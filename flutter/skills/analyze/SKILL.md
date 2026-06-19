---
name: analyze
description: Configures flutter analyze with strict lints and fixes all Flutter-specific issues
triggers:
  - /flutter:analyze
---

You are a Flutter static analysis expert.

## Step 1 — Verify analysis_options.yaml

Check the project root for `analysis_options.yaml`. Create or update it:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

  exclude:
    - "**/*.g.dart"       # generated files
    - "**/*.freezed.dart"

  errors:
    missing_return: error
    dead_code: warning
    unused_import: warning
    invalid_annotation_target: ignore  # suppress for freezed/json_serializable

lints:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_print
    - avoid_unnecessary_containers
    - avoid_web_libraries_in_flutter
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - prefer_single_quotes
    - require_trailing_commas
    - sized_box_for_whitespace
    - sort_child_properties_last
    - unawaited_futures
    - use_super_parameters
```

## Step 2 — Run analysis

```bash
flutter analyze
```

## Step 3 — Fix by severity: errors → warnings → infos

For each issue, state the root cause before applying the fix.

## Flutter-specific issues and fixes

| Issue | Fix |
|---|---|
| `avoid_unnecessary_containers` | Remove `Container` wrapper; use `Padding`, `SizedBox`, or `ColoredBox` instead |
| `prefer_const_constructors` | Add `const` before widget constructors |
| `prefer_const_literals_to_create_immutables` | Change `children: []` to `children: const []` |
| `sized_box_for_whitespace` | Replace `Container(width: 16)` with `SizedBox(width: 16)` |
| `sort_child_properties_last` | Move `child:` / `children:` to the last named argument |
| `use_super_parameters` | Replace `Widget({Key? key}) : super(key: key)` with `Widget({super.key})` |
| `avoid_print` | Replace with `debugPrint()` for Flutter debug output |
| `unawaited_futures` | Add `await`, wrap in `unawaited()`, or store the Future |
| `prefer_final_fields` | Change `var _field` to `final _field` where never reassigned |

## Generated file exclusions

Never fix lint issues inside `.g.dart` or `.freezed.dart` files — they are auto-generated. Add them to `exclude:` in `analysis_options.yaml` instead.

## Rules

- Do not use `// ignore:` without a documented reason on the same line.
- Do not introduce new issues while fixing existing ones.
- After all fixes: `flutter analyze` must print `No issues found!`
