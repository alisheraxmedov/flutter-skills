# Bloc widgets — provider, builder, listener, consumer

## BlocProvider — create & provide

```dart
BlocProvider(
  create: (context) =>
      TodoBloc(context.read<TodoRepository>())..add(const TodoStarted()),
  child: const TodoView(),
);
```

Multiple blocs:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => TodoBloc(context.read<TodoRepository>())..add(const TodoStarted())),
    BlocProvider(create: (_) => AuthCubit(context.read<AuthRepository>())),
  ],
  child: const App(),
);
```

`BlocProvider` disposes the bloc automatically when removed. Use `BlocProvider.value` to pass an existing instance (e.g. across a route) — it will NOT dispose it.

## BlocBuilder — rebuild UI from state

```dart
BlocBuilder<TodoBloc, TodoState>(
  builder: (context, state) => switch (state) {
    TodoInitial() || TodoLoading() => const CircularProgressIndicator(),
    TodoLoaded(:final todos) => TodoListView(todos),
    TodoError(:final message) => ErrorView(message),
  },
);
```

Filter rebuilds with `buildWhen`:

```dart
BlocBuilder<TodoBloc, TodoState>(
  buildWhen: (prev, curr) => prev != curr, // default; narrow further if needed
  builder: (context, state) => /* ... */,
);
```

## BlocListener — side effects only

Navigation, snackbars, and dialogs go here — NOT in `BlocBuilder` (builders run many times).

```dart
BlocListener<AuthCubit, AuthState>(
  listenWhen: (prev, curr) => curr is AuthError,
  listener: (context, state) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text((state as AuthError).message))),
  child: const LoginForm(),
);
```

## BlocConsumer — build + listen together

```dart
BlocConsumer<AuthCubit, AuthState>(
  listenWhen: (p, c) => c is AuthLoaded,
  listener: (context, state) => context.go('/home'),
  buildWhen: (p, c) => c is! AuthLoaded,
  builder: (context, state) => switch (state) {
    AuthLoading() => const CircularProgressIndicator(),
    AuthError(:final message) => ErrorView(message),
    _ => const LoginForm(),
  },
);
```

## Reading & dispatching from context

```dart
context.read<TodoBloc>().add(const TodoAdded('x')); // dispatch in a callback
final bloc = context.watch<TodoBloc>();             // reactive read in build
final count = context.select((TodoBloc b) =>        // rebuild only on slice change
    b.state is TodoLoaded ? (b.state as TodoLoaded).todos.length : 0);
```

- **`read`** — one-off, for callbacks; never to rebuild.
- **`watch`** — subscribes the whole `build` to every state change (prefer `BlocBuilder` for scoping).
- **`select`** — rebuilds only when the selected slice changes (slice needs `==`).
