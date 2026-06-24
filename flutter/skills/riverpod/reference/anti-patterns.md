# Common mistakes & anti-patterns (Riverpod)

State→UI rebuild bugs (mutating instead of reassigning, `ref.read` in `build`,
missing `props`, `select`) are covered in the CRITICAL section of `SKILL.md` and
in `reference/state-updates.md` — this file covers the remaining traps.

## 1. `setState` for shared / async state

Ad-hoc `setState` for state that more than one widget reads, or for the result
of an async call, leaves you with no single source of truth and no caching. Keep
it in a `Notifier`/`AsyncNotifier`.

```dart
// AVOID — local mutable state + manual async juggling in the widget
class CartIcon extends StatefulWidget {
  const CartIcon({super.key});
  @override
  State<CartIcon> createState() => _CartIconState();
}

class _CartIconState extends State<CartIcon> {
  List<Item> _items = [];        // sibling widgets can't see this
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await repo.fetchCart(); // not cancel-aware, refetched per screen
    setState(() => _loading = false);
  }
  // ...
}
```

```dart
// DO — one AsyncNotifier owns the state; any widget watches it
@riverpod
class Cart extends _$Cart {
  @override
  Future<List<Item>> build() => ref.watch(cartRepositoryProvider).fetchCart();

  Future<void> add(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cartRepositoryProvider).add(item);
      return ref.read(cartRepositoryProvider).fetchCart();
    });
  }
}

class CartIcon extends ConsumerWidget {
  const CartIcon({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((s) => s.valueOrNull?.length ?? 0));
    return Badge(label: Text('$count'), child: const Icon(Icons.shopping_cart));
  }
}
```

`setState` is still correct for purely-local, ephemeral UI state (a toggle inside
one widget, an `AnimationController`, scroll offset). The line is: shared or async
→ provider; local and ephemeral → `setState`.

## 2. No pattern — business state scattered across widgets

Don't spread the same logical state across several `StatefulWidget`s and try to
keep them in sync. Centralize in a provider; read with `ref.read` in callbacks and
`ref.watch` in `build`.

```dart
// AVOID — each widget owns a copy; they drift out of sync
class FilterBar extends StatefulWidget { /* holds _filter */ }
class ResultList extends StatefulWidget { /* holds its OWN _filter, must be told to refetch */ }
```

```dart
// DO — one provider; widgets derive from it
@riverpod
class ProductFilter extends _$ProductFilter {
  @override
  Filter build() => const Filter.all();
  void set(Filter f) => state = f;            // mutate via the notifier
}

@riverpod
Future<List<Product>> products(Ref ref) {
  final filter = ref.watch(productFilterProvider); // auto-refetch when filter changes
  return ref.watch(productRepositoryProvider).search(filter);
}

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DropdownButton<Filter>(
        value: ref.watch(productFilterProvider),                 // watch in build
        items: Filter.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
        onChanged: (f) => ref.read(productFilterProvider.notifier).set(f!), // read in callback
      );
}
```

## 3. Raw `FutureBuilder` for app data

`FutureBuilder(future: repo.fetch())` re-invokes `repo.fetch()` on **every
rebuild** (the future is recreated each `build`), so it loses its loaded state,
flashes the spinner, and offers no caching or cancellation. Use a
`FutureProvider`/`AsyncNotifier` + `AsyncValue` instead — the provider caches,
dedupes, and disposes the request when no longer watched.

```dart
// AVOID — future recreated every build: refires, flickers, no cache, no cancel
class UserCard extends StatelessWidget {
  const UserCard(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: repo.fetchUser(id),            // NEW future on every rebuild
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
// DO — FutureProvider caches the result and is cancel-aware
@riverpod
Future<User> user(Ref ref, String id) =>
    ref.watch(userRepositoryProvider).fetchUser(id);

class UserCard extends ConsumerWidget {
  const UserCard(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userProvider(id)).when(
          data: (user) => Text(user.name),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => ErrorView(e),
        );
  }
}
```

`FutureBuilder` is fine for a one-off future you create and own yourself (e.g. a
`showDialog` result), not for repository/app data that should be cached and shared.

## 4. `ref.read` in `build` (cross-reference)

Using `ref.read` inside `build` skips the subscription, so the widget never
rebuilds when the value changes — the most common stale-UI cause. Use `ref.watch`
in `build`, `ref.read` only in callbacks. Full do/avoid plus `select` and
collection rules: see the CRITICAL "State updates that actually rebuild the UI"
section in `SKILL.md` and `reference/state-updates.md`.
