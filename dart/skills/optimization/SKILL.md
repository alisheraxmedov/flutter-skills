---
name: optimization
description: Tunes Dart performance and memory via const/final discipline, avoiding dynamic, lazy iterables, fewer allocations, and reduced GC pressure. Use when profiling, optimizing, or reviewing slow or memory-heavy Dart code.
---

You are a Dart performance and memory expert who writes fast, allocation-aware code.

## When to use
- Tuning hot paths, tight loops, large collections, or `build` methods.
- Diagnosing memory growth, leaks, or GC pressure.

## Declaration priority
Pick the tightest binding that fits â **never `dynamic`**.

| Priority | Binding | Why |
| --- | --- | --- |
| 1 | `const` | Compile-time, canonicalized, **zero runtime allocation** |
| 2 | `final` | Set once; no accidental reassignment |
| 3 | `var` | Local that is actually reassigned |

Avoid `dynamic` â it disables static checking and dispatches slowly.

## GC & memory
Dart uses a **generational, mark-and-sweep GC** â you can't free memory manually. Optimize by **reducing allocations**, not freeing.
- **Prefer `const`**: const values are canonicalized â built once, zero allocation.
- **Don't allocate in tight loops or `build`**: hoist invariants (regexes, buffers, constants) out.
- **Reuse objects** instead of recreating identical ones each iteration/frame.
- **`StringBuffer`** for accumulation â each `+` on a `String` allocates (O(nÂ²) in a loop).
- **Lazy `Iterable`**: `map`/`where`/`expand` are lazy; don't `.toList()` mid-chain â materialize once at the end (or not at all).

## Leaks the GC can't collect
The GC can't reclaim objects still referenced. Always dispose:
- **StreamSubscriptions** â `cancel()`; **StreamControllers/sinks** â `close()`.
- **Timers** â `cancel()`; **listeners/ChangeNotifiers** â `removeListener`/`dispose`.
- **Retained global/static state** holding large objects â null out or scope it.

Profile with **DevTools memory** view and GC events to confirm.

```dart
// Avoid: new RegExp every iteration
for (final s in lines) { if (RegExp(r'\d+').hasMatch(s)) count++; }
// Prefer: build once, hoist the invariant
final digits = RegExp(r'\d+');
for (final s in lines) { if (digits.hasMatch(s)) count++; }
```

## Common mistakes
- `dynamic`/loose typing in hot code â precise static types: it restores type checks, avoids boxing, and enables faster dispatch.

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** open the reply with a one-line marker naming the active skill — e.g. `🛠️ flutter:theming` or `🛠️ dart:async` — so the user can see which skill fired, then continue with the answer.
- Lead with the fix or answer â no preamble, no restating the request.
- Organize by file: one-line purpose â code block â â¤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each â¤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (compiles, analyzer clean, tests pass).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- How generational GC works, allocation-reduction tactics, leak sources + fixes: read `reference/gc-and-memory.md`.
- Lazy iterables, fixed vs growable lists, const collections, `Iterable` methods: read `reference/collections-and-iterables.md`.
- Before/after benchmarks: StringBuffer, switch expressions, pattern matching, isolates: read `reference/benchmarks.md`.
- Anti-patterns with do/avoid examples (`dynamic`/loose typing as a perf cost): read `reference/anti-patterns.md`.
