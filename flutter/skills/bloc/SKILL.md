---
name: bloc
description: Build flutter_bloc state management with Cubit and Bloc; use when structuring feature state, events, side effects, or fixing UI that won't update.
---

You are a Flutter engineer who writes idiomatic flutter_bloc using Cubit and Bloc with Dart 3 sealed classes.

## When to use
- Structuring feature state, events, and side effects with Cubit/Bloc.
- Wiring widgets with `BlocProvider`/`BlocBuilder`/`BlocListener`/`BlocConsumer`.
- Debugging "I called `emit` but the UI didn't change" — see the CRITICAL section below.

## Detect first
Before writing code, match the existing project — don't impose a parallel setup:
- `pubspec.yaml`: is `flutter_bloc`/`bloc`/`bloc_test` present and which version?
- Conventions: existing Cubit vs Bloc usage and state-class style (sealed classes? Equatable?).
- If the project uses **Riverpod instead**, defer to `flutter:riverpod` rather than mixing the two.
- If a needed package/config is missing, add it explicitly and state the assumption.

## Setup

```yaml
dependencies: { flutter_bloc: ^9.0.0, equatable: ^2.0.0 }
dev_dependencies: { bloc_test: ^10.0.0 }
```

## Cubit vs Bloc

| | Cubit | Bloc |
|---|-------|------|
| Style | Imperative — call methods, `emit()` directly | Event-driven — `add(event)`, handled by `on<Event>` |
| Use for | Simple state (toggles, counters, form fields, simple auth) | Complex flows, traceable transitions, debounce/concurrency control |
| Boilerplate | Low | Higher (events + handlers) |

Start with a Cubit; promote to a Bloc when you need an event log or event transformers.

## Sealed states & events (Dart 3)
Sealed classes give **exhaustive `switch`** — the compiler forces every case.

```dart
sealed class TodoState extends Equatable {
  const TodoState();
  @override
  List<Object?> get props => [];
}
final class TodoLoading extends TodoState { const TodoLoading(); }
final class TodoLoaded extends TodoState {
  const TodoLoaded(this.todos);
  final List<Todo> todos;
  @override
  List<Object?> get props => [todos];
}
final class TodoError extends TodoState {
  const TodoError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
```

`emit(const TodoLoading())`; render with an exhaustive `switch` in `BlocBuilder`.

## Widgets

| Widget / API | Purpose |
|--------------|---------|
| `BlocProvider` | Create/provide a bloc to the subtree |
| `BlocBuilder` | Rebuild UI from state (`buildWhen` to filter) |
| `BlocListener` | Side effects: nav, snackbars, dialogs (`listenWhen` to filter) |
| `BlocConsumer` | Build + listen in one widget |
| `context.read<B>()` | One-off access, e.g. dispatch in a callback |
| `context.watch<B>()` | Reactive read inside `build` |
| `context.select` | Rebuild only when a slice changes |

```dart
BlocBuilder<TodoBloc, TodoState>(
  builder: (context, state) => switch (state) {
    TodoLoading() => const CircularProgressIndicator(),
    TodoLoaded(:final todos) => TodoListView(todos),
    TodoError(:final message) => ErrorView(message),
  },
);
```

Dispatch from callbacks: `context.read<TodoBloc>().add(const TodoAdded('x'))`.

## CRITICAL: State updates that actually rebuild the UI
The #1 bug: you `emit` but the UI doesn't change. **Bloc/Cubit drop `emit` when `newState == state`** — so mutate-in-place then emit the same reference is silently ignored and the UI stays stale.

- **Always `emit` a NEW instance.** Build a fresh state object; never mutate the current `state`'s fields.
- **Collections:** never `state.todos.add(x)` then `emit(TodoLoaded(state.todos))`. The same `List` reference is `==`, so with Equatable `newState == state` → **emit dropped**. Build a NEW collection:
  ```dart
  // avoid — same list, == old state, emit ignored, UI stale
  state.todos.add(todo);
  emit(TodoLoaded(state.todos));
  // do — new list every time
  emit(TodoLoaded([...current.todos, todo]));
  emit(TodoLoaded(current.todos.where((t) => t.id != id).toList()));
  ```
- **Value equality is required and double-edged:** Equatable lets equal states correctly skip rebuilds, but if `props` omits a field, a real change compares equal and the emit is dropped. `props` must list ALL fields.
- **Async guards:** after an `await`, the bloc may be closed. Guard with `if (isClosed) return;` (Cubit) or rely on `emit` being a no-op after the handler completes; in `on<Event>` handlers `emit` already throws if used post-completion, so check `emit.isDone` for long-running streams.
- **Side effects** (navigation, snackbars, dialogs) go in `BlocListener`/`listener`, **never** in `BlocBuilder` (builders run many times).

**Verify state→UI checklist:** (1) new state instance emitted, not a mutated field? (2) new collection, not `.add`/`.remove` on the reused list? (3) Equatable `props` cover ALL fields? (4) UI uses `BlocBuilder` / `context.watch` (not `read`)? (5) `isClosed`/`emit.isDone` checked for async/stream emits? (6) loading + error states rendered?

## Cleanup
- Cancel `StreamSubscription`s and close resources in `close()`; call `super.close()` last.
- Guard async emits with `if (isClosed) return;`.
- Inject repositories through the constructor — never construct them inside the bloc.

## Common mistakes
- `setState` for feature/shared state → use a Cubit or Bloc; don't run a real app on `setState`.
- Wrong pattern choice → Cubit for simple state (toggles, forms), Bloc for event-driven flows (logging, transformers).
- Raw `FutureBuilder(future: repo.fetch())` → model async as Bloc states (`Loading`/`Loaded`/`Error`) and render with `BlocBuilder`: FutureBuilder refires every rebuild and loses state.
- Mutating then emitting the same reference → emit a NEW instance/collection (see CRITICAL state→UI section).
- Side effects in `BlocBuilder` → put nav/snackbars/dialogs in `BlocListener`.
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
- Cubit full example (auth, sealed state, Result handling): read `reference/cubit.md`.
- Bloc with events, `on<Event>`, transformers, stream subscriptions: read `reference/bloc.md`.
- Sealed states + Equatable, new-instance / new-collection do/avoid: read `reference/state-design.md`.
- `BlocProvider`/`Builder`/`Listener`/`Consumer`, `buildWhen`/`select`: read `reference/widgets.md`.
- `bloc_test`, `seed`, `act`, stream-based blocs: read `reference/testing.md`.
- Common mistakes with full do/avoid (`setState` vs Cubit/Bloc, FutureBuilder vs Bloc states, Cubit vs Bloc choice): read `reference/anti-patterns.md`.
