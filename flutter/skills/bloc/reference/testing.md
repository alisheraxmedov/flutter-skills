# Testing with bloc_test

`blocTest` builds a bloc, optionally seeds state, runs `act`, and asserts the emitted state sequence.

## Basic sequence

```dart
blocTest<TodoBloc, TodoState>(
  'emits [Loading, Loaded] on TodoStarted',
  build: () => TodoBloc(fakeRepo),
  act: (bloc) => bloc.add(const TodoStarted()),
  expect: () => [const TodoLoading(), TodoLoaded(fixtureTodos)],
  verify: (_) => verify(() => fakeRepo.fetchAll()).called(1),
);
```

`expect` compares with `==`, so state classes need value equality (Equatable). This is also why a dropped-emit (new state equal to old) shows up as a missing entry.

## Seeding a starting state

```dart
blocTest<TodoBloc, TodoState>(
  'removes a todo from a loaded list',
  build: () => TodoBloc(fakeRepo),
  seed: () => TodoLoaded(fixtureTodos),          // start already loaded
  act: (bloc) => bloc.add(TodoDeleted('1')),
  expect: () => [TodoLoaded(fixtureTodos.where((t) => t.id != '1').toList())],
);
```

## Async setup and timing

```dart
blocTest<AuthCubit, AuthState>(
  'emits [Loading, Loaded] on successful login',
  setUp: () => when(() => fakeRepo.login(any(), any()))
      .thenAnswer((_) async => Success(fixtureUser)),
  build: () => AuthCubit(fakeRepo),
  act: (cubit) => cubit.login('a@b.com', 'pw'),
  wait: const Duration(milliseconds: 300), // for debounced/delayed emits
  expect: () => [const AuthLoading(), AuthLoaded(fixtureUser)],
);
```

## Stream-based blocs

```dart
blocTest<AuthBloc, AuthState>(
  'maps user stream to auth states',
  build: () {
    when(() => fakeRepo.userStream)
        .thenAnswer((_) => Stream.value(fixtureUser));
    return AuthBloc(fakeRepo);
  },
  act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
  expect: () => [Authenticated(fixtureUser)],
);
```

## Tips
- Use `errors: () => [isA<MyException>()]` to assert thrown errors.
- Use `skip:` to ignore the first N states.
- Register fallback values for sealed/custom types with `registerFallbackValue` before `any()` matchers (mocktail).
