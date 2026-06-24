# Flutter & Dart Skills

A Claude Code marketplace of **21 skills** for writing production-quality **Flutter** and **Dart** code, built on the official Flutter app-architecture guide and current 2026 best practices (Flutter 3.44 / Dart 3.12, Riverpod 3, flutter_bloc, go_router, dio, freezed, Material 3).

Each skill is **token-efficient by design**: a short core `SKILL.md` (rules, decision tables, a strict output contract) plus on-demand `reference/*.md` files that Claude loads only when a task needs the deep examples — so most of the content costs zero tokens until it's actually used.

## How it works — the orchestrator

`/flutter:flutter` is the **entry point**. For any Flutter task it: (1) **detects the project** (Flutter version, packages, state-management in use, folder conventions), (2) **routes to the specialist skills** it needs by invoking them via the Skill tool (e.g. `flutter:riverpod` + `flutter:networking` + `flutter:forms` for a login screen), (3) writes code following the rules, then (4) runs a **self-review** (or `flutter:review`) and confirms a shared **Definition of done**. So you can call one skill and the rest engage automatically — instead of loading everything up front.

## Install

Run these commands inside Claude Code:

```
/plugin marketplace add alisheraxmedov/flutter-skills
/plugin install dart@flutter-dart-marketplace
/plugin install flutter@flutter-dart-marketplace
```

Once installed, skills trigger **automatically** when relevant to your task, or you can invoke one explicitly with `/<plugin>:<skill>`.

## Dart plugin — `/dart:<skill>`

| Skill | What it does |
|-------|--------------|
| `/dart:dart` | Idiomatic Dart 3 — naming, null safety, pattern matching, records, sealed classes, class modifiers |
| `/dart:async` | Futures, streams, isolates — async/await, parallelism, cancellation, no blocking the event loop |
| `/dart:model` | Immutable data & domain models — hand-written sealed unions vs `freezed` + `json_serializable` |
| `/dart:analyze` | Strict `analysis_options.yaml`, `dart analyze --fatal-infos`, `dart fix`, `dart format` |
| `/dart:test` | Unit tests with `package:test` + `mocktail` — AAA pattern, async, edge cases, coverage |
| `/dart:optimization` | `const`/`final` discipline, tight typing, lazy iterables, efficient collections |

## Flutter plugin — `/flutter:<skill>`

| Skill | What it does |
|-------|--------------|
| `/flutter:flutter` | **Orchestrator + architecture** — detects the project, routes to specialist skills, Clean Architecture + MVVM, definition of done |
| `/flutter:riverpod` | Riverpod 3 with code generation — `@riverpod`, Notifier/AsyncNotifier, AsyncValue, lifecycle |
| `/flutter:bloc` | `flutter_bloc` — Cubit vs Bloc, sealed states/events, BlocBuilder/Listener, `bloc_test` |
| `/flutter:navigation` | `go_router` — type-safe routes, ShellRoute tabs, auth redirects, deep links |
| `/flutter:networking` | `dio` + `retrofit` — interceptors, token refresh, typed failures, `Result`-returning repos |
| `/flutter:theming` | Material 3 `ColorScheme.fromSeed`, `TextTheme` roles, `ThemeExtension` tokens, dark mode — never hardcode colors |
| `/flutter:error-handling` | Sealed `Result`/`Failure` types, boundary mapping, global handlers, crash reporting |
| `/flutter:forms` | `Form` + `TextFormField`, validation, focus navigation, controller lifecycle, submit flows |
| `/flutter:animation` | Implicit vs explicit vs prebuilt animations, controller lifecycle, performance |
| `/flutter:responsive` | MediaQuery, LayoutBuilder, breakpoints, adaptive navigation across phone/tablet/desktop |
| `/flutter:i18n` | `flutter_localizations` + ARB + `gen-l10n` — plurals, formatting, RTL, runtime locale switch |
| `/flutter:analyze` | Flutter lints, `analysis_options.yaml`, `use_build_context_synchronously`, CI integration |
| `/flutter:test` | Unit / widget / golden (`alchemist`) / integration tests, coverage, CI gating |
| `/flutter:optimization` | 60/120fps — const widgets, lazy lists, RepaintBoundary, rebuild & memory-leak control |
| `/flutter:review` | Code-review "judge" — audits code/diffs by severity (blocking/should-fix/nit) against the anti-pattern checklist |

## Usage

After installing, just describe what you want — Claude picks the matching skill automatically. To force a specific skill, type its command:

```
/flutter:riverpod
```

Then describe the feature, e.g. *"add an AsyncNotifier that loads and paginates a product list from the repository."* Claude follows the skill's rules to produce production-grade code.

## Built-in best practices

The skills bake in the things AI-generated Flutter code usually gets wrong:

- **State → UI updates** (`riverpod`, `bloc`): the #1 bug — data changes but the UI doesn't. Each skill has a *CRITICAL* section + verify checklist on emitting/assigning a **new immutable instance** (and a **new collection**, never a mutated-in-place list).
- **Memory & GC** (`optimization`): Dart's generational GC can't free still-referenced objects — always dispose controllers, cancel subscriptions/timers, reduce allocations.
- **const widgets & extraction** (`optimization`, `dart`): prefer a `const` `StatelessWidget` over a helper method; extract repeated Dart logic into named functions.
- **Architecture & file placement** (`flutter`): MVVM + Clean Architecture layers and a feature-first file-placement table.
- **Clean code & SRP** (`dart`): naming, one class = one job, one method = one job.
- **Declarations** (`dart`): when to use `var` / `final` / `const` / `late` / `required`.
- **Theming** (`theming`): centralized Material 3 theme — never hardcode `Color`/`TextStyle`.

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
    └── skills/<name>/
        ├── SKILL.md
        └── reference/*.md
```

**Dart skills:** `dart` · `async` · `model` · `analyze` · `test` · `optimization`
**Flutter skills:** `flutter` (orchestrator) · `riverpod` · `bloc` · `navigation` · `networking` · `theming` · `error-handling` · `forms` · `animation` · `responsive` · `i18n` · `analyze` · `test` · `optimization` · `review`

## License

[MIT](LICENSE)
