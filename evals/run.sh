#!/usr/bin/env bash
# Automated eval runner — baseline vs with-skill, LLM-judged, headless.
#
# Uses your EXISTING Claude login (keychain). NO new logins, ever. It loads the
# flutter/dart skills for the with-skill arm via --plugin-dir (this-session-only)
# and temporarily disables your other enabled plugins (caveman, superpowers, …)
# so neither arm is contaminated — then restores your settings on exit.
#
# Honest-by-construction: a failed/empty generation or an unparseable judge reply
# is reported as ERR and EXCLUDED from the aggregate — it is never silently scored
# 0% or 100%. Means and deltas are computed only over cases where BOTH arms scored.
#
# RUN:
#   ./evals/run.sh         # all cases in the evals file
#   ./evals/run.sh 3       # first 3 only (quick smoke test — do this first)
#   MODEL=claude-haiku-4-5-20251001 EVALS_FILE=evals/evals-hard.json ./evals/run.sh
#
# Outputs: evals/results/  (raw generations + RESULTS.md table).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVALS="${EVALS_FILE:-$ROOT/evals/evals.json}"
OUT="$ROOT/evals/results"
SETTINGS="$HOME/.claude/settings.json"
LIMIT="${1:-0}"

command -v claude >/dev/null || { echo "need claude CLI"; exit 1; }
command -v jq >/dev/null     || { echo "need jq"; exit 1; }
mkdir -p "$OUT"

# ── Temporarily disable other plugins; restore on ANY exit (incl. Ctrl+C) ──────
BACKUP=""
restore() { [ -n "$BACKUP" ] && [ -f "$BACKUP" ] && mv -f "$BACKUP" "$SETTINGS"; }
trap restore EXIT INT TERM
if [ -f "$SETTINGS" ]; then
  BACKUP="$(mktemp)"; cp "$SETTINGS" "$BACKUP"
  jq '(.enabledPlugins // {}) |= with_entries(.value = false)' "$SETTINGS" > "$SETTINGS.tmp" \
    && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "Temporarily disabled other plugins for a clean run (will restore on exit)."
fi

NOTOOLS=(--disallowedTools Write Edit MultiEdit Bash NotebookEdit --dangerously-skip-permissions --output-format text)
INLINE='Assume a standard, already-set-up Flutter app exists. Generate the requested code directly; do NOT ask clarifying questions about project setup or the current directory. Output the complete code inline in fenced code blocks; do not create or edit files; respond in text only.'

# Optional: eval a weaker model where the skill actually rescues the baseline.
#   MODEL=claude-haiku-4-5-20251001 EVALS_FILE=evals/evals-hard.json ./evals/run.sh
# Applies to the GENERATION arms only; the judge stays on your default (strong) model.
MODEL="${MODEL:-}"; MODEL_ARGS=(); [ -n "$MODEL" ] && MODEL_ARGS=(--model "$MODEL")

# Non-empty? (strips whitespace; a lone newline / blank reply counts as empty.)
nonempty() { [ -n "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }

# Generate with ONE retry — a transient empty reply shouldn't poison a data point.
_gen() {  # mode, query
  local out
  out="$(claude -p "$2" --append-system-prompt "$INLINE" "${MODEL_ARGS[@]}" "${@:3}" "${NOTOOLS[@]}" 2>/dev/null)"
  nonempty "$out" || out="$(claude -p "$2" --append-system-prompt "$INLINE" "${MODEL_ARGS[@]}" "${@:3}" "${NOTOOLS[@]}" 2>/dev/null)"
  printf '%s' "$out"
}
gen_base()  { _gen base  "$1"; }
gen_skill() { _gen skill "$1" --plugin-dir "$ROOT/flutter" --plugin-dir "$ROOT/dart"; }

# LLM judge → ONE compact JSON object. Empty/garbage reply yields empty output
# (caller treats that as ERR, never as a score).
judge() {  # code, expected_json, anti_json
  local prompt="You are a STRICT, neutral code grader. Score ONLY the GENERATED CODE against the rubric.
An EXPECTED item counts as satisfied only if the code clearly demonstrates it (ignore prose/promises).
An ANTI item counts as hit if the code does it anywhere.
Return ONLY one JSON object on a single line, no prose, no code fence:
{\"passed\": <int: EXPECTED items satisfied>, \"total\": <int: count of EXPECTED items>, \"anti_hit\": <true if ANY ANTI item appears, else false>}

EXPECTED: $2
ANTI: $3

GENERATED CODE:
$1"
  claude -p "$prompt" "${NOTOOLS[@]}" 2>/dev/null \
    | sed 's/```json//g; s/```//g' | tr '\n' ' ' \
    | grep -oE '\{[^{}]*"passed"[^{}]*\}' | tail -1
}

# Score one arm → integer percent on stdout, or "ERR" if the generation was empty
# or the judge reply could not be parsed into a valid object.
score_arm() {  # generated_code, expected_json, anti_json, expected_count
  nonempty "$1" || { echo ERR; return; }
  local j; j="$(judge "$1" "$2" "$3")"
  [ -n "$j" ] || { echo ERR; return; }
  local p t a
  p="$(printf '%s' "$j" | jq -r '.passed   // empty' 2>/dev/null)"
  t="$(printf '%s' "$j" | jq -r '.total    // empty' 2>/dev/null)"
  a="$(printf '%s' "$j" | jq -r '.anti_hit // false' 2>/dev/null)"
  # passed/total must be real integers, else the judge reply is unusable → ERR.
  [[ "$p" =~ ^[0-9]+$ ]] || { echo ERR; return; }
  [[ "$t" =~ ^[0-9]+$ ]] && [ "$t" -gt 0 ] || t="$4"
  [ "$a" = "true" ] && p=0
  [ "$t" -gt 0 ] || { echo ERR; return; }
  echo $(( 100 * p / t ))
}

n=$(jq length "$EVALS")
[ "$LIMIT" -gt 0 ] && [ "$LIMIT" -lt "$n" ] && n="$LIMIT"
echo "Running $n case(s) × (2 generations + 2 grades) on your existing login…"
printf '\n%-30s %10s %8s %7s\n' "case" "baseline" "skill" "delta"
printf '%-30s %10s %8s %7s\n' "------------------------------" "--------" "------" "------"

results="| case | baseline | skill | delta | helped? |\n|---|:--:|:--:|:--:|:--:|\n"
sum_b=0; sum_s=0; npair=0; win=0; errs=0
for i in $(seq 0 $((n-1))); do
  id=$(jq -r ".[$i].id" "$EVALS")
  q=$(jq -r ".[$i].query" "$EVALS")
  exp=$(jq -c ".[$i].expected_behavior" "$EVALS")
  anti=$(jq -c ".[$i].anti_behaviors" "$EVALS")
  exp_n=$(jq ".[$i].expected_behavior|length" "$EVALS")

  b_out=$(gen_base  "$q"); printf '%s\n' "$b_out" > "$OUT/$id.baseline.md"
  s_out=$(gen_skill "$q"); printf '%s\n' "$s_out" > "$OUT/$id.skill.md"
  b=$(score_arm "$b_out" "$exp" "$anti" "$exp_n")
  s=$(score_arm "$s_out" "$exp" "$anti" "$exp_n")

  # Display + aggregate. ERR on either arm => unpaired => excluded from means.
  bcell="$b"; scell="$s"; dcell="—"; helped="—"
  [ "$b" = ERR ] && bcell="ERR"   || bcell="${b}%"
  [ "$s" = ERR ] && scell="ERR"   || scell="${s}%"
  if [ "$b" != ERR ] && [ "$s" != ERR ]; then
    delta=$(( s - b )); dcell="${delta}%"
    sum_b=$((sum_b+b)); sum_s=$((sum_s+s)); npair=$((npair+1))
    helped="no"; [ "$delta" -gt 0 ] && { helped="yes"; win=$((win+1)); }
  else
    errs=$((errs+1))
  fi
  printf '%-30s %10s %8s %7s\n' "$id" "$bcell" "$scell" "$dcell"
  results+="| $id | $bcell | $scell | $dcell | $helped |\n"
done

echo
if [ "$npair" -gt 0 ]; then
  mean_b=$(( sum_b/npair )); mean_s=$(( sum_s/npair )); agg=$(( mean_s-mean_b ))
  echo "Aggregate over $npair scored case(s): baseline ${mean_b}% → skill ${mean_s}% (Δ +${agg} pp, skill helped in $win/$npair). Excluded (ERR): $errs."
else
  mean_b=0; mean_s=0; agg=0
  echo "No case scored on both arms — every case hit an ERR. Check your login / model / network."
fi
{
  echo "# Eval results (raw, single run)"; echo
  echo "Baseline vs with-skill, LLM-judged (\`evals/run.sh\`, existing login)."
  echo "Model: ${MODEL:-default}. Cases: $n. ERR = empty generation or unparseable judge reply (excluded)."; echo
  printf '%b\n' "$results"; echo
  if [ "$npair" -gt 0 ]; then
    echo "**Aggregate over $npair scored case(s):** baseline ${mean_b}% → skill ${mean_s}% (Δ +${agg} pp). Skill helped in $win/$npair. Excluded (ERR): $errs."
    echo; echo "_Single run — generation and the judge are non-deterministic. Average 3–5 runs before quoting a number._"
  else
    echo "**No case scored on both arms (all ERR).**"
  fi
} > "$OUT/RESULTS.md"
echo "Wrote $OUT/RESULTS.md"
