# Provider lifecycle (Riverpod 3)

## autoDispose by default

In Riverpod 3 with codegen, providers are **autoDispose**: an instance is created when first listened and destroyed when it has no listeners. Each rebuild creates a fresh notifier instance, so do all cleanup in `build` via `ref.onDispose`.

## ref.onDispose — clean up every resource

Register a callback for every timer, controller, or subscription you create.

```dart
@riverpod
Stream<int> ticker(Ref ref) {
  final controller = StreamController<int>();
  final timer = Timer.periodic(const Duration(seconds: 1), (t) => controller.add(t.tick));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
}
```

`ref.onDispose` runs both on autoDispose and on rebuild, so listeners/subscriptions never leak or double up.

## keepAlive — opt out of autoDispose

```dart
@riverpod
Future<Config> appConfig(Ref ref) async {
  ref.keepAlive(); // stays alive after listeners drop (e.g. cache once)
  return ref.watch(apiRepositoryProvider).loadConfig();
}
```

Conditionally keep alive only on success:

```dart
final link = ref.keepAlive();
ref.onDispose(() {}); // optional
final config = await fetch();
// if you want to drop the cache later: link.close();
```

## Other lifecycle hooks

- `ref.onCancel` — last listener removed (before disposal timer).
- `ref.onResume` — a new listener arrives after `onCancel`.
- `ref.onDispose` — provider is destroyed.

## Async-after-dispose safety

An autoDispose provider can be disposed while an `await` is pending. After the await, the notifier may be gone.

```dart
Future<void> refresh() async {
  final data = await _repo.fetch();
  // AsyncValue.guard handles disposed-notifier assignment safely:
  state = await AsyncValue.guard(() async => data);
}
```

For raw `state = ...` after an await, prefer `keepAlive` for the duration of the operation, or re-fetch through `AsyncValue.guard`, which swallows the post-dispose assignment. Never store `BuildContext` or `ref` results across an await without re-checking.

## Cross-provider invalidation

```dart
ref.invalidate(todoListProvider);          // force a rebuild/refetch
ref.invalidateSelf();                       // inside a notifier
ref.listen(authProvider, (prev, next) {     // react to another provider
  if (next.value == null) ref.invalidate(cartProvider);
});
```
