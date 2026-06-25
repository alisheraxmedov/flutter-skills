# Deprecated → current APIs (stale forms AI commonly emits)

Most of these have a `dart fix` quick-fix — run `dart fix --apply` first, then verify with `flutter analyze`. The table is the canonical stale→current mapping for hand edits.

## Colors & opacity
| Stale (AI mistake) | Current |
|---|---|
| `color.withOpacity(0.5)` | `color.withValues(alpha: 0.5)` |
| `Color.fromRGBO(...)` for alpha tweaks | `color.withValues(alpha: x)` |
| `color.value` (32-bit int) | component accessors `.a` `.r` `.g` `.b` (double 0–1) |
| `color.red` / `.green` / `.blue` (0–255 int) | `(color.r * 255).round()` etc., or work in `.r/.g/.b` doubles |
| `color.alpha` (0–255 int) | `color.a` (double 0–1) |

`withOpacity` loses precision (8-bit) and is deprecated; `withValues` keeps full-precision channels.

## Material → Widget state
| Stale (AI mistake) | Current |
|---|---|
| `MaterialStateProperty.all(x)` | `WidgetStateProperty.all(x)` |
| `MaterialStateProperty.resolveWith(...)` | `WidgetStateProperty.resolveWith(...)` |
| `MaterialState.pressed` / `.hovered` / ... | `WidgetState.pressed` / `.hovered` / ... |
| `MaterialStatesController` | `WidgetStatesController` |
| `MaterialStateColor` / `MaterialStateMouseCursor` | `WidgetStateColor` / `WidgetStateMouseCursor` |

The classes moved out of Material so they work in non-Material widgets; the `Material*` names are deprecated aliases.

## Text scaling
| Stale (AI mistake) | Current |
|---|---|
| `textScaleFactor: 1.5` (double) | `textScaler: TextScaler.linear(1.5)` |
| `MediaQuery.textScaleFactorOf(context)` | `MediaQuery.textScalerOf(context)` |
| `MediaQuery.of(context).textScaleFactor` | `MediaQuery.textScalerOf(context)` |

`TextScaler` supports non-linear scaling; the flat `double` factor is removed.

## Theme surfaces
| Stale (AI mistake) | Current |
|---|---|
| `ColorScheme.background` | `ColorScheme.surface` |
| `ColorScheme.onBackground` | `ColorScheme.onSurface` |
| `ThemeData(backgroundColor: ...)` | use `ColorScheme.surface` / `Scaffold(backgroundColor:)` |
| `ColorScheme.surfaceVariant` | `ColorScheme.surfaceContainerHighest` |

`background`/`onBackground` were removed from `ColorScheme`; map them onto the surface roles.

## Misc commonly-stale forms
| Stale (AI mistake) | Current |
|---|---|
| `flutter packages get` | `flutter pub get` |
| `dart migrate` | `dart fix --apply` (and version pin via fvm) |
| `RaisedButton` / `FlatButton` / `OutlineButton` | `ElevatedButton` / `TextButton` / `OutlinedButton` |
| `Scaffold.of(context).showSnackBar` | `ScaffoldMessenger.of(context).showSnackBar` |
| `WillPopScope` | `PopScope` |
| `accentColor` (ThemeData) | `ColorScheme.secondary` |
| `Slider(year2023: ...)` left implicit | new slider visuals are default; pass `year2023: false` only if you must opt out |

After any sweep: `dart fix --apply` → `flutter analyze` → run tests. Anything `analyze` still flags has no auto-fix and needs a manual edit guided by the breaking-changes doc.
