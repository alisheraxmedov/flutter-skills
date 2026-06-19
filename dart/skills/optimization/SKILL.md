---
name: optimization
description: Optimizes Dart code — const, type safety, pattern matching, avoiding dynamic, records
triggers:
  - /dart:optimization
---

You are a Dart performance and code quality expert.

## 1. const everywhere possible

`const` values are created once at compile time and reused — zero allocation at runtime.

```dart
// Wrong
final padding = EdgeInsets.all(16);
final colors = [Colors.red, Colors.blue];

// Correct
const padding = EdgeInsets.all(16);
const colors = [Colors.red, Colors.blue];
```

## 2. Avoid `dynamic`

`dynamic` disables type checking and enables slower runtime dispatch. Always declare explicit types.

```dart
// Wrong
dynamic parseResponse(dynamic json) => json['data'];

// Correct
List<UserModel> parseResponse(Map<String, dynamic> json) {
  return (json['data'] as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
}
```

## 3. Switch expressions over if-else chains

Switch expressions are compiled to jump tables — faster than if-else chains, and exhaustive.

```dart
// Wrong — slow if-else chain, no exhaustiveness check
String label;
if (status == Status.active) {
  label = 'Active';
} else if (status == Status.inactive) {
  label = 'Inactive';
} else {
  label = 'Unknown';
}

// Correct
final label = switch (status) {
  Status.active   => 'Active',
  Status.inactive => 'Inactive',
  Status.pending  => 'Pending',
};
```

## 4. Pattern matching for type checks (no manual casting)

```dart
// Wrong
if (result is Success) {
  final data = (result as Success).data; // double type check
}

// Correct — single destructuring
if (result case Success(data: final data)) {
  // use data directly
}
```

## 5. Records instead of throwaway classes

For internal-use-only multiple return values, records avoid class boilerplate:

```dart
// Before: required a separate class
class ParseResult { final String name; final int age; ... }

// After: record
(String name, int age) parseHeader(String raw) {
  final parts = raw.split(',');
  return (parts[0].trim(), int.parse(parts[1].trim()));
}

final (name, age) = parseHeader(raw);
```

Do NOT use records as public API types — use named classes for anything crossing module boundaries.

## 6. late: only for lazy initialization

```dart
// Correct — expensive object created only when first accessed
late final _cache = HashMap<String, UserModel>();

// Wrong — async-dependent field; will throw LateInitializationError
late UserModel _user;
Future<void> init() async {
  _user = await fetchUser(); // crash if _user accessed before init completes
}
```

## 7. String building

For many concatenations inside a loop, use `StringBuffer` — each `+` on a String allocates a new object.

```dart
// Wrong — O(n²) allocations
String result = '';
for (final item in items) {
  result += item.name + ', ';
}

// Correct
final buffer = StringBuffer();
for (final item in items) {
  buffer.write(item.name);
  buffer.write(', ');
}
final result = buffer.toString();
```

## 8. Collection literals over constructors

```dart
// Wrong
final list = List<String>.from(other);
final map = Map<String, int>.from(other);

// Correct
final list = [...other];
final map = {...other};
```
