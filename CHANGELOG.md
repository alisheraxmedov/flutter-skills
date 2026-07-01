# Changelog

All notable changes to the **flutter-dart-marketplace** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
each plugin is versioned independently with [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- **Eval honesty** — `evals/RESULTS.md`, `README.md` and `CHANGELOG.md` no longer
  headline an "82% average" (a mean of two models' absolute scores) or "+100 pp".
  They now report the **measured cost-efficient-model uplift** (Haiku 4.5
  38% → 64%, +26 pp, mean of 2 runs) and state plainly that the frontier-model
  delta is **≈ 0** because the baseline is already near-ceiling.
- **Grader (`evals/run.sh`)** — empty generations and unparseable judge replies are
  now reported as **ERR and excluded** from aggregates, instead of being silently
  scored 0% or 100%; means/deltas are computed only over cases scored on both arms;
  generations get one retry on a transient empty reply.
- **Leaked scaffolding** — removed stray tool-call close-tags (content/invoke)
  from `flutter/skills/migrations/SKILL.md`.
- **i18n** — `AppLocalizations.of(context)` is nullable; snippets now use `!`
  (with a note on `nullable-getter: false`) so they compile.

### Added
- **Three new Flutter skills** — `flutter:layout` (constraint model, Row/Column/Flex/Expanded,
  Stack, intrinsic sizing, slivers, keys, widget/element/render trees, `InheritedWidget`),
  `flutter:custom-paint` (`CustomPainter`/`Canvas`/paths, `shouldRepaint` & `Paint` caching,
  `save`/`restore`/`saveLayer`, gestures & hit testing), and `flutter:graphql`
  (`graphql_flutter` vs `ferry`, normalized cache + identity, fetch policies, mutation cache
  updates, the HTTP-200-with-`errors` → `Result`/`Failure` mapping). Marketplace now ships
  **39 skills** (6 Dart + 33 Flutter).
- **Dart language depth** — two new references on `dart:dart`: `extensions-and-mixins.md`
  (extension dispatch is *static*, mixin linearization order, callable classes, custom
  operators) and `collections-and-generics.md` (Iterable laziness re-evaluation, generic
  covariance soundness hole, `covariant`, bounded type params).
- **Linter** — `scripts/check_skills.py` now flags leaked tool-call scaffolding
  tags (content / invoke / parameter close-tags from a bad generation) in any
  `*.md`, without touching legitimate Android/iOS XML.

### Changed
- **2026 currency pass** across existing skills:
  - `state-management` — Riverpod 3.3.2 / `riverpod_annotation` 4.0.3 (version lines differ),
    `.valueOrNull`→`.value`, legacy providers → `package:flutter_riverpod/legacy.dart`,
    sealed `AsyncValue` exhaustive `switch`, `Ref.mounted` async guards, automatic retry +
    experimental `riverpod_sqflite` persistence, a `signals` decision row, `hydrated_bloc`.
  - `data-model` — freezed 3.2.5, `abstract`/`sealed` classes, `when`/`map` deprecated →
    Dart 3 pattern matching, `dart run build_runner build --delete-conflicting-outputs`.
  - `optimization` / `animation` — Impeller-default framing: raster-thread vs UI-thread
    profiling, the `RepaintBoundary` "every-frame → no cache reuse" rule, `cacheExtent`/
    `prototypeItem`, and SkSL warmup / `--bundle-sksl-path` marked obsolete under Impeller.
  - `test` — mocktail-over-mockito rationale, `ProviderContainer.test()` (Riverpod 3),
    4-layer pyramid with a Patrol native-E2E top row; current tool versions.
  - `analyze` — `flutter_lints` vs `very_good_analysis` (vs `lints` for pure Dart)
    base-ruleset choice; pick one, don't stack.
  - `migrations` — made the canonical deprecation source; **corrected** the Gradle guidance
    (Groovy is *not* deprecated; Kotlin DSL is the new-project default since 3.29; the
    deprecated part is imperative `apply` → `plugins {}`); cross-links freezed & Riverpod moves.
  - `networking` — routes GraphQL work to `flutter:graphql`; dio 5.10.0 / retrofit 4.9.2.
- **Plugin versions** — flutter `3.3.0`, dart `3.2.0`; marketplace `3.3.0`.

## flutter 3.2.0 · dart 3.1.0 — 2026-06-27

### Fixed
- **Encoding** — removed double-encoded UTF-8 mojibake from all 36 `SKILL.md`
  files (em-dashes, arrows, comparison operators and box-drawing characters
  were corrupted, including inside 19 `description:` fields — the text Claude
  matches on to trigger a skill).

### Added
- **CI** — `lint-skills` GitHub Actions workflow plus `scripts/check_skills.py`:
  validates frontmatter, the 500-line core cap, JSON manifests and reference
  links, and guards against any mojibake regression. ShellCheck on hooks/scripts.
- **Project docs** — `CHANGELOG.md`, `CONTRIBUTING.md`, a pull-request template
  and issue templates.
- **Automated evals** — `evals/run.sh` (baseline vs with-skill, LLM-judged, uses
  the existing login via `--plugin-dir`, supports `MODEL=` / `EVALS_FILE=`),
  `evals/evals-hard.json` (7 high-signal cases) and `evals/RESULTS.md`. On the
  suite the skills lift a cost-efficient model (Haiku 4.5) **38% → 64%** (**+26 pp**,
  mean of 2 runs); on a near-ceiling frontier model (Opus 4.8) the measured delta
  is **≈ 0**. Numbers are noisy — see RESULTS.md for caveats.

### Changed
- **Marketplace metadata** — `marketplace.json` description is now in English and
  carries a `version` field; plugin versions aligned (flutter `3.2.0`, dart `3.1.0`).
- **Roadmap** — internal roadmap reconciled with the shipped 36-skill reality.

## flutter 3.1.0 · dart 3.0.0 — earlier

- Initial public marketplace: 6 Dart + 30 Flutter skills, an orchestrator entry
  point, a `review` judge, SessionStart + usage-logging hooks, and an `evals/`
  harness.
