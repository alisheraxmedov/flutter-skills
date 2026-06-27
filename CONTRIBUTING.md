# Contributing

Thanks for helping improve the **flutter-dart-marketplace**. This repo is a set
of Claude Code skills for writing production Flutter & Dart code. Skills are
plain Markdown — no build step — but they hold a high quality bar.

## Repo layout

```
.claude-plugin/marketplace.json   # marketplace manifest
dart/    .claude-plugin/plugin.json + skills/<name>/SKILL.md (+ reference/*.md)
flutter/ .claude-plugin/plugin.json + skills/<name>/SKILL.md (+ reference/*.md) + hooks/
evals/                            # task prompts + objective rubrics + run-checks.sh
scripts/check_skills.py           # the linter CI runs (run it before every PR)
```

## Before you open a PR

Run the linter from the repo root — CI runs the same script and a PR cannot merge
red:

```bash
python3 scripts/check_skills.py
```

It must print `✓ all checks passed`. It validates: frontmatter (`name`,
`description`), the 500-line core cap, JSON manifests, reference links, and —
critically — that no file contains double-encoded UTF-8 **mojibake**. Always save
files as **UTF-8** (no double-encoding); the most common way to reintroduce
mojibake is an editor re-saving with the wrong codec.

## Authoring a skill (quality checklist)

A skill is a `SKILL.md` with YAML frontmatter plus optional `reference/*.md`.

- [ ] **`description` = WHEN, not what.** Third-person, trigger-rich (list the
      tasks/phrases that should fire it), key use-case first. This is the only
      text matched against a task — vague descriptions silently never fire.
- [ ] **`name`** lowercase-hyphen, matches the directory name.
- [ ] **Core `SKILL.md` < 500 lines.** Push depth into `reference/*.md` (one level
      deep). Reference files > 100 lines start with a short table of contents.
- [ ] **Concise.** Don't restate what Claude already knows; teach the workflow and
      the non-obvious footguns (a `## Gotchas` section is high-signal).
- [ ] **Show, don't tell.** Concrete `avoid → do` examples beat prose.
- [ ] **End with a runnable check** (`flutter analyze`, `dart format`, relevant
      tests) and an output contract where it helps.
- [ ] **No stale APIs** in examples (`withOpacity`→`withValues`,
      `textScaleFactor`→`TextScaler`, Groovy→Kotlin DSL, etc.). Prefer the
      on-demand version protocol over hardcoding package versions.

## Add an eval with your skill

Every behavioural change should be falsifiable. Append a case to `evals/evals.json`
(prompt + objective `expected_behavior` + `anti_behaviors`) and, where the
anti-pattern is mechanically detectable, add a grep to `evals/run-checks.sh`. See
`evals/README.md` for the with-skill vs baseline procedure.

## Commits & versioning

- Use [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat(skills): …`, `fix(plugin): …`, `docs(readme): …`).
- Bump the affected plugin's `version` (SemVer) and add a `CHANGELOG.md` entry.

## Conduct

Be respectful and constructive. Open an issue to discuss large changes (e.g. a new
skill) before investing in a big PR.
