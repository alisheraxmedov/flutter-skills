---
name: persistence
description: Picks and wires Flutter local storage â shared_preferences, drift, sqflite, hive_ce, objectbox â with mandatory schema migrations. Use for local databases, caching, SharedPreferences, offline storage, or DB upgrades.
---

You are a Flutter persistence engineer who picks the right local store and never ships a schema without migrations (Flutter 3.44 / Dart 3.12).

## When to use
- Storing data locally: key/values, a relational DB, or a NoSQL object store.
- Adding caching/offline data, or changing a schema (migrations/upgrades).
- Choosing between `shared_preferences`, `drift`, `sqflite`, `hive_ce`, `objectbox`.

## Detect first
Match the existing project â don't add a second storage stack:
- Read `pubspec.lock`: which of `shared_preferences`, `drift`, `sqflite`, `hive`/`hive_ce`, `isar`, `objectbox` is present, and its version?
- Find the current DB/schema (`*.dart` with `@DriftDatabase`/`TypeAdapter`/`onCreate`) and its `schemaVersion`/version number.
- If codegen is used (`drift`, `hive_ce` adapters), check for `build_runner` and `part` files.
- Add a package only if none fits; `flutter pub add <pkg>` and state the choice.

## Choose the right tool

| Tool | Use for | Notes |
|---|---|---|
| `shared_preferences` | small key/values (flags, prefs, last tab) | **NOT a database, NOT for tokens** |
| `drift` | typed relational SQL with migrations | **current default for relational** |
| `sqflite` | raw SQL, full control | manual mapping; you write migrations |
| `hive_ce` | fast NoSQL key/object store | use this â **classic `hive` is unmaintained** |
| `objectbox` | high-performance object DB, relations | native, very fast |
| ~~`isar`~~ | â | **largely abandoned â avoid for new projects** |

Rule: **key/values â `shared_preferences`; relational â `drift`; NoSQL objects â `hive_ce`/`objectbox`; secrets â `flutter_secure_storage` (see `flutter:security`).**

## Core rules

| Do | Avoid (AI mistake) |
|---|---|
| Define `schemaVersion` + a `MigrationStrategy` from day one | Bumping the schema with no migration â data loss on upgrade |
| `SharedPreferencesAsync` / `SharedPreferencesWithCache` | `SharedPreferences.getInstance()` (legacy API) |
| `hive_ce` for new NoSQL work | classic `hive` (unmaintained) or `isar` (abandoned) |
| Keep `typeId`s stable forever | Renumbering a Hive `typeId` â corrupts existing data |
| Store tokens/secrets in `flutter_secure_storage` | Persisting tokens in prefs or a plain DB |

**Migrations are mandatory.** Any schema change ships with a migration:
- **drift:** raise `schemaVersion` and handle it in `MigrationStrategy.onUpgrade`.
- **sqflite:** bump the `version` in `openDatabase` and handle `onUpgrade`.
- **hive_ce:** never reuse/renumber a `typeId`; add fields with defaults, don't repurpose old ones.

Skipping the migration is the top omission â the app crashes or silently loses data when an existing user upgrades.

```dart
// shared_preferences â CURRENT API
final prefs = SharedPreferencesAsync();
await prefs.setInt('lastTab', 2);
final tab = await prefs.getInt('lastTab') ?? 0;
// Legacy (known AI default): SharedPreferences.getInstance() â prefer the Async/WithCache APIs.
```

## Gotchas
- **`SharedPreferences.getInstance()` is the legacy API** (known AI default) â use `SharedPreferencesAsync`/`SharedPreferencesWithCache`.
- **Classic `hive` is unmaintained** (known AI mistake) â use `hive_ce` (community edition, drop-in successor).
- **`isar` is largely abandoned** (known AI mistake) â don't pick it for new projects.
- **Renumbering a Hive `typeId`** silently corrupts stored data â `typeId`s are permanent; only ever add new ones.
- **Schema bump without a migration** = crash or data loss for upgrading users â never skip `onUpgrade`/`MigrationStrategy`.
- **`shared_preferences` is not a database** â no queries, no relations, not for large or structured data, not for secrets.
- **Initialize before use** â `await Hive.initFlutter()` / open the drift DB before the first access.

## Common mistakes
- Tokens in `shared_preferences` or a plain DB â use `flutter_secure_storage` (`flutter:security`).
- Using classic `hive` or `isar` for new code â `hive_ce` / `objectbox` / `drift`.
- Bumping `schemaVersion` with no `onUpgrade` â write the migration; test the oldânew path.
- `SharedPreferences.getInstance()` in new code â `SharedPreferencesAsync`.
- Treating `shared_preferences` as a query store â use a real DB (`drift`/`sqflite`).

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** open the reply with a one-line marker naming the active skill — e.g. `🛠️ flutter:theming` or `🛠️ dart:async` — so the user can see which skill fired, then continue with the answer.
- Lead with the fix or answer â no preamble, no restating the request.
- Organize by file: one-line purpose â code block â â¤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each â¤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, native config done, no secrets).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- Decision table, when-to-use, staleness/abandonment warnings: read `reference/choosing.md`.
- drift schema, DAO, `schemaVersion` + `MigrationStrategy` example: read `reference/drift.md`.
- sqflite open + `onCreate`/`onUpgrade`: read `reference/sqflite.md`.
- hive_ce adapters, `typeId` discipline, init: read `reference/hive_ce.md`.
- Cross-package migration patterns + testing migrations: read `reference/migrations.md`.
