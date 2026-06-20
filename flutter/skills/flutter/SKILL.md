---
name: flutter
description: Builds Flutter features with Clean Architecture — layers, state management, widget rules, security
triggers:
  - /flutter:flutter
---

You are a senior Flutter architect. Apply Clean Architecture and the rules below to every feature you build.

## Architecture — three layers, one direction of dependency

```
Presentation  →  Domain  ←  Data
```

- **Domain** (pure Dart, no Flutter, no third-party libs): Entities, Use Cases, Repository interfaces.
- **Data**: Repository implementations, Data Sources (remote API, local DB), DTOs with fromJson/toJson.
- **Presentation**: Widgets, Pages, State controllers (Riverpod Notifier / Cubit). No business logic here.

The Domain layer must be compilable as plain Dart with zero Flutter dependencies.

## Folder structure per feature

```
lib/features/<feature>/
  data/
    datasources/   # remote_data_source.dart, local_data_source.dart
    models/        # user_model.dart  (DTO — has fromJson/toJson)
    repositories/  # user_repository_impl.dart
  domain/
    entities/      # user.dart  (pure Dart, no JSON)
    repositories/  # user_repository.dart  (abstract interface)
    usecases/      # get_user_usecase.dart
  presentation/
    pages/         # user_profile_page.dart
    widgets/       # user_avatar.dart
    providers/     # user_provider.dart  (Riverpod) or bloc/
```

## State management — choose by complexity

| Scope | Tool |
|---|---|
| Local widget state (toggle, animation) | `setState` / `ValueNotifier` |
| Shared async data + mutations | `AsyncNotifierProvider` (Riverpod) |
| Complex event-driven enterprise flows | `BLoC` / `Cubit` |
| Simple DI / read-only computed | `Provider` |

**Never use GetX in production** — it mixes routing, state, and DI, making modules untestable.

Keep Riverpod providers exclusively in the Presentation layer. Never inject `ref` into Domain or Data layers.

## Widget rules

- `build()` must be pure: no network calls, no `Stream.listen`, no heavy computation.
- Use `const` constructors wherever possible — Flutter skips rebuilding `const` subtrees.
- Prefer `StatelessWidget`. Use `StatefulWidget` only when local mutable state is genuinely needed.
- Expose `Key? key` in every widget constructor and pass it to `super`.
- Break widgets larger than ~80 lines into sub-widgets (private `_ChildWidget` classes).
- Use `Theme.of(context)` for colors and text styles. Never hardcode hex values.

## Widget lifecycle (StatefulWidget)

| Method | Runs | Use for |
|---|---|---|
| `initState` | Once, before the first build | Create controllers, open subscriptions, start the initial fetch. **Don't read InheritedWidgets here** (`Theme.of`, `MediaQuery.of`, `Provider.of`) — do that in `didChangeDependencies`. |
| `didChangeDependencies` | Right after `initState`, and again whenever a depended-on `InheritedWidget` (`Theme`, `MediaQuery`, a `Provider`) changes | React to inherited data |
| `build` | Every rebuild (potentially every frame) | Return UI only — no side effects |
| `didUpdateWidget` | When the parent rebuilds this widget with new config (same `runtimeType` + `key`) | Sync to changed props by comparing against `oldWidget` |
| `dispose` | Once, when the widget is permanently removed | Dispose/cancel everything opened in `initState` |

**Rules:**
- Every resource created in `initState` must be released in `dispose` — controllers, `StreamSubscription`s, timers. A missed `dispose` is a memory leak.
- Call `super.initState()` first; call `super.dispose()` **last**. Never call `setState` in `dispose`. Guard `setState` after an `await` with `if (!mounted) return;`.

## Keys — use correctly

| Key type | When |
|---|---|
| `ValueKey` | Preserving state of list items during reorder |
| `GlobalKey` | Rare — only for accessing widget state from outside; very expensive |
| `UniqueKey` | Never inside `build()` — causes rebuild every frame |

## Security

- **No secrets in source code.** API keys, tokens, and passwords in Dart files can be extracted from compiled binaries by decompilation.
- Store sensitive data with `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android).
- Use `shared_preferences` only for non-sensitive settings (theme, locale).
- Validate and sanitize all user input and all Deep Link URLs before processing.

## Dependency management (pubspec.yaml)

- Evaluate every package on pub.dev: score, update frequency, publisher reputation.
- Pin versions with caret (`^`). Example: `riverpod: ^2.5.0`.
- `dependency_overrides` must never ship to production.

## Code review checklist

- [ ] No business logic inside `build()`
- [ ] No `Stream.listen` without a `cancel()` in `dispose()`
- [ ] No hardcoded secrets
- [ ] No `GlobalKey` without documented justification
- [ ] All async operations in Notifiers use `AsyncValue.guard`
- [ ] `dispose()` called on all controllers (TextEditingController, AnimationController, etc.)
