# Flutter & Dart Skills

[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-7C3AED)](https://code.claude.com/docs/en/plugins)
[![skills.sh](https://skills.sh/b/alisheraxmedov/flutter-skills)](https://skills.sh/alisheraxmedov/flutter-skills)
[![skills](https://img.shields.io/badge/skills-39-blue)](#flutter-plugin--flutterskill)
[![lint-skills](https://github.com/alisheraxmedov/flutter-skills/actions/workflows/lint-skills.yml/badge.svg)](https://github.com/alisheraxmedov/flutter-skills/actions/workflows/lint-skills.yml)
[![Flutter 3.44 · Dart 3.12](https://img.shields.io/badge/Flutter%203.44-Dart%203.12-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A Claude Code marketplace of **39 skills** for writing production-quality **Flutter** and **Dart** code — from architecture, state, layout/rendering, and UI to data (REST & GraphQL), security, Firebase, native interop, signing, and release. Built on the official Flutter app-architecture guide and current 2026 best practices (Flutter 3.44 / Dart 3.12, Riverpod 3, flutter_bloc, go_router, dio, freezed, Material 3).

Each skill is **token-efficient by design**: a short core `SKILL.md` (rules, decision tables, a strict output contract) plus on-demand `reference/*.md` files that Claude loads only when a task needs the deep examples — so most of the content costs zero tokens until it's actually used.

## How it works — the orchestrator

`/flutter:flutter` is the **entry point**. For any Flutter task it: (1) **detects the project** (Flutter version, packages, state-management in use, folder conventions), (2) **routes to the specialist skills** it needs by invoking them via the Skill tool (e.g. `flutter:state-management` + `flutter:networking` + `flutter:forms` for a login screen), (3) writes code following the rules, then (4) runs a **self-review** (or `flutter:review`) and confirms a shared **Definition of done**. So you can call one skill and the rest engage automatically — instead of loading everything up front.

## Install

### Option A — Claude Code plugin (recommended)

Gets the full experience: both plugins, the orchestrator entry point, and the SessionStart hook. Run inside Claude Code:

```
/plugin marketplace add alisheraxmedov/flutter-skills
/plugin install dart@flutter-dart-marketplace
/plugin install flutter@flutter-dart-marketplace
```

Then invoke skills explicitly with `/<plugin>:<skill>` (e.g. `/flutter:state-management`), or just describe your task and the orchestrator routes for you.

### Option B — `skills` CLI (Claude Code, Cursor, Copilot, Codex, Gemini & more)

Installs all 39 `SKILL.md` files into your agent from your terminal — no Claude Code required:

```
npx skills add alisheraxmedov/flutter-skills
```

Either way, skills trigger **automatically** when relevant to your task.

## Update

Installing **copies the plugin into Claude Code's own cache** — editing this repo (or pulling a new release) does **not** change an already-installed copy until you refresh the marketplace. The marketplace **name** is `flutter-dart-marketplace` (from `marketplace.json`), not the repo name `flutter-skills` — use it in `install`/`update` commands.

### Option A — Claude Code plugin

```
/plugin marketplace update flutter-dart-marketplace
```

Then **restart Claude Code** (or run `/reload-plugins`). If an old or renamed skill still lingers (e.g. you still see a removed `/model` instead of `/data-model`), do a clean re-add:

```
/plugin marketplace remove flutter-dart-marketplace
/plugin marketplace add alisheraxmedov/flutter-skills
/plugin install dart@flutter-dart-marketplace
/plugin install flutter@flutter-dart-marketplace
```

### Option B — `skills` CLI

```
npx skills update -p -y      # project scope; use -g for global installs
```

> **Note on versions:** installed plugins only pick up changes when the plugin `version` is bumped (see each `plugin.json`). Each release here bumps the affected plugin's SemVer, so `marketplace update` + restart is enough to get the latest skills.

## Dart plugin — `/dart:<skill>`

| Skill | What it does |
|-------|--------------|
| `/dart:dart` | Idiomatic Dart 3 — naming, null safety, pattern matching, records, sealed classes, class modifiers |
| `/dart:async` | Futures, streams, isolates — async/await, parallelism, cancellation, no blocking the event loop |
| `/dart:data-model` | Immutable data & domain models — hand-written sealed unions vs `freezed` + `json_serializable` |
| `/dart:analyze` | Strict `analysis_options.yaml`, `dart analyze --fatal-infos`, `dart fix`, `dart format` |
| `/dart:test` | Unit tests with `package:test` + `mocktail` — AAA pattern, async, edge cases, coverage |
| `/dart:optimization` | `const`/`final` discipline, tight typing, lazy iterables, efficient collections |

## Flutter plugin — `/flutter:<skill>`

**Architecture & UI**

| Skill | What it does |
|-------|--------------|
| `/flutter:flutter` | **Orchestrator + architecture** — detects the project, routes to specialist skills, Clean Architecture + MVVM, definition of done |
| `/flutter:state-management` | **Riverpod 3 + Bloc/Cubit in one skill** — decision guide, the state→UI rebuild fix, on-demand pub.dev version/changelog checks |
| `/flutter:navigation` | `go_router` — type-safe routes, ShellRoute tabs, auth redirects |
| `/flutter:deep-linking` | App Links / Universal Links + go_router — manifest/entitlements, hosted `assetlinks.json`/AASA, cold-start |
| `/flutter:theming` | Material 3 `ColorScheme.fromSeed`, `TextTheme`, `ThemeExtension`, dark mode — never hardcode colors |
| `/flutter:forms` | `Form` + `TextFormField`, validation, focus, controller lifecycle, submit flows |
| `/flutter:animation` | Implicit vs explicit vs prebuilt animations, controller lifecycle, performance |
| `/flutter:custom-paint` | `CustomPainter`/`Canvas`/paths, `shouldRepaint` & `Paint` caching, gestures & hit testing |
| `/flutter:responsive` | MediaQuery, LayoutBuilder, breakpoints, adaptive navigation across phone/tablet/desktop |
| `/flutter:layout` | Constraints model, Row/Column/Flex/Expanded, Stack, slivers, overflow fixes, keys, render tree, `InheritedWidget` |
| `/flutter:accessibility` | `Semantics`, screen readers, `TextScaler`, contrast, touch targets, guideline tests |
| `/flutter:i18n` | `flutter_localizations` + ARB + `gen-l10n` — plurals, formatting, RTL, locale switch |
| `/flutter:image-assets` | `cached_network_image`, decode-memory (`cacheWidth`), asset variants, SVG |

**Data, backend & security**

| Skill | What it does |
|-------|--------------|
| `/flutter:networking` | `dio` + `retrofit` — interceptors, token refresh, typed failures, `Result`-returning repos |
| `/flutter:graphql` | `graphql_flutter` vs `ferry` — normalized cache, fetch policies, mutation cache updates, 200-with-errors mapping |
| `/flutter:error-handling` | Sealed `Result`/`Failure`, boundary mapping, global handlers, crash reporting |
| `/flutter:firebase` | Auth (stream-based), Firestore (offline cache), security rules — never ship test-mode rules |
| `/flutter:persistence` | drift / sqflite / hive_ce / shared_preferences — choosing + **migrations** (no data loss) |
| `/flutter:security` | Secure storage, cert pinning in Dart, obfuscation myths, OWASP MASVS hardening |
| `/flutter:observability` | Crashlytics / Sentry, capture all error channels, symbol upload, structured logging |

**Native & platform**

| Skill | What it does |
|-------|--------------|
| `/flutter:isolates-background` | `Isolate.run`/compute, sendable data, plugins-in-isolates, workmanager |
| `/flutter:platform-channels` | Pigeon over raw `MethodChannel`, EventChannel, FFI, ANR-safe threading |
| `/flutter:push-notifications` | FCM + local notifications, the `@pragma('vm:entry-point')` handler, APNs/Android 13 setup |

**Build, release & DevOps**

| Skill | What it does |
|-------|--------------|
| `/flutter:flavors-env` | Flavors (Android + iOS schemes), `appFlavor`, `--dart-define-from-file`, env config |
| `/flutter:release` | Android signing (Kotlin DSL), Play App Signing, AAB/IPA, versioning, symbols |
| `/flutter:ci-cd` | GitHub Actions / Codemagic / fastlane — analyze/test/build, auto build number, CI secrets |
| `/flutter:app-size` | `--analyze-size`, obfuscation + `--split-debug-info`, asset/font trimming |
| `/flutter:migrations` | `fvm` pinning, `dart fix`, major-upgrade cascade, deprecated-API sweep |
| `/flutter:packaging` | pub workspaces, Melos 7, pub.dev publishing/pana, federated plugins |

**Quality**

| Skill | What it does |
|-------|--------------|
| `/flutter:analyze` | Flutter lints, `analysis_options.yaml`, `use_build_context_synchronously`, CI |
| `/flutter:test` | Unit / widget / golden (`alchemist`) / integration tests, coverage, CI gating |
| `/flutter:optimization` | 60/120fps — const widgets, lazy lists, RepaintBoundary, rebuild & memory-leak control |
| `/flutter:review` | Code-review "judge" — audits code/diffs by severity (blocking/should-fix/nit) against the anti-pattern checklist |

## Usage

After installing, just describe what you want — Claude picks the matching skill automatically. To force a specific skill, type its command:

```
/flutter:state-management
```

Then describe the feature, e.g. *"add an AsyncNotifier that loads and paginates a product list from the repository."* Claude follows the skill's rules to produce production-grade code.

## Built-in best practices

The skills bake in the things AI-generated Flutter code usually gets wrong:

- **State → UI updates** (`state-management`): the #1 bug — data changes but the UI doesn't. A *CRITICAL* section + verify checklist on emitting/assigning a **new immutable instance** (and a **new collection**, never a mutated-in-place list), for both Riverpod and Bloc.
- **Memory & GC** (`optimization`): Dart's generational GC can't free still-referenced objects — always dispose controllers, cancel subscriptions/timers, reduce allocations.
- **const widgets & extraction** (`optimization`, `dart`): prefer a `const` `StatelessWidget` over a helper method; extract repeated Dart logic into named functions.
- **Architecture & file placement** (`flutter`): MVVM + Clean Architecture layers and a feature-first file-placement table.
- **Clean code & SRP** (`dart`): naming, one class = one job, one method = one job.
- **Declarations** (`dart`): when to use `var` / `final` / `const` / `late` / `required`.
- **Theming** (`theming`): centralized Material 3 theme — never hardcode `Color`/`TextStyle`.
- **Stays current** (`state-management`, `networking`, `navigation`, `data-model`): instead of hardcoding versions, these read `pubspec.lock` for the project's version and check pub.dev + the package changelog **only when adding/upgrading** — so they don't go stale.
- **Native & release footguns** (`push-notifications`, `release`, `deep-linking`, `firebase`): the things that pass in debug but break in release or need Xcode/Gradle/hosted-file config AI usually skips — `@pragma('vm:entry-point')` background handlers, Kotlin-DSL signing, `assetlinks.json`/AASA, and never shipping test-mode Firestore rules.
- **Stale-API protection** (`migrations`, `persistence`, `packaging`): each skill flags the deprecated forms AI still emits — `withOpacity`→`withValues`, `textScaleFactor`→`TextScaler`, freezed `when`/`map`→pattern matching, Riverpod `.valueOrNull`→`.value`, Isar/Hive→`drift`/`hive_ce`, `melos.yaml`→pub workspaces. (Note: Groovy Gradle is *not* deprecated — Kotlin DSL is just the new-project default since 3.29.)

Most skills also carry a `## Common mistakes` checklist in the core plus a `reference/anti-patterns.md` with full `avoid → do` examples, covering 30+ of the most frequent Flutter/Dart anti-patterns (unnecessary `!`, `BuildContext` across async gaps, `setState` misuse, logic in `build()`, undisposed controllers/timers, swallowed errors, logged secrets, `FutureBuilder` refires, god classes, magic numbers, dead code, and more).

## Plugin structure

```
flutter-skills/
├── .claude-plugin/
│   └── marketplace.json
├── dart/
│   ├── .claude-plugin/plugin.json
│   └── skills/<name>/
│       ├── SKILL.md          # concise core
│       └── reference/*.md     # loaded on demand
└── flutter/
    ├── .claude-plugin/plugin.json
    ├── hooks/              # SessionStart orchestrator nudge + skill-usage logger
    └── skills/<name>/
        ├── SKILL.md
        └── reference/*.md
```

The repo also ships an **`evals/`** harness — task prompts, objective rubrics, and an **automated runner** (`evals/run.sh`) that generates **with-skill vs baseline** output and scores it with an LLM judge. On the 7-case high-signal suite the skills lift a **cost-efficient model (Haiku 4.5) from 38% → 64%** — a **+26 pp** uplift (mean of 2 runs; numbers are noisy at this sample size). On a **frontier model (Opus 4.8)** the baseline is already near-ceiling, so the measurable delta on these single-file snippets is **≈ 0** — the frontier value is cross-file consistency, which this snippet suite doesn't measure. Full numbers, per-run detail, and honest caveats in [`evals/RESULTS.md`](evals/RESULTS.md).

**Dart skills (6):** `dart` · `async` · `data-model` · `analyze` · `test` · `optimization`

**Flutter skills (33):** `flutter` (orchestrator) · `state-management` · `navigation` · `deep-linking` · `networking` · `graphql` · `theming` · `error-handling` · `observability` · `forms` · `animation` · `custom-paint` · `layout` · `responsive` · `accessibility` · `i18n` · `image-assets` · `security` · `firebase` · `persistence` · `flavors-env` · `release` · `ci-cd` · `app-size` · `isolates-background` · `platform-channels` · `push-notifications` · `migrations` · `packaging` · `analyze` · `test` · `optimization` · `review`

## License

[MIT](LICENSE)
