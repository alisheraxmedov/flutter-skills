# State updates that actually rebuild the UI (Riverpod)

Flutter rebuilds a widget only when the value it `ref.watch`es is a **NEW object that is `!=` the previous one**. Mutating the existing state object in place leaves the reference unchanged, so `==` reports "no change" and nothing rebuilds.

## Use a value-equality state class

```dart
@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<Item> items,
    @Default(false) bool checkingOut,
  }) = _CartState;
}
```

freezed (or an Equatable class) gives `==`, `hashCode`, and `copyWith`. Equal states now skip rebuilds; changed states actually differ — which is exactly why creating a correct NEW instance matters.

## Scalar / object fields — copyWith, never mutate

```dart
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  CartState build() => const CartState();

  // avoid — mutates the existing object; same reference, no rebuild
  void brokenCheckout() {
    state.checkingOut == state.checkingOut; // can't even reassign a field this way
  }

  // do — new instance via copyWith
  void startCheckout() => state = state.copyWith(checkingOut: true);
}
```

## Collections — build a NEW collection

The most common stale-UI bug. A `List` is `==` only to itself, so adding to it and reassigning the same reference changes nothing.

```dart
// AVOID — same List reference; no rebuild even though contents changed
void addBroken(Item item) {
  state.items.add(item);          // mutates in place
  state = state.copyWith(items: state.items); // same reference -> == -> no rebuild
}

// DO — new List every time
void add(Item item) =>
    state = state.copyWith(items: [...state.items, item]);

void remove(String id) =>
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());

void updateQty(String id, int qty) => state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.id == id) i.copyWith(qty: qty) else i,
      ],
    );
```

Same rule for `Map` and `Set`: `{...state.map, key: value}`, `{...state.set, x}`.

## AsyncNotifier — new AsyncData / guard

```dart
state = AsyncData([...current, newItem]);             // new AsyncData + new list
state = await AsyncValue.guard(() => _repo.fetchAll()); // new AsyncValue
```

Never mutate the list inside the current `AsyncData` and reassign it.

## Subscribe in build with watch, not read

```dart
// AVOID — read does not subscribe; UI never updates
final cart = ref.read(cartNotifierProvider);

// DO — watch subscribes the widget to changes
final cart = ref.watch(cartNotifierProvider);
```

## Slice rebuilds with select

Rebuild only when one field changes, not the whole state:

```dart
final count = ref.watch(cartNotifierProvider.select((s) => s.items.length));
// this widget rebuilds only when items.length changes
```

`select`'s comparison is `==`, so the selected slice must also have value equality.

## Equatable props must cover every field

If a field is missing from `props` (Equatable) or the freezed constructor, two states that differ only in that field compare equal and the UI won't update.

```dart
class TodoLoaded extends Equatable {
  const TodoLoaded(this.todos, this.filter);
  final List<Todo> todos;
  final Filter filter;
  @override
  List<Object?> get props => [todos, filter]; // include BOTH, not just todos
}
```

## autoDispose: guard async state assignment

An autoDispose provider can be disposed while an `await` is in flight. `AsyncValue.guard` is safe, but a raw `state = ...` after an await can throw on a disposed notifier. Re-read fresh state after the await and let guard handle it, or check liveness before assigning.

## Verify state→UI checklist
1. New state instance assigned (`copyWith` / new `AsyncData`), not a mutated field?
2. New collection built (spread / `.where().toList()` / collection-for), not `.add`/`.remove` on the reused list?
3. Equatable `props` / freezed fields cover ALL state fields?
4. Widget uses `ref.watch` in `build` (not `ref.read`)?
5. Async updates guarded for autoDispose disposal?
6. Loading and error states rendered, not just data?
