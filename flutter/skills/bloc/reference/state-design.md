# State design + updates that rebuild the UI (Bloc)

Bloc and Cubit **drop `emit` when `newState == state`**. With Equatable on your state, a new object whose fields equal the old one compares `==` and the emit is silently ignored — the UI stays stale. So state design and new-instance creation are inseparable.

## Sealed states + Equatable

```dart
sealed class TodoState extends Equatable {
  const TodoState();
  @override
  List<Object?> get props => [];
}
final class TodoInitial extends TodoState { const TodoInitial(); }
final class TodoLoading extends TodoState { const TodoLoading(); }
final class TodoLoaded extends TodoState {
  const TodoLoaded(this.todos, {this.filter = Filter.all});
  final List<Todo> todos;
  final Filter filter;
  @override
  List<Object?> get props => [todos, filter]; // EVERY field, or changes are invisible
}
final class TodoError extends TodoState {
  const TodoError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
```

- **Sealed** → exhaustive `switch` in the builder; the compiler forces every case.
- **Equatable `props` must list every field.** Omit `filter` and a filter change compares equal → emit dropped → UI never updates.

## Scalar/object change — new instance, never mutate

```dart
// AVOID — mutating the current state's field; no new instance, emit may be dropped
(state as TodoLoaded).filter = Filter.active; // also: fields are final
// DO — emit a new instance (copyWith on a data state, or a fresh sealed instance)
final current = state as TodoLoaded;
emit(TodoLoaded(current.todos, filter: Filter.active));
```

## Collections — build a NEW collection

The classic dropped-emit bug:

```dart
final current = state as TodoLoaded;

// AVOID — same List reference; newState == state -> emit IGNORED -> UI stale
current.todos.add(todo);
emit(TodoLoaded(current.todos));

// DO — new List every time
emit(TodoLoaded([...current.todos, todo]));                          // add
emit(TodoLoaded(current.todos.where((t) => t.id != id).toList()));    // remove
emit(TodoLoaded([                                                     // update item
  for (final t in current.todos)
    if (t.id == id) t.copyWith(done: !t.done) else t,
]));
```

Same for `Map`/`Set`: `{...current.map, k: v}`, `{...current.set, x}`.

## Async / stream emits — guard

A bloc can be closed mid-`await`.

```dart
// Cubit
Future<void> load() async {
  emit(const TodoLoading());
  final data = await _repo.fetchAll();
  if (isClosed) return;        // guard before emit
  emit(TodoLoaded(data));
}
```

```dart
// Bloc handler — emit throws after the handler returns; for streams check isDone
on<Subscribed>((e, emit) async {
  await for (final batch in _repo.stream) {
    if (emit.isDone) break;    // emitter closed
    emit(TodoLoaded(batch));
  }
});
```

## Verify state→UI checklist
1. New state instance emitted (`copyWith` or fresh sealed instance), not a mutated field?
2. New collection built (spread / `.where().toList()` / collection-for), not `.add`/`.remove` on the reused list?
3. Equatable `props` cover ALL fields?
4. UI uses `BlocBuilder` / `context.watch` (not `read`) to rebuild?
5. `isClosed` (Cubit) / `emit.isDone` (Bloc) checked for async and stream emits?
6. Loading and error states rendered, not just the data state?
