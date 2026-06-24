# Finding jank and leaks with DevTools (+ Impeller)

## DevTools views

| DevTools view | Use it to |
|---------------|-----------|
| Performance / Timeline | See per-frame build/layout/raster times; red bars = dropped frames. |
| "Track widget rebuilds" / Rebuild stats | Find widgets rebuilding too often — the targets for `const`/splitting. |
| CPU profiler | Spot expensive methods called during build. |
| Memory view | Watch heap growth and find leaks (objects never freed after disposal). |

Toggle "Highlight repaints" to see which layers repaint each frame — flashing static areas signal a missing `RepaintBoundary` or a too-broad rebuild.

## Workflow

1. Reproduce the jank/growth while recording in the relevant view.
2. **Jank:** look at the Timeline for the costly phase. Long *UI* (build) time → too many/expensive rebuilds → apply `const` + widget extraction + selective rebuilds. Long *Raster* time → too many layers/overdraw → fewer `Opacity`/clips, add targeted `RepaintBoundary`.
3. **Rebuilds:** use rebuild stats to find the widget rebuilding far more than its data changes; extract it or add a selector.
4. **Memory:** snapshot the heap, exercise the screen, snapshot again. Objects that keep accumulating across navigations are leaks — trace their retaining path back to the missing `dispose`/`cancel`/`removeListener`.

## Profile correctly

- Profile on a **physical device in profile mode** (`flutter run --profile`). Debug mode and emulators are **not** representative — debug carries asserts and no JIT optimization; emulators have different GPUs.

## Impeller notes

- Impeller is the **default renderer** on iOS and Android. It precompiles shaders, so the classic "first-run shader jank" is gone — do **not** ship `--bundle-sksl-path` workarounds.
- The optimizations elsewhere in this skill (const, lazy lists, fewer layers, sized images, dispose hygiene) are renderer-agnostic and still apply under Impeller.

## Full optimization checklist

- [ ] `const` on every eligible widget; static subtrees extracted as `const` widgets (not methods).
- [ ] No allocation/logic/I/O inside `build()`.
- [ ] Long/lazy lists use `ListView.builder`/`SliverList`, never `map` + `Column`.
- [ ] Stateful list items have stable `Key`s; fixed-height lists set `itemExtent`.
- [ ] `RepaintBoundary` around frequently animated/painted subtrees only.
- [ ] `SizedBox`/`ColoredBox`/`DecoratedBox` over `Container`; `FadeTransition` over `Opacity`.
- [ ] Images decoded at display size (`cacheWidth`/`cacheHeight`).
- [ ] Controllers/animations disposed, streams cancelled, listeners removed, `mounted` checked post-`await`.
- [ ] Selective rebuilds via state-management selectors.
- [ ] Profiled on a physical device in profile mode with DevTools.
