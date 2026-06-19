# Flutter Skills Plugin

Claude Code skills for writing production-quality **Flutter** and **Dart** code.

## Install

Run these commands inside Claude Code:

```
/plugin marketplace add alisheraxmedov/flutter-skills
/plugin install flutter
/plugin install dart
```

## Skills

### Dart — `/dart:<skill>`

| Command | Description |
|---------|-------------|
| `/dart:dart` | Clean, idiomatic Dart 3 — naming, null safety, pattern matching, sealed classes, records |
| `/dart:analyze` | Configure `analysis_options.yaml` with strict rules and fix all `dart analyze` output |
| `/dart:test` | Write unit tests — AAA pattern, mocktail mocks, async pitfalls, edge cases |
| `/dart:optimization` | Optimize Dart code — const, avoid dynamic, switch expressions, StringBuffer |

### Flutter — `/flutter:<skill>`

| Command | Description |
|---------|-------------|
| `/flutter:flutter` | Build features with Clean Architecture — layers, state management, widget rules, security |
| `/flutter:analyze` | Configure Flutter lints, fix Flutter-specific issues, exclude generated files |
| `/flutter:test` | Write unit, widget, integration, and golden tests with full coverage strategy |
| `/flutter:optimization` | Achieve 60/120fps — const widgets, lazy lists, RepaintBoundary, memory leak prevention |

## Usage

### Example — create a Dart model

```
/dart:dart
```

Then describe what you need and Claude will write clean, idiomatic Dart 3 code following all naming, null safety, and typing rules.

### Example — fix all lint warnings

```
/dart:analyze
```

Claude will configure `analysis_options.yaml` with strict rules, run `dart analyze`, and fix every issue by severity.

### Example — write tests for a use case

```
/dart:test
```

Provide the code to test. Claude writes AAA-pattern unit tests with mocktail mocks covering happy path, edge cases, and error paths.

### Example — optimize a slow screen

```
/flutter:optimization
```

Claude audits the screen for missed `const`, unnecessary rebuilds, non-lazy lists, Opacity animations, and memory leaks — then fixes them.

## Plugin Structure

```
flutter-skills/
├── .claude-plugin/
│   └── marketplace.json
├── dart/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── dart/       # /dart:dart
│       ├── analyze/    # /dart:analyze
│       ├── test/       # /dart:test
│       └── optimization/ # /dart:optimization
└── flutter/
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        ├── flutter/    # /flutter:flutter
        ├── analyze/    # /flutter:analyze
        ├── test/       # /flutter:test
        └── optimization/ # /flutter:optimization
```

## License

MIT
