---
name: observability
description: Wires crash reporting, error capture, and structured logging in Flutter â Crashlytics/Sentry, FlutterError.onError + PlatformDispatcher.onError, symbol upload. Use for uncaught errors, recordError, breadcrumbs, obfuscated stack traces, or logging.
---

You are a Flutter observability engineer who captures every error source, ships readable symbolicated crash reports, and logs without leaking secrets (Flutter 3.44 / Dart 3.12).

## When to use
- Adding crash reporting (Crashlytics or Sentry), or crashes aren't showing up / are obfuscated and unreadable.
- Wiring global error capture in `main()`, recording non-fatals, or replacing `print` with structured logging.

## Detect first
Match the existing setup â don't add a second crash reporter:
- Read `pubspec.lock`: `firebase_crashlytics`, `sentry_flutter`, `logging`/`logger` present and versions?
- `main()`: is `FlutterError.onError` set? `PlatformDispatcher.instance.onError`? Any `runZonedGuarded`? An isolate error listener?
- Release build flags: does CI build with `--obfuscate --split-debug-info=...`? Is symbol upload (Crashlytics/Sentry) in the pipeline?
- Existing logger config vs scattered `print(...)` calls.

## Setup (essentials)
1. `flutter pub add firebase_crashlytics` **or** `flutter pub add sentry_flutter`; plus `flutter pub add logging` (run for latest). Baselines: `firebase_crashlytics: ^4`, `sentry_flutter: ^8`, `logging: ^1`.
2. Crashlytics requires Firebase (`flutter:firebase`). Native + symbol-upload steps in `reference/crashlytics.md` / `reference/sentry.md`.
3. Capture **all** error sources in `main()`, then **upload symbols** for obfuscated release builds.

## Core rules

| Do | Avoid (known AI mistake) |
|---|---|
| Set **both** `FlutterError.onError` **and** `PlatformDispatcher.instance.onError` | Only `FlutterError.onError` â async/uncaught errors slip through |
| Use `PlatformDispatcher.onError` for async errors | Wrapping everything in `runZonedGuarded` (the older, heavier pattern) |
| Add an **isolate** error listener (`Isolate.current.addErrorListener`) | Ignoring background-isolate crashes entirely |
| **Upload symbols** for `--obfuscate` builds (Crashlytics/Sentry) | Shipping obfuscated builds with no symbols â unreadable traces |
| Structured logger (`logging`/`logger`), gate verbose behind `kDebugMode` | `print()` everywhere; verbose logs in release |
| `recordError(... fatal: false)` for handled errors; set non-PII user id | Logging tokens/PII into breadcrumbs or crash context |

**Capture every source (the core fix).** Three independent channels â wire them all:
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Framework (build/layout/paint) errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.recordFlutterError(details);
  };
  // 2. Async/uncaught errors â modern replacement for runZonedGuarded
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, fatal: true);
    return true; // handled
  };
  runApp(const MyApp());
}
```
`FlutterError.onError` alone misses async errors; `PlatformDispatcher.instance.onError` is the modern catch-all â you no longer need `runZonedGuarded` for most apps. Isolate errors are a separate channel (see `reference/error-capture.md`).

**Symbolication (release-only footgun).** `--obfuscate --split-debug-info=build/symbols` makes stack traces unreadable unless you upload the matching symbols:
- Crashlytics: `firebase crashlytics:symbols:upload --app=<id> build/symbols` (+ dSYMs on iOS).
- Sentry: upload Dart debug symbols and the iOS dSYM (`sentry-cli` / the Sentry Gradle/Dart plugin).
Skip this and every release crash is a wall of hex. Cross-ref `flutter:release` (obfuscation) and `flutter:ci-cd` (automating upload).

**Logging & redaction.** Use a structured logger, not `print`; gate verbose logs behind `kDebugMode`; **never** log tokens, passwords, emails, or other PII â they leak into breadcrumbs, device logs, and crash context (see `reference/logging.md`).

## Gotchas
- **Only `FlutterError.onError` is a known AI mistake** â it catches framework errors but **not** async/uncaught ones. Add `PlatformDispatcher.instance.onError`.
- **Defaulting to `runZonedGuarded` for global capture is now stale** (mark as AI mistake) â `PlatformDispatcher.instance.onError` is the modern path; reserve zones for narrow cases.
- **Obfuscated release with no symbol upload is a top footgun** â traces are unreadable. Upload Crashlytics/Sentry symbols + iOS dSYM every release.
- **Logging PII/tokens** into breadcrumbs/logs (known AI mistake) â redact; treat crash context as shippable-to-a-vendor data.
- **`print()` in release** floods device logs and isn't level-filtered â use a logger gated by `kDebugMode`.
- **Crashlytics needs a real signal** â it reports on next launch; force a test crash to confirm wiring, and remember debug builds may be filtered.
- **Isolate crashes are invisible** unless you add `Isolate.current.addErrorListener`.

## Common mistakes
- Only `FlutterError.onError` â add `PlatformDispatcher.instance.onError` (+ isolate listener).
- Reaching for `runZonedGuarded` first â use `PlatformDispatcher.onError`.
- `--obfuscate` with no symbols uploaded â wire symbol upload into CI.
- `print()` debugging left in â structured logger gated by `kDebugMode`.
- Tokens/emails in breadcrumbs â redact; set only a non-PII user id.

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
- Full `main()` wiring â `FlutterError.onError` + `PlatformDispatcher.onError` + isolate errors: read `reference/error-capture.md`.
- Crashlytics setup + `crashlytics:symbols:upload` + dSYM: read `reference/crashlytics.md`.
- Sentry setup, symbols/dSYM, tracing/performance: read `reference/sentry.md`.
- Structured logging, levels, redaction, `kDebugMode` gating: read `reference/logging.md`.
