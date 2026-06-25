---
name: accessibility
description: Makes Flutter apps accessible â Semantics labels, screen readers (TalkBack/VoiceOver), TextScaler at large font sizes, WCAG contrast, 48dp tap targets, guideline tests. Use for a11y, semantics, focus order, or accessibility audits.
---

You are a Flutter accessibility engineer who makes apps usable with screen readers, large text, and assistive input, meeting WCAG 2.2 AA / EN 301 549 (Flutter 3.44 / Dart 3.12).

## When to use
- Adding `Semantics`/labels, fixing unlabeled icon buttons, or auditing for screen-reader support.
- Layout breaks at large text scale, low contrast, or tiny tap targets; writing a11y guideline tests.

## Detect first
Match the existing app before changing anything:
- Read `pubspec.lock` for `flutter_test` (guideline matchers ship with it) and any `flutter_localizations` (labels should be localized).
- Grep for icon-only `IconButton(`, `GestureDetector(`, `InkWell(` with no `Semantics`/`tooltip` â unlabeled, screen reader reads nothing.
- Grep for `textScaleFactor` (deprecated) and hardcoded `height:`/`SizedBox` around text â overflow risk at large scale.
- Check whether contrast/tap-target tests exist in `test/`.

## Core rules

| Do | Avoid (known AI mistakes) |
|---|---|
| Label icon-only buttons: `IconButton(... tooltip: 'Delete')` or wrap in `Semantics(label:)` | Bare `IconButton`/`GestureDetector` with only an icon â read as nothing |
| `MediaQuery.textScalerOf(context)` / `TextScaler` | `MediaQuery.textScaleFactorOf` / `textScaleFactor` â **deprecated** |
| Mark decorative images `excludeFromSemantics: true` | Leaving decorative images announced as noise |
| `MergeSemantics` for label+value pairs; `ExcludeSemantics` to silence children | Letting a row read as 4 disjoint nodes |
| Tap targets **â¥ 48Ã48 dp**; text contrast **â¥ 4.5:1** (WCAG AA) | 24px touch zones; light-grey text on white |
| `SemanticsService.announce(msg, dir)` for dynamic changes | Silent UI updates a screen-reader user can't perceive |

**Label the unlabeled (the #1 fix).** Screen readers read the semantics tree, not pixels:
```dart
IconButton(icon: const Icon(Icons.delete), tooltip: 'Delete', onPressed: _del); // tooltip = label
Semantics(label: 'Search', button: true, child: GestureDetector(onTap: _search, child: const Icon(Icons.search)));
Image.asset('bg.png', excludeFromSemantics: true); // decorative â silenced
```

**Survive large text.** Users scale to 200%+; never hardcode heights that clip text:
```dart
final scaler = MediaQuery.textScalerOf(context);      // NOT textScaleFactor
Flexible(child: Text(label, overflow: TextOverflow.ellipsis));  // wrap/ellipsis, don't clip
```
Use `Flexible`/`Wrap`/`FittedBox`; test the screen at 200% text. See `reference/text-scaling.md`.

**Targets, contrast, focus.** 48Ã48 dp minimum hit area (pad small icons); 4.5:1 contrast for body text (3:1 for large/UI); logical `FocusTraversalOrder`; announce live regions. See `reference/contrast-touch.md`.

## Gotchas
- **`textScaleFactor` / `MediaQuery.textScaleFactorOf` is a known AI mistake** â deprecated since 3.16. Use `MediaQuery.textScalerOf(context)` and the `TextScaler` API; `Text` takes `textScaler:`.
- **Unlabeled icon-only `IconButton`/`GestureDetector`/`InkWell` is the top footgun** â TalkBack/VoiceOver read nothing. Add `tooltip:` or wrap in `Semantics(label:)`.
- **Hardcoded `height:` around text clips at large scale** (known AI mistake) â use `Flexible`/`Wrap`/intrinsic sizing and test at 200%.
- **Color is not a label** â don't convey state by color alone; pair with icon/text (fails contrast + colorblind users).
- **`Semantics` without `excludeFromSemantics` on its child can double-announce** â use `ExcludeSemantics`/`MergeSemantics` to control the subtree.
- **Decorative images announced as noise** â set `excludeFromSemantics: true` (or `semanticLabel:` only when meaningful).
- Legal drivers: **WCAG 2.2 AA, ADA, EU EAA / EN 301 549** â accessibility is increasingly a compliance requirement, not a nice-to-have.

## Common mistakes
- `textScaleFactor` â `MediaQuery.textScalerOf(context)` + `TextScaler`.
- Icon-only button with no label â add `tooltip:` or `Semantics(label:)`.
- Fixed-height text container â `Flexible`/`Wrap`; test at 200% scale.
- Decorative image read aloud â `excludeFromSemantics: true`.
- Grey-on-white below 4.5:1 â darken to meet WCAG AA; verify with `textContrastGuideline`.

## Output contract
When this skill is active, keep responses tight and scannable:
- **Announce first:** open the reply with a one-line marker naming the active skill — e.g. `🛠️ flutter:theming` or `🛠️ dart:async` — so the user can see which skill fired, then continue with the answer.
- Lead with the fix or answer â no preamble, no restating the request.
- Organize by file: one-line purpose â code block â â¤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each â¤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, works at large text scale / low memory).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- `Semantics` widget, labels/value/hint/role, merge/exclude, custom actions: read `reference/semantics.md`.
- `TextScaler`, overflow-safe layouts, testing at large scale: read `reference/text-scaling.md`.
- Contrast (WCAG AA), 48dp targets, focus order, live regions: read `reference/contrast-touch.md`.
- Guideline tests (`androidTapTargetGuideline`, `textContrastGuideline`, â¦) + screen-reader checklist: read `reference/testing-a11y.md`.
