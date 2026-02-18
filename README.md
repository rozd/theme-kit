# ThemeKit

A Swift package that brings native-feeling theming to SwiftUI. Theme tokens resolve through SwiftUI's environment system — just like built-in styles — so views use `.foregroundStyle(.surface)` with zero boilerplate.

ThemeKit has two parts:

1. **Core types** — the theming backbone (`ThemeAdaptiveStyle`, `ThemeShapeStyle`)
2. **Code generation** — a command plugin that reads your config and generates all theme files

Based on the approach described in [Building a Native-Feeling Theme System in SwiftUI](https://dev.to/rozd/building-a-native-feeling-theme-system-in-swiftui-h1k).

## Quick Start

### 1. Add the package

In Xcode: File → Add Package Dependencies → enter the repository URL:

```
https://github.com/rozd/theme-kit
```

### 2. Define your tokens

Create a `theme.json` in your project root:

```json
{
  "$schema": "https://raw.githubusercontent.com/rozd/theme-kit/main/theme.schema.json",
  "colors": ["surface", "onSurface", { "name": "primary", "style": "primaryColor" }],
  "gradients": ["primary"],
  "shadows": ["card"]
}
```

Token entries are either a plain string or an object with `name` and `style` — use the object form when the token name conflicts with SwiftUI built-ins (e.g. `primary`).

### 3. Generate theme files

In Xcode: right-click your project → ThemeKit Commands → Generate Theme Files.

This generates:
- `ThemeColors.swift`, `ThemeGradients.swift`, `ThemeShadows.swift` — token structs
- `ShapeStyle+ThemeColors.swift`, etc. — convenience extensions
- `Theme.swift` — root container with only the categories you configured
- `Environment+Theme.swift` — environment integration
- `copyWith` extensions for all structs

### 4. Provide default values

Create a `Theme+Default.swift` in your project with your app's actual style values:

```swift
extension Theme {
    static let `default` = Theme(
        colors: ThemeColors(
            surface: .init(light: Color(hex: 0xF7F5EC), dark: Color(hex: 0x1A1A1A)),
            primary: .init(light: Color(hex: 0x1B8188), dark: Color(hex: 0x1B8188))
        ),
        gradients: ...
    )
}
```

### 5. Use in views

```swift
@main
struct MyApp: App {
    @State private var theme: Theme = .default

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, theme)
        }
    }
}
```

```swift
Text("Hello")
    .foregroundStyle(.primaryColor)

RoundedRectangle(cornerRadius: 12)
    .fill(.surface)
```

## How It Works

Theme tokens are resolved lazily through SwiftUI's `ShapeStyle` protocol. Under the hood, `ThemeShapeStyle<Style>` holds a key path into the `Theme` and resolves the correct light/dark variant at render time using the environment's color scheme:

```swift
struct ThemeShapeStyle<Style: ShapeStyle & Sendable & Codable>: ShapeStyle {
    let keyPath: KeyPath<Theme, ThemeAdaptiveStyle<Style>>

    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        environment.theme[keyPath: keyPath].resolved(for: environment.colorScheme)
    }
}
```

This means theme-aware styles work exactly like SwiftUI's built-in `.primary` or `.tint` — no `@Environment` property wrappers needed in your views.

## Runtime Theme Switching

Themes support immutable updates via `copyWith`:

```swift
theme = theme.copyWith(
    colors: theme.colors.copyWith(
        primary: .init(light: .purple, dark: .indigo)
    )
)
```

All theme types conform to `Codable`, so themes can be loaded from JSON, a remote database, or any other source.

## License

MIT
