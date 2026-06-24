# Common mistakes & anti-patterns (bloc)

State→UI rebuild bugs (mutating then emitting the same reference, missing
Equatable `props`, side effects in `BlocBuilder`) are covered in the CRITICAL
section of `SKILL.md` and in `reference/state-design.md` — this file covers the
remaining traps.

## 1. `setState` for feature / shared state

`setState` for state more than one widget reads, or for the result of an async
call, gives you no single source of truth, no testable transitions, and forces
sibling widgets to be told to refresh. Use a Cubit (or Bloc) instead.

```dart
// AVOID — feature state trapped in one widget's State
class CartIcon extends StatefulWidget {
  const CartIcon({super.key});
  @override
  State<CartIcon> createState() => _CartIconState();
}

class _CartIconState extends State<CartIcon> {
  List<Item> _items = [];        // siblings can't see this
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await repo.fetchCart();
    setState(() => _loading = false);
  }
}
```

```dart
// DO — a Cubit owns the state; any widget reads it via BlocBuilder
class CartCubit extends Cubit<CartState> {
  CartCubit(this._repo) : super(const CartLoading());
  final CartRepository _repo;

  Future<void> load() async {
    emit(const CartLoading());
    final result = await _repo.fetchCart();
    if (isClosed) return;
    emit(result.fold(CartLoaded.new, CartError.new));
  }
}

class CartIcon extends StatelessWidget {
  const CartIcon({super.key});
  @override
  Widget build(BuildContext context) {
    final count = context.select<CartCubit, int>(
      (c) => switch (c.state) { CartLoaded(:final items) => items.length, _ => 0 },
    );
    return Badge(label: Text('$count'), child: const Icon(Icons.shopping_cart));
  }
}
```

`setState` is still correct for purely-local, ephemeral UI (a toggle inside one
widget, an `AnimationController`). Shared or async → Cubit/Bloc.

## 2. Wrong choice — Cubit vs Bloc, or no pattern at all

Pick by the shape of the problem, and don't run a real app on `setState`.

- **Cubit** for simple, imperative state: toggles, counters, form fields, simple
  auth — call a method, `emit` directly.
- **Bloc** for event-driven flows: when you want a traceable event log, event
  transformers (debounce, `restartable`), or distinct events feeding one handler.

```dart
// Simple toggle — a Cubit is the right size
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);
  void toggle() => emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
```

```dart
// Debounced search across distinct events — promote to a Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._repo) : super(const SearchInitial()) {
    on<QueryChanged>(_onQuery, transformer: restartable()); // cancels stale requests
  }
  final SearchRepository _repo;

  Future<void> _onQuery(QueryChanged e, Emitter<SearchState> emit) async {
    emit(const SearchLoading());
    final result = await _repo.search(e.query);
    emit(result.fold(SearchLoaded.new, SearchError.new));
  }
}
```

Don't reach for a Bloc with events + handlers when a two-line Cubit does the job,
and don't keep promoting `setState` flags as a whole feature grows — move to a
Cubit/Bloc before the state spreads across widgets.

## 3. Raw `FutureBuilder` for app data

`FutureBuilder(future: repo.fetch())` recreates the future on every rebuild, so it
loses loaded state, re-flashes the spinner, and gives no caching, cancellation, or
testability. Model the async lifecycle as Bloc states (`Loading`/`Loaded`/`Error`)
and render with `BlocBuilder`.

```dart
// AVOID — new future every build: refires, flickers, untestable
class UserCard extends StatelessWidget {
  const UserCard(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: repo.fetchUser(id),          // recreated on every rebuild
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        if (snap.hasError) return ErrorView(snap.error!);
        return Text(snap.data!.name);
      },
    );
  }
}
```

```dart
// DO — model the async as states; the Cubit fetches once and caches in state
sealed class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}
final class UserLoading extends UserState { const UserLoading(); }
final class UserLoaded extends UserState {
  const UserLoaded(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
final class UserError extends UserState {
  const UserError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class UserCubit extends Cubit<UserState> {
  UserCubit(this._repo, this.id) : super(const UserLoading()) {
    _load();
  }
  final UserRepository _repo;
  final String id;

  Future<void> _load() async {
    final result = await _repo.fetchUser(id);
    if (isClosed) return;
    emit(result.fold(UserLoaded.new, (f) => UserError(f.message)));
  }
}

// In the UI
BlocBuilder<UserCubit, UserState>(
  builder: (context, state) => switch (state) {
    UserLoading() => const CircularProgressIndicator(),
    UserLoaded(:final user) => Text(user.name),
    UserError(:final message) => ErrorView(message),
  },
);
```

`FutureBuilder` is acceptable for a one-off future you own (e.g. a `showDialog`
result), not for repository/app data that should be cached and shared.

## 4. Stale emit & misplaced side effects (cross-reference)

Mutating the current `state` then emitting the same reference is silently dropped
(`newState == state`), and putting navigation/snackbars in `BlocBuilder` fires them
on every rebuild. Full do/avoid for new-instance/new-collection emits, Equatable
`props`, and `BlocListener` for side effects: see the CRITICAL section in
`SKILL.md` and `reference/state-design.md`.
