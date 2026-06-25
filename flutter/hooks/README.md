# Flutter plugin hooks

Two small, optional hooks defined in [`hooks.json`](./hooks.json). Both are
safe and non-intrusive: neither can block a tool call or fail a session.

## What they do

### 1. SessionStart → `flutter-session-start.sh`
Runs once when a session starts or resumes. It checks the current project and
**only acts inside a Flutter project** — i.e. a `pubspec.yaml` that declares
`flutter:` as a dependency. When that's true, it injects a short
`additionalContext` note reminding Claude to run the `flutter` orchestrator
skill first (to detect the project and route to specialist skills) before
writing code.

If there's no `pubspec.yaml`, or it isn't a Flutter project, the script outputs
nothing and exits cleanly. It never errors and never blocks.

### 2. PreToolUse (matcher `Skill`) → `log-skill-usage.sh`
Runs just before any `Skill` tool call and appends one timestamped, tab-separated
line recording the skill name. **It is logging only** — it always allows the tool
to proceed and never returns a permission decision.

## Where the usage log is written
- `${CLAUDE_PLUGIN_DATA}/skill-usage.log` if `CLAUDE_PLUGIN_DATA` is set, else
- `${HOME}/.flutter-skills/skill-usage.log`

Each line: `<UTC timestamp>\tskill\t<skill name>` (or `\traw\t<...>` when the
name can't be parsed). To inspect or measure usage, just read that file; to
reset, delete it.

## How to disable

- **Disable both hooks:** delete `hooks/hooks.json` (or the whole `hooks/`
  directory). With no `hooks.json` the plugin registers no hooks.
- **Disable just one:** remove that event's entry from the `"hooks"` object in
  `hooks/hooks.json` (drop the `"SessionStart"` array or the `"PreToolUse"`
  array). The other keeps working.
- **Inspect what's active:** run `/hooks` in Claude Code to browse configured
  hooks and confirm which are coming from this plugin.
- **Turn off plugin-wide:** disabling or uninstalling the `flutter` plugin via
  your plugin/marketplace settings removes its hooks along with it.

The scripts themselves do nothing destructive: no network access, no secrets,
read-only project checks plus a single appended log line.
