#!/usr/bin/env bash
# log-skill-usage.sh
# PreToolUse hook (matcher: "Skill") for the `flutter` plugin.
#
# Appends a timestamped line recording which skill was invoked, then exits 0 so
# the Skill tool ALWAYS proceeds. This is logging only: it never returns a
# permissionDecision and never blocks.
#
# Log location: ${CLAUDE_PLUGIN_DATA}/skill-usage.log if CLAUDE_PLUGIN_DATA is
# set, else ${HOME}/.flutter-skills/skill-usage.log.
#
# Stdin carries the hook input JSON, e.g.
#   { "tool_name": "Skill", "tool_input": { "skill": "flutter:state-management", ... }, ... }
# (https://code.claude.com/docs/en/hooks)
set -uo pipefail

# Read stdin defensively; tolerate missing or empty input.
input="$(cat 2>/dev/null || true)"
: "${input:=}"

# Resolve the log directory and file.
if [ -n "${CLAUDE_PLUGIN_DATA:-}" ]; then
  log_dir="${CLAUDE_PLUGIN_DATA}"
else
  log_dir="${HOME:-/tmp}/.flutter-skills"
fi
log_file="${log_dir}/skill-usage.log"

# Best-effort directory creation; if it fails, do not block the tool.
mkdir -p "$log_dir" 2>/dev/null || exit 0

# Extract the skill name. Prefer jq; otherwise parse defensively with grep/sed.
# The Skill tool's input uses a "skill" field; fall back to "name" then to raw.
skill=""
if [ -n "$input" ]; then
  if command -v jq >/dev/null 2>&1; then
    skill="$(printf '%s' "$input" \
      | jq -r '.tool_input.skill // .tool_input.name // empty' 2>/dev/null || true)"
  fi
  if [ -z "$skill" ]; then
    # Grep/sed fallback: first "skill" (or "name") string value in tool_input.
    skill="$(printf '%s' "$input" \
      | grep -oE '"(skill|name)"[[:space:]]*:[[:space:]]*"[^"]*"' \
      | head -n1 \
      | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true)"
  fi
fi

# Build the log line. If we could not extract a name, fall back to a compact
# single-line form of the raw stdin (or a placeholder when stdin was empty).
ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo 'unknown-time')"
if [ -n "$skill" ]; then
  line="${ts}\tskill\t${skill}"
elif [ -n "$input" ]; then
  raw="$(printf '%s' "$input" | tr '\n' ' ' | tr -s ' ' | cut -c1-500)"
  line="${ts}\traw\t${raw}"
else
  line="${ts}\traw\t(no stdin)"
fi

# Append; never let a write failure block the tool.
printf '%b\n' "$line" >>"$log_file" 2>/dev/null || true

exit 0
