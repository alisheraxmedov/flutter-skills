# Testing Riverpod providers

## ProviderContainer + overrides (unit tests)

Build a `ProviderContainer`, override dependencies with fakes, and always `addTearDown(container.dispose)`.

```dart
test('loads todos', () async {
  final container = ProviderContainer(
    overrides: [
      todoRepositoryProvider.overrideWithValue(FakeTodoRepo()),
    ],
  );
  addTearDown(container.dispose);

  // initial state is loading
  expect(container.read(todoListProvider), const AsyncLoading<List<Todo>>());

  // await the load
  await container.read(todoListProvider.future);
  expect(container.read(todoListProvider).value, hasLength(2));
});
```

## Overriding a Notifier/AsyncNotifier

```dart
ProviderContainer(
  overrides: [
    todoListProvider.overrideWith(() => FakeTodoList()), // returns a notifier instance
  ],
);
```

## Listening to emitted states

`container.listen` captures successive values — useful for asserting a sequence after an action.

```dart
test('add appends a todo', () async {
  final container = ProviderContainer(
    overrides: [todoRepositoryProvider.overrideWithValue(FakeTodoRepo())],
  );
  addTearDown(container.dispose);
  await container.read(todoListProvider.future);

  await container.read(todoListProvider.notifier).add('new');

  expect(container.read(todoListProvider).value, contains(predicate<Todo>((t) => t.title == 'new')));
});
```

## Widget tests — wrap in ProviderScope

```dart
testWidgets('shows todos', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [todoRepositoryProvider.overrideWithValue(FakeTodoRepo())],
      child: const MaterialApp(home: TodosPage()),
    ),
  );
  await tester.pumpAndSettle(); // let the future resolve
  expect(find.byType(TodoView), findsOneWidget);
});
```

## Tips
- Override at the **lowest** level you can (the repository), so the real provider logic still runs.
- `overrideWithValue` for a constant; `overrideWith` to supply a builder/notifier.
- For `keepAlive` providers, disposing the container still cleans them up in tests.
