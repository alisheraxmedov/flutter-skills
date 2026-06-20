---
name: optimization
description: Optimizes Flutter for 60/120fps — const widgets, rebuild control, lazy lists, memory leak prevention
triggers:
  - /flutter:optimization
---

You are a Flutter performance expert. The target is 60fps (16ms/frame) or 120fps (11ms/frame). Every rule here directly prevents dropped frames or memory leaks.

---

## 1. const widgets — zero rebuild cost

`const` widgets are instantiated once at compile time and never rebuilt, even when a parent rebuilds.

```dart
// Wrong — rebuilt every frame
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
}

// Correct — skipped by the diff algorithm entirely
Widget build(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
}
```

**Rule:** Run `flutter analyze` — `prefer_const_constructors` flags every missed opportunity.

### const avoids per-build allocation; hoist for clarity

A non-`const` constructor written inline in `build()` allocates a new object on every rebuild — `const` avoids that. Dart canonicalizes `const` expressions to one shared instance, so an inline `const` is already reused across builds. Promoting reused constants to `static const` class fields is therefore a readability / single-source win, not extra performance:

```dart
class _MyWidgetState extends State<MyWidget> {
  static const _padding = EdgeInsets.all(16);
  static const _gap = SizedBox(height: 8);

  @override
  Widget build(BuildContext context) => Padding(padding: _padding, child: ...);
}
```

### Centralize repeated spacing as design tokens

When the same spacing values repeat across screens, declaring them per-widget breaks consistency. Collect them in one place so they stay uniform and can be changed from a single source:

```dart
// app_spacing.dart
abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

// usage
const SizedBox(height: AppSpacing.sm);
Padding(padding: const EdgeInsets.all(AppSpacing.md), child: ...);
```

---

## 2. Surgical rebuilds — never setState at the top

`setState()` on a parent widget triggers `build()` on the entire subtree. Isolate mutable state as low as possible.

```dart
// Wrong — rebuilds the whole screen for a counter
class _HomeState extends State<HomeScreen> {
  int _count = 0;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const ExpensiveHeader(),     // rebuilt unnecessarily
      Text('$_count'),
      ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('+')),
    ]);
  }
}

// Correct — isolate state to the smallest widget
class _CounterButton extends StatefulWidget { ... }
// ExpensiveHeader is never rebuilt
```

Alternatives to `setState` for cross-widget updates: `ValueListenableBuilder`, `StreamBuilder`, Riverpod `Consumer`, BLoC `BlocBuilder`.

---

## 3. Lazy lists — always use builders

`ListView(children: [...])` renders **all** children immediately, even those off-screen.

```dart
// Wrong — renders all 10,000 items at once
ListView(children: items.map((e) => ItemCard(item: e)).toList())

// Correct — renders only visible items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => ItemCard(item: items[i]),
)
```

**For fixed-height items** — add `itemExtent`. The scroll engine then pre-calculates offsets without measuring each item:

```dart
ListView.builder(
  itemCount: items.length,
  itemExtent: 72.0,              // enables O(1) scroll position calculation
  itemBuilder: (_, i) => ItemTile(item: items[i]),
)
```

---

## 4. FadeTransition over Opacity for animations

`Opacity` is composited on the GPU every frame. `FadeTransition` uses the animation layer directly — no extra composite pass.

```dart
// Wrong — expensive GPU composite every frame
Opacity(opacity: _animation.value, child: child)

// Correct — leverages the render layer, no compositing cost
FadeTransition(opacity: _animation, child: child)
```

---

## 5. RepaintBoundary for high-frequency updates

Wrap rapidly-changing widgets (timers, live counters, charts) to isolate their repaint from the rest of the screen.

```dart
RepaintBoundary(
  child: LiveCounterWidget(),   // repaints at 60fps without dirtying the parent layer
)
```

---

## 6. Memory leaks — the silent killer

Memory leaks cause gradual slowdown, increased battery drain, and eventual OOM crashes.

### 6a. Always dispose controllers

```dart
class _MyState extends State<MyWidget> {
  late final TextEditingController _textCtrl;
  late final AnimationController _animCtrl;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _animCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
```

### 6b. Cancel stream subscriptions

```dart
StreamSubscription<Event>? _subscription;

@override
void initState() {
  super.initState();
  _subscription = eventStream.listen(_onEvent);
}

@override
void dispose() {
  _subscription?.cancel();   // without this, the listener keeps the widget in memory
  super.dispose();
}
```

**Prefer `StreamBuilder`** — it manages subscription lifecycle automatically.

### 6c. Check `mounted` before setState after async gaps

```dart
Future<void> _loadData() async {
  final data = await repository.fetch();
  if (!mounted) return;        // widget may have been disposed during the await
  setState(() => _data = data);
}
```

### 6d. Never store BuildContext in long-lived objects

`BuildContext` holds a reference to the entire widget subtree. Storing it in a singleton, provider, or async closure prevents garbage collection of the entire branch.

```dart
// Wrong
class MyService {
  late BuildContext context; // keeps widget tree alive forever
}

// Correct — pass context only at the call site, never store it
```

---

## 7. Profiling checklist

Use **Flutter DevTools** (Performance and Memory tabs):

- [ ] Navigate between screens in a loop → memory should not grow unboundedly
- [ ] Check the Performance overlay (red bars = jank)
- [ ] Use Timeline view to find expensive `build()` / `layout()` / `paint()` calls
- [ ] Use Memory tab's Allocation Profiler to find retained objects after screen disposal

```bash
flutter run --profile          # profile mode — closest to release performance
flutter run --profile --trace-systrace
```
