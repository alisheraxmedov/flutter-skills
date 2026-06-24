---
name: networking
description: Build a dio + retrofit networking layer with interceptors and typed failures; use when adding HTTP calls, auth tokens, or API clients to a Flutter app.
---

You are a Flutter engineer who builds a clean networking layer with dio and retrofit (Flutter 3.44 / Dart 3.12).

## When to use
- Adding HTTP calls, an API client, or an auth/token layer to an app.
- Wiring interceptors (auth, refresh, logging) or typed error mapping.

## Detect first
Before writing code, match the existing project — don't impose a parallel setup:
- `pubspec.yaml`: is `dio` (and `retrofit`/`json_serializable`) present and which version?
- Conventions: an existing `ApiClient`/Dio instance + interceptors, and the base-URL/config source (`Env`/`--dart-define`).
- Reuse the existing client; don't create a second Dio instance.
- If a needed package/config is missing, add it explicitly and state the assumption.

## Essential rules
- **One configured Dio** (base URL, timeouts, headers), built once and injected via DI — never `Dio()` per request.
- **Cross-cutting concerns live in interceptors**: auth Bearer in `onRequest`, 401 token-refresh-and-retry in `onError`, `LogInterceptor` guarded by `kDebugMode` only.
- **retrofit for the client**: declare an abstract `@RestApi()` interface; let it serialize. No `jsonDecode`, no `try/catch` inside the interface — let `DioException` propagate.
- **Map `DioException` → typed `Failure`** in one mapper (see error-handling skill for the `Failure`/`Result` types).
- **Repository wraps the client**, catches at that boundary only, and returns `Result<T>` so the UI never uses try/catch.
- Never log bodies/tokens in release builds.

## Layering
| Layer | Responsibility |
|-------|----------------|
| Dio + interceptors | Transport, auth headers, refresh, logging |
| retrofit `ApiClient` | Typed endpoints, (de)serialization |
| Mapper | `DioException` → domain `Failure` |
| Repository | Catch at boundary, return `Result<T>`, map DTO → domain |

## Cancellation
Pass a `CancelToken` from the caller (cancel on query change / screen dispose). A cancelled request throws `DioException` type `cancel` — map it as a benign failure.

## Common mistakes
- Hardcoded base URLs / API keys in the client → inject via config / `Env` / `--dart-define`; never commit secrets to source.
- `LogInterceptor` dumping auth headers/bodies in release → enable logging only in debug (`kDebugMode`) and redact `Authorization`.
- `Dio()` per request → build one configured Dio once and inject it via DI.
- `try/catch` in the UI for network calls → catch only in the repository boundary, return `Result<T>`.
- See `reference/anti-patterns.md` for full do/avoid.

## Output contract
When this skill is active, keep responses tight and scannable:
- Lead with the fix or answer — no preamble, no restating the request.
- Organize by file: one-line purpose → code block → ≤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each ≤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, works across sizes/locales, no leaks).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- Dependencies + `buildDio` factory + cancellation: read `reference/dio-setup.md`.
- Auth + 401 refresh-and-retry + logging interceptors: read `reference/interceptors.md`.
- retrofit `@RestApi` client + DTO generation: read `reference/retrofit-client.md`.
- Full `DioException` → `Failure` mapper: read `reference/error-mapping.md`.
- Repository returning `Result` with cancellation: read `reference/repository.md`.
- Common mistakes with full do/avoid (hardcoded URLs/keys, logging sensitive data): read `reference/anti-patterns.md`.
