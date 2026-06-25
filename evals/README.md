# Evals — flutter-skills marketplace

An evaluation harness that proves the **flutter** and **dart** skills actually
improve generated code, by running each task **with the plugin installed** and
again **without it (baseline)** and comparing how many objective assertions pass.

The format follows Anthropic's `skill-creator` convention: every eval is a
**task prompt** plus a set of **objective, checkable pass/fail assertions**. The
skill earns its keep only when the with-skill run passes more assertions than
baseline.

## What's here

| File             | Purpose |
|------------------|---------|
| `evals.json`     | 14 eval cases (prompt + `expected_behavior` + `anti_behaviors`) for the highest-value skills. |
| `run-checks.sh`  | Portable objective checks on a generated Flutter project (analyze, format, test, anti-pattern greps). |
| `RUBRIC.md`      | A per-task scoring template you fill in when running an eval manually. |
| `README.md`      | This file. |

## Purpose

A skill that doesn't change the output is dead weight. These evals exist to
answer one question per case: **does the skill make Claude produce code that
follows the rule, where baseline does not?** We measure that with assertions
that are objective and Flutter-specific (e.g. "emits a new list reference", "uses
`ColorScheme.fromSeed`", "disposes controllers in `dispose()`") — not vibes.

## How to run an eval (manual)

For each case in `evals.json`:

1. **Scratch project.** Create a throwaway Flutter app to generate into:
   ```bash
   flutter create eval_scratch && cd eval_scratch
   ```
   Reset it (`git stash` / `git checkout .` / fresh `flutter create`) between
   runs so one run never contaminates the next.

2. **Baseline run (no plugin).** In a **fresh** Claude Code session with the
   `flutter`/`dart` plugins **uninstalled**, paste the case's `query` verbatim.
   Save the generated files.

3. **With-skill run (plugin installed).** Install the marketplace and the
   relevant plugin, then in **another fresh** session paste the **same** `query`.
   ```bash
   # in Claude Code
   /plugin marketplace add <path-or-repo-to>/flutter-skills
   /plugin install flutter@flutter-dart-marketplace
   /plugin install dart@flutter-dart-marketplace
   ```
   Confirm the intended skill (the case's `skill` field) actually fired.

4. **Score both runs against the rubric.** Copy `RUBRIC.md`, list each assertion
   from `expected_behavior` and each item from `anti_behaviors`, and mark
   pass/fail for the with-skill output and the baseline output. Run the objective
   checks to back up your judgement:
   ```bash
   ./run-checks.sh ../eval_scratch
   ```
   `run-checks.sh` mechanically catches the headline anti-patterns (hardcoded hex
   colors, `.withOpacity(`, `SingleChildScrollView` over long lists, force-unwrap
   spam, empty `catch {}`, `badCertificateCallback`, committed `key.properties`,
   wide-open security rules) and runs `flutter analyze` / `dart format` /
   `flutter test`. It degrades gracefully (warns, doesn't crash) when Flutter
   isn't installed.

5. **Record the delta.** `expected_behavior` items are pass-positive; any
   `anti_behaviors` item that appears is an automatic fail for that run. The skill
   wins the case if its pass-rate beats baseline's.

### Automating with `skill-creator`

The `skill-creator` skill can drive this loop for you: point it at `evals.json`,
have it run each `query` with and without the skill, score the output against the
assertions, and report a per-case and aggregate pass-rate with variance. Use it
to regression-test a skill after editing its `SKILL.md`, or to benchmark a
description change for trigger accuracy.

## How to read results

- **Per case**: with-skill pass-count vs baseline pass-count. A positive delta
  means the skill is pulling its weight on that task.
- **Anti-behaviors are gates**: a single anti-behavior present fails the run for
  that case regardless of how many expected behaviors passed.
- **Aggregate**: the headline number is the with-skill pass-rate minus the
  baseline pass-rate across all cases. If a skill's delta is ~0, the skill isn't
  changing behavior — fix the `SKILL.md` (or its description/trigger) or drop it.
- A case where **baseline already passes everything** is a weak eval — tighten
  the prompt so the rule isn't trivially obvious, or pick a harder scenario.

## Adding a new eval

Append an object to the array in `evals.json`:

```json
{
  "id": "skill-short-scenario",
  "skill": "flutter:state-management",
  "query": "The exact user prompt to paste into Claude Code.",
  "expected_behavior": [
    "an OBJECTIVE, checkable assertion (a reviewer can mark yes/no without opinion)"
  ],
  "anti_behaviors": [
    "a specific thing that must NOT appear in the output"
  ]
}
```

Guidelines:

- **`id`**: kebab-case, `skill-scenario` shaped, unique.
- **`skill`**: the namespaced skill expected to fire (`flutter:theming`,
  `dart:async`, …) — also lets you verify triggering.
- **Make assertions objective and Flutter-specific.** "Emits a new list via
  spread, not `.add()` on the existing reference" is checkable; "handles state
  well" is not.
- **Pick scenarios baseline plausibly gets wrong.** The eval only has signal if
  there's headroom for the skill to win.
- If a new anti-pattern is mechanically detectable, add a grep for it to
  `run-checks.sh` so scoring stays cheap.
