# Orchestration — routing, multi-skill workflows, and the review judge

This skill is the **entry point** for Flutter work. Its job is to route to specialists and enforce a consistent workflow, not to do everything itself.

## The rule

Invoke the matching specialist skill via the **Skill tool** *before* writing code. Treat a >1% chance that a skill applies as "invoke it" — if it turns out irrelevant, you don't have to use it. Announce briefly: "Using `flutter:state-management` to wire the view model."

User instructions always win: if the user says "don't use Bloc" or "skip tests," follow the user.

## Skill priority when several apply

1. **Detect/architecture first** — this skill: figure out the project and where files go.
2. **Foundational specialists** — `flutter:networking`, `flutter:error-handling`, `dart:model` (data + failures the feature depends on).
3. **State** — `flutter:state-management` (covers Riverpod and Bloc; follows whichever the project uses).
4. **UI specialists** — `flutter:navigation`, `flutter:forms`, `flutter:theming`, `flutter:responsive`, `flutter:animation`, `flutter:i18n`.
5. **Quality last** — `flutter:test`, `flutter:analyze`, `flutter:optimization`, then `flutter:review`.

## Worked routing examples

| Request | Skills to invoke (in order) |
|---|---|
| "Add a login screen that calls our API" | detect → `flutter:networking` → `flutter:error-handling` → `flutter:state-management` → `flutter:forms` → `flutter:test` → `flutter:review` |
| "Make the app support dark mode" | detect → `flutter:theming` → `flutter:review` |
| "The list screen is janky" | detect → `flutter:optimization` → `flutter:review` |
| "Add a bottom-nav with 3 tabs" | detect → `flutter:navigation` → `flutter:responsive` → `flutter:review` |
| "Translate the app to Uzbek + RTL" | detect → `flutter:i18n` → `flutter:review` |

## Choosing the state approach

- Use `flutter:state-management` — it covers **Riverpod** and **Bloc/Cubit** and follows whichever the project already uses.
- Neither present and the user has no preference → default to **Riverpod** (state the assumption). Never introduce both into one project.

## Dispatching a review subagent (the "judge")

For multi-file features or risky refactors, run review as a **separate agent** so it starts clean and isn't biased by the implementation context:

1. Finish the implementation.
2. Dispatch a subagent (Task tool) whose job is only: "Review this diff against `flutter:review`'s checklist; report blocking/should-fix/nit issues with concrete fixes. Do not rewrite — report."
3. Apply the blocking + should-fix items, then present.

For small changes, an inline self-review against the used skills' `## Common mistakes` is enough.

## Definition of done (expanded)

- Compiles; `flutter analyze` clean (no new warnings); `dart format` applied.
- Tests written for new logic/widgets and passing.
- No anti-patterns from the used skills' `reference/anti-patterns.md`.
- State→UI verified: a new immutable state/collection is emitted/assigned; UI uses `ref.watch`/`BlocBuilder`.
- All `controllers`, `AnimationController`s, `StreamSubscription`s, `Timer`s disposed/cancelled.
- `BuildContext` not used across async gaps without `context.mounted`.
- Matches project folder structure, naming, and the state-management already in use.
- No hardcoded secrets/URLs/keys; config via `Env`/`--dart-define`.
