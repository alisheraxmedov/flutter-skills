---
name: riverpod
description: Build Riverpod 3 state management with code generation; use when adding providers, async state, dependency injection, or fixing UI that won't update.
---

You are a Flutter state-management engineer who writes idiomatic Riverpod 3 with code generation.

## When to use
- Adding providers, async data, or dependency injection to a Flutter app.
- Mutating state through `Notifier`/`AsyncNotifier` and wiring widgets to it.
- Debugging "data changed but the UI didn't rebuild" — see the CRITICAL section below.

## Detect first
Before writing code, match the existing project — don't impose a parallel setup:
- `pubspec.yaml`: is `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` present and which version (Riverpod 3 + codegen?), and is `build_runner` configured?
- Conventions: is `ProviderScope` already at the root, and what naming do existing providers/notifiers follow?
- If the project uses **Bloc instead**, say so and defer to `flutter:bloc` rather than mixing the two.
- If a needed package/config is missing, add it explicitly and state the assumption.

## Setup

```yaml
dependencies: { flutter_riverpod: ^3.0.0, riverpod_annotation: ^3.0.0 }
dev_dependencies: { riverpod_generator: ^3.0.0, build_runner: ^2.4.0 }
```

Wrap the app in `ProviderScope`; run `dart run build_runner watch -d`. Every `@riverpod` file needs `part 'file.g.dart';`.

```dart
void main() => runApp(const ProviderScope(child: MyApp()));
```

## The `@riverpod` annotation
Annotate a **function** for read-only/derived values, a **class** for state you mutate.

```dart
@riverpod
ApiRepository apiRepository(Ref ref) => ApiRepository(ref.watch(dioProvider));

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;          // initial state
  void increment() => state++; // reassign state -> rebuild
}
```

Read with `ref.watch(counterProvider)`; call methods with `ref.read(counterProvider.notifier).increment()`.

## Provider types — when to use each

| Type | Generated from | Use for |
|------|----------------|---------|
| `Provider` | `@riverpod T foo(Ref)` | Sync derived values, DI of services/repos |
| `FutureProvider` | `@riverpod Future<T> foo(Ref)` | One-shot async read (no mutation) |
| `StreamProvider` | `@riverpod Stream<T> foo(Ref)` | Subscribing to a stream |
| `Notifier` | `@riverpod class X { T build() }` | Sync mutable state |
| `AsyncNotifier` | `@riverpod class X { Future<T> build() }` | Async state you also mutate |

**Avoid legacy** `StateProvider`, `StateNotifierProvider`, `ChangeNotifierProvider` — deprecated in Riverpod 3. Use `Notifier`/`AsyncNotifier`.

## ref.watch vs read vs listen

| API | Where | Purpose |
|-----|-------|---------|
| `ref.watch` | inside `build` | Reactive dependency; **rebuild on change** |
| `ref.read` | callbacks/event handlers | One-off read; **never in `build`** |
| `ref.listen` | inside `build` | Side effects (snackbar, navigation) on change |

`ref.watch` subscribes the widget. `ref.read` in `build` skips reactivity and is the most common cause of a stale UI.

## AsyncValue
Async providers expose `AsyncValue<T>`; render all three states.

```dart
ref.watch(todoListProvider).when(
  data: (items) => TodoView(items),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorView(e),
);
```

Inside an `AsyncNotifier`, wrap mutations in `AsyncValue.guard` so errors land in `state`:
```dart
state = const AsyncLoading();
state = await AsyncValue.guard(() => _repo.fetch());
```

## CRITICAL: State updates that actually rebuild the UI
The #1 bug: data changes but the UI doesn't. Flutter rebuilds **only when the watched state is a NEW value that is `!=` the old one.** Mutating fields or collections of the existing state object in place does NOT trigger a rebuild.

- **Assign a NEW instance.** `state = state.copyWith(...)` — never mutate `state.field` directly. (`state++` works because it reassigns.)
- **Collections:** never `state.items.add(x)` then reuse the list. The same `List` reference is `==` itself → no rebuild. Build a NEW collection:
  ```dart
  // avoid — mutates and reuses the same list, no rebuild
  state.items.add(todo);
  // do — new list every time
  state = state.copyWith(items: [...state.items, todo]);
  state = state.copyWith(items: state.items.where((t) => t.id != id).toList());
  ```
- **AsyncNotifier:** `state = AsyncData(newValue)` or `state = await AsyncValue.guard(...)` — always a new `AsyncData`/`AsyncValue`.
- **Value equality** (Equatable/freezed) on state lets equal states skip rebuilds and changed states actually differ — which makes correct new-instance creation essential (omit a field from `props` and changes to it are invisible).
- **Subscribe in `build` with `ref.watch`**, not `ref.read`.
- **Slice rebuilds:** `ref.watch(p.select((s) => s.field))` rebuilds only when that field changes.
- **autoDispose + async:** a provider can be disposed mid-`await`; guard before assigning. `AsyncValue.guard` handles this, but for raw `state = ...` check the notifier is still alive.

**Verify state→UI checklist:** (1) new state instance assigned, not mutated? (2) new collection, not `.add`/`.remove` on the reused list? (3) Equatable/freezed `props` cover ALL fields? (4) widget uses `ref.watch` (not `ref.read`) in `build`? (5) async updates guarded for autoDispose? (6) loading + error states rendered?

## Lifecycle
Providers are `autoDispose` by default. Clean up resources in `build` via `ref.onDispose`; opt out with `ref.keepAlive()`.

```dart
@override
Stream<int> build() {
  final timer = Timer.periodic(...);
  ref.onDispose(timer.cancel); // always clean up
  return controller.stream;
}
```

Register `ref.onDispose` for every timer, controller, or subscription you create.

## Common mistakes
- `setState` for shared/async state → keep it in a `Notifier`/`AsyncNotifier`; don't mix ad-hoc `setState` with providers.
- Business state scattered across widgets → centralize in providers; one source of truth.
- `ref.read` in `build` → use `ref.watch` in `build`, `ref.read` only in callbacks (see CRITICAL state→UI section).
- Raw `FutureBuilder(future: repo.fetch())` → use `FutureProvider`/`AsyncNotifier` + `AsyncValue`: it refires every rebuild and loses state; providers cache and are cancel-aware.
- Legacy `StateProvider`/`StateNotifierProvider`/`ChangeNotifierProvider` → use `Notifier`/`AsyncNotifier`.
- See `reference/anti-patterns.md` for full do/avoid.

## Output contract
When this skill is active, keep responses tight and scannable:
- Lead with the fix or answer — no preamble, no restating the request.
- Organize by file: one-line purpose → code block → ≤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each ≤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, UI rebuilds on state change, no leaks).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- Each provider type with a full example + family/parameters: read `reference/providers.md`.
- AsyncNotifier load + mutate-list, `AsyncValue.guard`, optimistic updates: read `reference/async-notifier.md`.
- Full do/avoid rebuild examples incl. collections + `select`: read `reference/state-updates.md`.
- `ProviderContainer`, overrides, widget-test wrapping: read `reference/testing.md`.
- `ref.onDispose`, autoDispose, `keepAlive`, async-after-dispose: read `reference/lifecycle.md`.
- Common mistakes with full do/avoid (`setState` vs Notifier, FutureBuilder vs FutureProvider, watch/read): read `reference/anti-patterns.md`.
