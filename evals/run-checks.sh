#!/usr/bin/env bash
#
# run-checks.sh — objective code checks for a target Flutter project.
#
# Usage:   ./run-checks.sh [TARGET_DIR]
#          TARGET_DIR defaults to the current directory ".".
#
# Runs the toolchain checks (analyze, format, test) and greps lib/ for the
# headline anti-patterns the flutter-skills marketplace is meant to prevent.
# Prints a PASS/FAIL summary with counts. Does NOT crash if flutter is missing.
#
set -uo pipefail

TARGET="${1:-.}"
LIB="$TARGET/lib"

# ---- counters --------------------------------------------------------------
PASS=0
FAIL=0
WARN=0

pass() { printf '  [PASS] %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  [WARN] %s\n' "$1"; WARN=$((WARN + 1)); }
hdr()  { printf '\n=== %s ===\n' "$1"; }

# count matches of a regex in lib/ (dart files only); prints 0 if no lib/.
count_in_lib() {
  local pattern="$1"
  if [ ! -d "$LIB" ]; then echo 0; return; fi
  grep -rInE --include='*.dart' -- "$pattern" "$LIB" 2>/dev/null | wc -l | tr -d ' '
}

# show up to N example matches for context
show_in_lib() {
  local pattern="$1"
  if [ ! -d "$LIB" ]; then return; fi
  grep -rInE --include='*.dart' -- "$pattern" "$LIB" 2>/dev/null | head -5 \
    | sed 's/^/      /'
}

printf '################################################################\n'
printf '# flutter-skills eval checks\n'
printf '# target: %s\n' "$TARGET"
printf '################################################################\n'

if [ ! -d "$TARGET" ]; then
  printf 'ERROR: target dir "%s" does not exist.\n' "$TARGET"
  exit 2
fi

# ---- toolchain availability ------------------------------------------------
HAVE_FLUTTER=0
HAVE_DART=0
if command -v flutter >/dev/null 2>&1; then HAVE_FLUTTER=1; fi
if command -v dart    >/dev/null 2>&1; then HAVE_DART=1;    fi

# ---- 1. flutter analyze ----------------------------------------------------
hdr "flutter analyze"
if [ "$HAVE_FLUTTER" -eq 1 ]; then
  if (cd "$TARGET" && flutter analyze) >/tmp/_fs_analyze.log 2>&1; then
    pass "flutter analyze clean"
  else
    fail "flutter analyze reported issues"
    tail -20 /tmp/_fs_analyze.log | sed 's/^/      /'
  fi
else
  warn "flutter not installed — skipping analyze"
fi

# ---- 2. dart format --------------------------------------------------------
hdr "dart format (check only)"
if [ "$HAVE_DART" -eq 1 ]; then
  if (cd "$TARGET" && dart format --output=none --set-exit-if-changed .) \
        >/tmp/_fs_format.log 2>&1; then
    pass "dart format: all files already formatted"
  else
    fail "dart format: files would be reformatted (run 'dart format .')"
    head -20 /tmp/_fs_format.log | sed 's/^/      /'
  fi
else
  warn "dart not installed — skipping format check"
fi

# ---- 3. flutter test -------------------------------------------------------
hdr "flutter test"
if [ -d "$TARGET/test" ]; then
  if [ "$HAVE_FLUTTER" -eq 1 ]; then
    if (cd "$TARGET" && flutter test) >/tmp/_fs_test.log 2>&1; then
      pass "flutter test passed"
    else
      fail "flutter test failed"
      tail -20 /tmp/_fs_test.log | sed 's/^/      /'
    fi
  else
    warn "flutter not installed — skipping tests"
  fi
else
  warn "no test/ directory — skipping tests"
fi

# ---- 4. anti-pattern greps over lib/ ---------------------------------------
hdr "anti-pattern scan (lib/)"
if [ ! -d "$LIB" ]; then
  warn "no lib/ directory at $LIB — skipping anti-pattern scan"
else

  # 4a. hardcoded hex colors in widget code: Color(0xFF...) / Color(0xff...)
  n=$(count_in_lib 'Color\(0x[0-9A-Fa-f]{6,8}\)')
  if [ "$n" -eq 0 ]; then
    pass "no hardcoded Color(0x...) hex literals in lib/"
  else
    fail "hardcoded hex Color(0x...) literals in lib/: $n (use ColorScheme / theme tokens)"
    show_in_lib 'Color\(0x[0-9A-Fa-f]{6,8}\)'
  fi

  # 4b. deprecated .withOpacity( -> withValues(alpha:)
  n=$(count_in_lib '\.withOpacity\(')
  if [ "$n" -eq 0 ]; then
    pass "no deprecated .withOpacity( in lib/"
  else
    fail "deprecated .withOpacity( in lib/: $n (use .withValues(alpha:))"
    show_in_lib '\.withOpacity\('
  fi

  # 4c. SingleChildScrollView (often wrapping a long Column -> should be ListView.builder)
  n=$(count_in_lib 'SingleChildScrollView')
  if [ "$n" -eq 0 ]; then
    pass "no SingleChildScrollView in lib/"
  else
    warn "SingleChildScrollView in lib/: $n — verify none wraps a long Column (use ListView.builder)"
    show_in_lib 'SingleChildScrollView'
  fi

  # 4d. force-unwrap-heavy lines: 2+ occurrences of '<ident>!' bang-unwrap on a line.
  #     '<ident>!' = an identifier/closer followed by '!' (excludes '!=' and '!x').
  BANG='[]A-Za-z0-9_)]!([^!]*[]A-Za-z0-9_)]!)'
  n=$(count_in_lib "$BANG")
  if [ "$n" -eq 0 ]; then
    pass "no force-unwrap-heavy lines (2+ bang) in lib/"
  else
    warn "force-unwrap-heavy lines in lib/: $n — review each '!' for a proven non-null"
    show_in_lib "$BANG"
  fi

  # 4e. empty catch blocks: catch (e) {} / catch {}  -> swallowed errors
  n=$(count_in_lib 'catch[^{]*\{[[:space:]]*\}')
  if [ "$n" -eq 0 ]; then
    pass "no empty catch {} blocks in lib/"
  else
    fail "empty catch {} blocks in lib/: $n (log + return a Failure)"
    show_in_lib 'catch[^{]*\{[[:space:]]*\}'
  fi

  # 4f. insecure TLS: badCertificateCallback override
  n=$(count_in_lib 'badCertificateCallback')
  if [ "$n" -eq 0 ]; then
    pass "no badCertificateCallback override in lib/"
  else
    fail "badCertificateCallback in lib/: $n (do not disable TLS verification)"
    show_in_lib 'badCertificateCallback'
  fi
fi

# ---- 5. repo-level secret / config checks ----------------------------------
hdr "secret & config scan (repo)"

# 5a. android signing secrets committed
if [ -f "$TARGET/android/key.properties" ]; then
  fail "android/key.properties is present in the tree (must NOT be committed)"
else
  pass "no committed android/key.properties"
fi

# 5b. wide-open Firebase / Firestore rules: allow read, write: if true
RULES=$(grep -rIlE 'allow[[:space:]]+read,[[:space:]]*write:[[:space:]]*if[[:space:]]+true' \
          "$TARGET" 2>/dev/null \
          | grep -vE '/(build|\.dart_tool|\.git)/' || true)
if [ -z "$RULES" ]; then
  pass "no 'allow read, write: if true' rules found"
else
  fail "wide-open security rules ('allow read, write: if true'):"
  printf '%s\n' "$RULES" | sed 's/^/      /'
fi

# ---- summary ---------------------------------------------------------------
hdr "SUMMARY"
printf '  PASS: %d\n' "$PASS"
printf '  FAIL: %d\n' "$FAIL"
printf '  WARN: %d  (review manually)\n' "$WARN"

if [ "$FAIL" -gt 0 ]; then
  printf '\nRESULT: FAIL (%d hard failures)\n' "$FAIL"
  exit 1
fi
printf '\nRESULT: PASS (no hard failures; %d warnings)\n' "$WARN"
exit 0
