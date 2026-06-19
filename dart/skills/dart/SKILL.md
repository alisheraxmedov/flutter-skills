---
name: dart
description: Writes clean, idiomatic Dart 3 code — naming, null safety, pattern matching, records, sealed classes
triggers:
  - /dart:dart
---

You are an expert Dart 3 developer. Apply every rule below without exception.

## Naming conventions

| Target | Style | Example |
|---|---|---|
| Classes, enums, typedefs, extensions | `UpperCamelCase` | `UserRepository`, `OrderStatus` |
| Files, packages, directories | `lowercase_with_underscores` | `user_repository.dart` |
| Variables, functions, parameters | `lowerCamelCase` | `fetchUser`, `isLoading` |
| Acronyms > 2 chars | Treated as words | `HttpClient`, `userId` (not `HTTPClient`, `userID`) |

## Booleans
Always prefix with `is`, `has`, `should`, or `can`. Never use negative names like `notActive` — `!user.notActive` creates cognitive load.

```dart
// Wrong
bool active = true;
bool notLoaded = false;

// Correct
bool isActive = true;
bool isLoaded = false;
```

## Null safety

- Never use `!` (bang operator) unless the null-impossibility is proven at the call site.
- Prefer `?.` for safe calls and `??` for fallbacks.
- Use `late` **only** for lazy initialization of non-nullable fields that are guaranteed to be set before first read. Never on async-dependent fields.

```dart
// Wrong
String name = user!.name;

// Correct
String name = user?.name ?? 'Anonymous';
```

## Functions and getters

- Function names start with a verb: `fetchUser()`, `buildWidget()`, `validateEmail()`.
- Getters must be cheap, idempotent, and side-effect-free.
- If getting a value requires I/O or heavy computation, make it a method: `fetchPosts()` not `get posts`.

## Dart 3 — pattern matching and switch expressions

Replace all `switch` statements that return values with switch expressions:

```dart
// Old
String label;
switch (status) {
  case OrderStatus.pending:
    label = 'Pending';
    break;
  // ...
}

// Dart 3
final label = switch (status) {
  OrderStatus.pending   => 'Pending',
  OrderStatus.shipped   => 'Shipped',
  OrderStatus.delivered => 'Delivered',
  OrderStatus.cancelled => 'Cancelled',
};
```

The compiler enforces exhaustiveness on enums and sealed classes — a missed case is a compile error, not a runtime crash.

## Dart 3 — records

Use records to return multiple values without a throwaway class:

```dart
(String name, int age) parseUser(Map<String, dynamic> json) {
  return (json['name'] as String, json['age'] as int);
}

final (name, age) = parseUser(json);
```

**Anti-pattern:** Do NOT expose records as public API types between modules. If a structure crosses module boundaries, give it a proper named class.

## Dart 3 — sealed classes

Use sealed classes for exhaustive type hierarchies (replacing abstract classes + manual type checks):

```dart
sealed class AuthState {}
class AuthAuthenticated extends AuthState { final UserModel user; AuthAuthenticated(this.user); }
class AuthUnauthenticated extends AuthState {}
class AuthLoading extends AuthState {}

// Compiler guarantees all cases are handled
final message = switch (state) {
  AuthAuthenticated(user: final u) => 'Welcome, ${u.name}',
  AuthUnauthenticated()            => 'Please log in',
  AuthLoading()                    => 'Loading...',
};
```

## Generics

Always specify type arguments. Never leave raw types:

```dart
// Wrong
List items = [];
Map data = {};

// Correct
List<UserModel> items = [];
Map<String, dynamic> data = {};
```

## Code structure rules

- One public class per file.
- File name matches the class name in snake_case.
- Keep functions under 20 lines; extract if longer.
- No `print()` in production code — use a logger or remove.
- `dependency_overrides` in pubspec.yaml must never ship to production.
