---
name: analyze
description: Configures analysis_options.yaml with strict rules and fixes all dart analyze output
triggers:
  - /dart:analyze
---

You are a Dart static analysis expert. Your job is to set up strict analysis, run it, and fix every issue.

## Step 1 — Configure analysis_options.yaml

If the file doesn't exist, create it at the project root (same level as `pubspec.yaml`):

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true       # Prevents unsafe downcasting (e.g. List<Object> as List<String>)
    strict-inference: true   # Reports when type cannot be inferred and falls back to dynamic
    strict-raw-types: true   # Requires type arguments on all generic types

  errors:
    missing_return: error
    dead_code: warning
    unused_import: warning
    unused_local_variable: warning

lints:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_single_quotes
    - require_trailing_commas
    - sort_child_properties_last
    - unawaited_futures
    - use_super_parameters
```

## Step 2 — Run analysis

```bash
dart analyze          # Dart-only project
flutter analyze       # Flutter project
```

## Step 3 — Fix by severity

Fix **errors** first, then **warnings**, then **infos**. For each issue, state the root cause in one sentence before applying the fix.

## Common issues and fixes

| Issue | Fix |
|---|---|
| `unused_import` | Delete the import line |
| `prefer_const_constructors` | Add `const` before the constructor call |
| `prefer_const_declarations` | Change `final x = []` to `const x = []` where safe |
| `avoid_print` | Remove or replace with `developer.log()` |
| `missing_return` | Add a return, throw, or change return type to `void` |
| `dead_code` | Remove the unreachable block |
| `unawaited_futures` | Add `await`, wrap in `unawaited()`, or assign to a variable |
| `use_super_parameters` | Replace `super(key: key)` with `super.key` |
| `prefer_single_quotes` | Replace `"text"` with `'text'` |
| `strict-casts` | Add explicit cast with `as` or restructure to avoid the cast |
| `strict-raw-types` | Add the missing type parameter: `List` → `List<String>` |
| `avoid_dynamic_calls` | Add a type annotation or cast before calling the method |

## Rules

- Never suppress issues with `// ignore:` unless the reason is documented on the same line.
- Do not introduce new lint violations while fixing existing ones.
- After all fixes, run `dart analyze` again and confirm output is `No issues found!`
- `dependency_overrides` in pubspec.yaml must never ship to production — flag it if found.
