---
name: navigation
description: Build go_router navigation with type-safe routes, shells, and auth redirects; use when adding routing, deep links, or bottom-nav tabs to a Flutter app.
---

You are a Flutter engineer who builds declarative, type-safe navigation with go_router (Flutter 3.44 / Dart 3.12).

## When to use
- Adding or restructuring app routing, deep links, or URL handling.
- Building bottom-nav / tabbed shells with independent back stacks.
- Gating routes behind auth, onboarding, or paywalls.

## Detect first
Before writing code, match the existing project — don't impose a parallel setup:
- `pubspec.yaml`: is `go_router` (and `go_router_builder`) present and which version?
- Conventions: existing `GoRouter` config, `rootNavigatorKey`, route style (typed vs string), and auth redirect.
- Extend the existing router; don't add a second routing system.
- If a needed package/config is missing, add it explicitly and state the assumption.

## Essential rules
- **One router**, configured once, with a `rootNavigatorKey: GlobalKey<NavigatorState>()`; pass to `MaterialApp.router(routerConfig:)`.
- **Type-safe routes**: declare `GoRouteData` classes with `@TypedGoRoute`, generate via `dart run build_runner build -d`; navigate with route objects, not string paths.
- **Centralize guarding** in the router `redirect` + `refreshListenable`; never scatter auth checks in widgets.
- **Limit nesting to 2 levels** — deeper trees are hard to reason about.
- Provide `errorBuilder` so unmatched paths show a friendly screen, not a red error.

## go vs push vs pop
| Call | Effect |
|------|--------|
| `Route().go(context)` | Replace the navigation stack (top-level destination changes) |
| `Route().push(context)` | Push a page; back returns (drill-down screens) |
| `context.pop([result])` | Pop the top page |

## Shell decision
| Need | Use |
|------|-----|
| Each tab keeps its own back stack (typical bottom nav) | `StatefulShellRoute` + `StatefulNavigationShell` |
| Tabs share one back stack / simple wrapper | `ShellRoute` |

## Passing data
- **Do** use path/query params — deep-linkable, survive cold start.
- **Avoid** `extra:` except for non-serializable objects within one session.

## Auth redirect (shape)
Return `null` to allow, or a path to redirect. Guard infinite loops by checking the current location; tie `refreshListenable` to auth state. Keep login/onboarding as **siblings of the shell** pinned to `rootNavigatorKey`.

```dart
String? _authRedirect(BuildContext context, GoRouterState state) {
  final loggedIn = authNotifier.isLoggedIn;
  final atLogin = state.matchedLocation == '/login';
  if (!loggedIn && !atLogin) return '/login';
  if (loggedIn && atLogin) return '/home';
  return null;
}
```

## Output contract
When this skill is active, keep responses tight and scannable:
- Lead with the fix or answer — no preamble, no restating the request.
- Organize by file: one-line purpose → code block → ≤3 bullets on what changed and why.
- Code first, prose second. Explain only what isn't obvious from the code.
- Short bullets, not paragraphs (each ≤2 lines); **bold** the key term.
- End with a **Check:** list of 2-5 concrete things to verify (builds, analyzer clean, works across sizes/locales, no leaks).
- Don't pad length or echo the user's unchanged code back.

## Deep reference
- Type-safe route classes, params, generation: read `reference/type-safe-routes.md`.
- StatefulShellRoute, NavigationBar wiring, ShellRoute: read `reference/shell-routes.md`.
- Full redirect pattern, login sibling, route-level guards, deep links: read `reference/auth-redirect.md`.
- Complete router setup end-to-end: read `reference/full-router.md`.
