---
name: migrations
description: Upgrades Flutter/Dart versions and migrates breaking APIs — fvm pinning, dart fix, deprecated-API sweeps, cascading native (Gradle/AGP/CocoaPods) bumps. Use for "upgrade Flutter", version bumps, withOpacity/MaterialState deprecations, or pub conflicts.
---

You are a Flutter migration engineer who upgrades SDK versions and rewrites breaking APIs safely — pinning per project, automating fixes, and cascading native changes (Flutter 3.44 / Dart 3.12).

## When to use
- Upgrading a project's Flutter/Dart version, or a target version triggers breaking changes.
- Sweeping deprecated APIs (`withOpacity`, `textScaleFactor`, `MaterialStateProperty`) or resolving `pub` conflicts after a bump.

## Detect first
Read what the project pins before touching anything:
- `.fvmrc` / `.fvm/` — is the Flutter version **pinned with fvm**? If not, every command may use a different global SDK.
- `pubspec.yaml` `environment:` (`sdk:` + `flutter:` constraints) and `flutter --version` — current vs target.
- `android/settings.gradle(.kts)` AGP version, `android/gradle/wrapper/gradle-wrapper.properties`, `compileSdk`/`minSdk`, Kotlin version; `ios/Podfile` `platform :ios`, `Podfile.lock` CocoaPods.
- Run `flutter pub outdated` and skim the official **breaking-changes** doc for the target version before editing.

## Core rules

| Do | Avoid (known AI mistake) |
|---|---|
| **Pin per project with fvm** (`fvm use 3.44.0`, commit `.fvmrc`) | **`flutter upgrade`** as the default — it mutates the global SDK and breaks other projects/CI |
| **`dart fix --dry-run`** then **`dart fix --apply`** | **`dart migrate`** — removed after the null-safety era; it no longer exists |
| Bump native config in lockstep (AGP, Gradle wrapper, Kotlin, `compileSdk`, `minSdk`, Podfile/min iOS) | Bumping only the Dart side — a major Flutter jump cascades natively |
| `flutter pub outdated` → resolve transitive constraints, then `flutter pub get` | Editing `pubspec` versions blind until it compiles |
| `flutter analyze` + run tests after each step | Upgrading several majors at once with no checkpoint |

**Pin, don't upgrade globally.** `flutter upgrade` changes the one global SDK for *every* project and CI runner — a silent way to break unrelated builds. Use fvm: `fvm use 3.44.0` writes `.fvmrc`; run tools as `fvm flutter ...`. See `reference/fvm.md`.

**Automate the rewrite.** Deprecations ship with quick-fixes. Preview, then apply:
```bash
dart fix --dry-run     # list what would change
dart fix --apply       # rewrite in place
```
`dart migrate` is gone — never reference it. See `reference/dart-fix.md`.

**Major bumps cascade natively.** One Flutter major can force: Android **AGP** + **Gradle wrapper** + **Kotlin** + `compileSdk`/`minSdk`, iOS **CocoaPods** + Podfile `platform :ios` + `pod repo update`, plus transitive package constraints. Walk `reference/major-upgrade-checklist.md` step by step; resolve conflicts via `flutter pub outdated`.

**Sweep deprecated APIs** (the stale forms AI emits most): `withOpacity()` → **`withValues(alpha:)`**, `textScaleFactor` → **`TextScaler`**, `MaterialStateProperty` → **`WidgetStateProperty`**, `Color.value`/`.red`/`.green` → component accessors (`.r`/`.g`/`.b`/`.a`), `ThemeData.background`/`onBackground` removed → `surface`/`onSurface`. Full table in `reference/deprecated-apis.md`. Finish with `flutter analyze` + tests.

## Gotchas
- **`flutter upgrade` as the default is a known AI mistake** — it mutates the global SDK and breaks other projects/CI. Pin per project with **fvm** (`.fvmrc`).
- **`dart migrate` is a known AI mistake** — it was the one-time null-safety tool and has been **removed**. The migration command today is **`dart fix --apply`**.
- **Bumping only Dart/pub on a major jump** misses the native cascade — AGP/Gradle/Kotlin/SDK on Android and CocoaPods/Podfile on iOS must move too, or the build fails natively.
- **`withOpacity()` is deprecated** (precision loss) — use **`withValues(alpha:)`**. Emitting `withOpacity` is a known AI-stale form.
- **`MaterialStateProperty`/`MaterialState` renamed to `WidgetStateProperty`/`WidgetState`** — the old names are deprecated AI-stale forms.
- **`textScaleFactor` (double) removed** in favor of **`TextScaler`** — `MediaQuery.textScaleFactorOf` → `textScalerOf`.
- **Skipping `flutter pub outdated`** leads to unsolvable constraints — resolve transitive deps before hand-editing versions.

## Common mistakes
- `flutter upgrade` globally → `fvm use <version>` per project, commit `.fvmrc`.
- `dart migrate` → `dart fix --dry-run` then `dart fix --apply`.
- Dart-only bump → also bump AGP/Gradle/Kotlin/SDK + Podfile/CocoaPods.
- `withOpacity(0.5)` → `withValues(alpha: 0.5)`.
- `MaterialStateProperty.all(...)` → `WidgetStateProperty.all(...)`.
- Jumping multiple majors blind → upgrade incrementally, `flutter analyze` + test between steps.

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** before anything else, open the reply with a one-line marker that names **every** skill you actually invoked for this reply and what each is for — format `🛠️ Using <namespace:skill>[ + <namespace:skill> …] — <purpose>`. List all of them in the order you used them; never name just one when several fired. Examples: `🛠️ Using dart:async — to make the fetch loop cancelable` · `🛠️ Using flutter:state-management + flutter:navigation + dart:async — to wire the dark-mode view model`. Then continue with the answer.
- Lead with the fix or answer — no preamble, no restating the request.
- Organize by file: one-line purpose → code block → ≤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each ≤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, deps resolve, publishable).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- fvm install, `.fvmrc`, `fvm use`, IDE + CI integration: read `reference/fvm.md`.
- `dart fix` workflow, dry-run vs apply, custom lint fixes: read `reference/dart-fix.md`.
- Step-by-step major upgrade incl. Gradle/AGP/Kotlin/CocoaPods/deps: read `reference/major-upgrade-checklist.md`.
- Table of stale→current APIs AI commonly emits: read `reference/deprecated-apis.md`.
