# Bloc — events, on<Event>, emit, transformers

A Bloc is event-driven: dispatch with `add(event)`, handle in `on<Event>` registered in the constructor. Use for complex flows, traceable transitions, or concurrency control.

## Sealed events + handlers

```dart
sealed class TodoEvent {
  const TodoEvent();
}
final class TodoStarted extends TodoEvent { const TodoStarted(); }
final class TodoAdded extends TodoEvent {
  const TodoAdded(this.title);
  final String title;
}
final class TodoDeleted extends TodoEvent {
  const TodoDeleted(this.id);
  final String id;
}

final class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc(this._repo) : super(const TodoLoading()) {
    on<TodoStarted>(_onStarted);
    on<TodoAdded>(_onAdded);
    on<TodoDeleted>(_onDeleted);
  }
  final TodoRepository _repo;

  Future<void> _onStarted(TodoStarted e, Emitter<TodoState> emit) async {
    emit(const TodoLoading());
    final result = await _repo.fetchAll();
    switch (result) {
      case Success(:final value): emit(TodoLoaded(value));
      case Failure(:final failure): emit(TodoError(failure.message));
    }
  }

  Future<void> _onAdded(TodoAdded e, Emitter<TodoState> emit) async {
    final current = state;
    if (current is! TodoLoaded) return;
    await _repo.create(e.title);
    final fresh = await _repo.fetchAll();
    if (fresh case Success(:final value)) emit(TodoLoaded(value)); // new instance
  }

  Future<void> _onDeleted(TodoDeleted e, Emitter<TodoState> emit) async {
    final current = state;
    if (current is! TodoLoaded) return;
    emit(TodoLoaded(current.todos.where((t) => t.id != e.id).toList())); // NEW list
    await _repo.delete(e.id);
  }
}
```

Rules:
- **Register every event** with `on<Event>(handler)`.
- Inject repositories through the constructor.
- Each `emit` is a **new** state instance; collection updates build a **new** list.
- `emit` inside `on<Event>` throws if called after the handler returns; for long-running work check `emit.isDone`.

## Event transformers (concurrency control)

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';

on<SearchChanged>(
  _onSearch,
  transformer: debounce(const Duration(milliseconds: 300)),
);

Transformer<E> debounce<E>(Duration d) =>
    (events, mapper) => events.debounce(d).switchMap(mapper);
```

Built-ins from `bloc_concurrency`: `sequential()`, `restartable()`, `droppable()`, `concurrent()` (default). Use `restartable()` for search, `droppable()` for submit buttons.

## Stream subscriptions with emit.forEach / onEach

Drive a bloc from a stream and cancel via the handler completing (the emitter manages the subscription).

```dart
final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    on<AuthSubscriptionRequested>((e, emit) => emit.forEach<User?>(
          _repo.userStream,
          onData: (user) =>
              user == null ? const Unauthenticated() : Authenticated(user),
          onError: (_, __) => const AuthFailure(),
        ));
  }
  final AuthRepository _repo;
}
```

`emit.forEach` keeps the handler alive (and the subscription open) until the bloc is closed or a new `restartable` event replaces it.

## Cleanup

```dart
@override
Future<void> close() {
  _sub?.cancel();
  return super.close();
}
```
