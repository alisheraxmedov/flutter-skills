#!/usr/bin/env bash
# flutter-session-start.sh
# SessionStart hook for the `flutter` plugin.
#
# Acts ONLY when the working directory is a Flutter project: a pubspec.yaml
# that lists `flutter:` under its dependencies. In that case it injects a short
# additionalContext note nudging the orchestrator skill to run first.
# Otherwise it stays silent. It never blocks and never exits non-zero.
#
# Schema: SessionStart hooks return context via
#   { "hookSpecificOutput": { "hookEventName": "SessionStart",
#                             "additionalContext": "..." } }
# (https://code.claude.com/docs/en/hooks)
set -uo pipefail

# Read (and discard) stdin so the hook input JSON does not linger on the pipe.
# We do not need any of its fields; defaults handle a missing/empty stdin.
stdin_json="$(cat 2>/dev/null || true)"
: "${stdin_json:=}"

# Determine the project directory. Prefer CLAUDE_PROJECT_DIR if Claude Code set
# it; otherwise fall back to the current working directory.
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
pubspec="${project_dir}/pubspec.yaml"

# Not a Dart/Flutter package: no pubspec.yaml -> stay silent.
[ -f "$pubspec" ] || exit 0

# Only treat this as a Flutter project when pubspec declares `flutter:` as a
# dependency. We look for a `flutter:` key indented under dependencies, which
# covers the conventional `  flutter:` / `    sdk: flutter` block. This is a
# best-effort textual check (no YAML parser required) and errs toward silence.
is_flutter=0
if grep -Eq '^[[:space:]]+flutter:[[:space:]]*$' "$pubspec" 2>/dev/null; then
  is_flutter=1
elif grep -Eq '^[[:space:]]+sdk:[[:space:]]*flutter[[:space:]]*$' "$pubspec" 2>/dev/null; then
  is_flutter=1
fi

# Not a Flutter project -> output nothing, exit cleanly.
[ "$is_flutter" -eq 1 ] || exit 0

# Emit the additional-context note. Keep it short; Claude reads it as a system
# reminder on the next request.
# shellcheck disable=SC2016  # backticks are literal markdown in the note text, not command substitution
note='Flutter/Dart project detected. For any Flutter or Dart work, run the `flutter` orchestrator skill FIRST: it detects the project setup and routes to the right specialist skills (state-management, navigation, networking, theming, testing, etc.) before code is written.'

# Build valid JSON. Prefer jq when available; otherwise emit a hand-escaped
# object (the note text is static and contains no characters needing escaping
# beyond the backticks, which are JSON-safe).
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "$note" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}' 2>/dev/null \
    || printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "\"$note\""
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$note"
fi

exit 0
