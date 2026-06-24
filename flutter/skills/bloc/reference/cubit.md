# Cubit — full examples

A Cubit is imperative: call methods, `emit()` a new state directly. Use for simple state (toggles, counters, form fields, simple flows).

## Minimal counter

```dart
final class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1); // new value -> rebuild
  void decrement() => emit(state - 1);
}
```

`int` has value equality, so `emit(state + 1)` is always `!= state`.

## Auth cubit with sealed state + repository

```dart
sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}
final class AuthInitial extends AuthState { const AuthInitial(); }
final class AuthLoading extends AuthState { const AuthLoading(); }
final class AuthLoaded extends AuthState {
  const AuthLoaded(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthInitial());
  final AuthRepository _repo;

  Future<void> login(String email, String pw) async {
    emit(const AuthLoading());
    final result = await _repo.login(email, pw);
    if (isClosed) return; // async guard
    switch (result) {
      case Success(:final value): emit(AuthLoaded(value));
      case Failure(:final failure): emit(AuthError(failure.message));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    if (isClosed) return;
    emit(const AuthInitial());
  }
}
```

Notes:
- **`if (isClosed) return;`** after every `await` — the cubit may have been closed while the request was in flight.
- Inject `AuthRepository` through the constructor; never construct it inside the cubit.
- Each branch emits a **new** sealed state instance.

## Cubit holding a data class (copyWith)

```dart
final class FormCubit extends Cubit<FormState> {
  FormCubit() : super(const FormState());

  void setEmail(String v) => emit(state.copyWith(email: v)); // new instance
  void setPassword(String v) => emit(state.copyWith(password: v));
}
```

Use `copyWith` so each emit is a new instance; the missing `==` would otherwise drop the emit.

## Cleanup

```dart
final class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._repo) : super(const FeedInitial()) {
    _sub = _repo.stream.listen((d) {
      if (!isClosed) emit(FeedLoaded(d));
    });
  }
  final FeedRepository _repo;
  late final StreamSubscription _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
```
