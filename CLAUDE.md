    # CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ThemeKit is a Swift package for SwiftUI that provides:
1. **Core theming types** — backbone types that implement environment-aware theming (ThemeAdaptiveStyle, ThemeShapeStyle, Theme, etc.)
2. **A code generation command plugin** — reads a config file with token names and generates concrete style token files (ThemeColors, ThemeGradients, ThemeShadows, etc.)

The theming approach is described in detail at: https://dev.to/rozd/building-a-native-feeling-theme-system-in-swiftui-h1k

## Build & Test Commands

```bash
swift build                          # Build the package
swift test                           # Run all tests
swift test --filter <TestCase>       # Run a single test class
swift test --filter <TestCase>/<method>  # Run a single test method
```

## Architecture

### Core Types (library target)

- **`ThemeAdaptiveStyle<Style>`** — Generic wrapper holding `light`/`dark` variants of any style, resolved via `ColorScheme`.
- **`ThemeShapeStyle<Style: ShapeStyle>`** — The critical bridge: a `ShapeStyle` that takes a `KeyPath<Theme, ThemeAdaptiveStyle<Style>>` and resolves against both the theme and color scheme from `EnvironmentValues`. This is what makes `.themePrimary` work like a native SwiftUI style.
- **`Theme`** — Root container aggregating all style collections (colors, gradients, shadows, etc.). Injected into the view hierarchy via `environment(\.theme, theme)`.
- **`EnvironmentValues.theme`** — Uses the `@Entry` macro to expose the theme throughout the SwiftUI environment.
- **Codable conformances** — `Color`, `Gradient`, and other SwiftUI types get `Codable` conformance (via `@retroactive`) to enable remote/serialized theming.

### Code Generation (command plugin target)

The command plugin reads a user-authored config file listing semantic token names (e.g., `colors: [surface, onSurface]`, `gradients: [primary]`, `shadows: [card]`) and generates:
- Struct definitions (e.g., `ThemeColors` with the listed properties)
- `static let default` values
- `ShapeStyle` convenience extensions (e.g., `static var themeSurface: Self`)
- `copyWith` methods for immutable updates

### End-User Flow

1. Add ThemeKit package to Xcode project
2. Edit config file (e.g., `theme.json`) declaring token names
3. Run the command plugin ("ThemeKit Commands > Generate Theme Files")
4. Use generated tokens: `.foregroundStyle(.themeSurface)`

## Key Patterns

- All types are `nonisolated`, `Sendable`, and `Codable`
- Style resolution always goes through SwiftUI's `resolve(in: EnvironmentValues)` — never requires `@Environment` in views
- Themes are fully specified (no optional/fallback values) — every token must have both light and dark variants
- The `copyWith` pattern enables immutable theme updates at runtime
- Generated `ShapeStyle` extensions constrain `Self` to `ThemeShapeStyle<ConcreteType>` for type safety and autocomplete
