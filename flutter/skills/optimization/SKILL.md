---
name: optimization
description: Optimizes Flutter rendering for smooth 60/120fps using const widgets, ListView.builder, and RepaintBoundary. Use when fixing jank, slow scrolling, excessive rebuilds, memory leaks, or sluggish UI.
---

You are a Flutter performance engineer who keeps frames under budget (16ms at 60fps, 8ms at 120fps) by minimizing rebuilds, repaints, and allocations, and who prevents memory leaks.

## When to use
- Diagnosing jank, dropped frames, slow scrolling, or excessive widget rebuilds.
- Hunting memory growth / leaks, or reviewing for `const`, list, and dispose hygiene.

## Frame budget
Each frame may **build** (run `build()`), **layout** (size/position), and **paint** (rasterize). Optimization = do less of each, and localize work so a small change touches a small part of the tree.

## Rebuilds and const
- **Prefer `const` widgets** â canonicalized once, reused, and they **short-circuit rebuilds** of their subtree. Make constructors `const` and pass `const` children wherever values are compile-time constants.
- **Extract a `StatelessWidget` with a `const` constructor, NOT a helper method that returns a `Widget`.**
  - *Avoid:* `_buildChart()` â reruns on every parent rebuild and can never be `const`.
  - *Do:* `const ExpensiveChart()` â a real widget localizes rebuilds and can be `const`.
- Keep `build()` pure and cheap: **no** allocation, parsing, or I/O inside it. Compute once (`initState`/memoized/state selector).
- Selective rebuilds: `ref.watch(p.select(...))` (riverpod), `Selector` (provider), `BlocBuilder` `buildWhen`.

## Lists and painting
- **`ListView.builder`/`SliverList.builder` for long lists** â never `Column(children: list.map(...).toList())`, which builds every child up front.
- Give stateful list items stable `Key`s; set `itemExtent` for fixed-height rows.
- Wrap frequently-repainting subtrees (animation, spinner, video) in `RepaintBoundary` â sparingly; each is its own layer.
- Lighter containers: `SizedBox`/`ColoredBox`/`DecoratedBox` over `Container`; `FadeTransition` over animated `Opacity`. Decode images at display size (`cacheWidth`/`cacheHeight`).

## Memory and leaks
Dart's GC is **generational + mark-and-sweep**; it **cannot collect objects still referenced**. A forgotten subscription, listener, or controller keeps its whole object graph alive â that is a leak. Always:
- **Dispose** controllers and `AnimationController`s in `dispose()`.
- **Cancel** `StreamSubscription`s and `Timer`s; **close** `StreamController`s.
- **Remove** listeners you added (`removeListener`, `ValueNotifier`, `Animation`).
- **Check `mounted`** after every `await` before `setState`/touching `context`; never store `BuildContext` in a long-lived object.
- Reduce allocations in `build()`. Profile heap growth with DevTools Memory view.

## Common mistakes
- `setState` for every tiny change / high in the tree â isolate state in the smallest widget; lift only shared state into a state-mgmt solution.
- `setState` on a large ancestor for a local change â push state down, or use `ValueListenableBuilder` / `select` so only the dependent leaf rebuilds.
- `StatefulWidget` with no mutable state â use `StatelessWidget` so the subtree can be `const`.
- `SingleChildScrollView` + `Column` for many/unbounded items â `ListView.builder` / slivers (lazy, builds only what's visible).
- Controllers/subscriptions/timers created in `build` or never released â create in `initState`, dispose/cancel/close in `dispose` (see `reference/memory-and-leaks.md`).
- `Widget _buildHeader()` helper â extract a real `const StatelessWidget` (see `reference/rebuilds-and-const.md`).
- Stateless vs Stateful confusion â state that changes over the widget's life â Stateful; otherwise Stateless. Missing `const` â see `reference/rebuilds-and-const.md`.

## Gotchas
- **`const` only short-circuits if the *whole* subtree is const** â a single non-const child cascades a rebuild up; one stray non-const node defeats it.
- **`RepaintBoundary` helps only animated/expensive subtrees** â each one is its own layer, so over-adding them costs memory and hurts; don't sprinkle them everywhere.
- **Profile in release/profile mode, not debug** â debug builds are unoptimized (assertions, no JIT inlining); jank numbers from debug are meaningless.

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** open the reply with a one-line marker naming the active skill — e.g. `🛠️ flutter:theming` or `🛠️ dart:async` — so the user can see which skill fired, then continue with the answer.
- Lead with the fix or answer â no preamble, no restating the request.
- Organize by file: one-line purpose â code block â â¤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each â¤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, UI updates, no leaks).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- `const` + extract-widget-vs-method full examples, pure `build()`: read `reference/rebuilds-and-const.md`.
- `ListView.builder`, keys, `itemExtent`, `RepaintBoundary`, light containers, images: read `reference/lists-and-painting.md`.
- GC overview, dispose patterns, and the leak checklist: read `reference/memory-and-leaks.md`.
- Finding jank and leaks with DevTools + Impeller notes: read `reference/devtools.md`.
- Common rebuild/state/list anti-patterns with do/avoid code: read `reference/anti-patterns.md`.
