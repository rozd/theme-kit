# ThemeKit

A Swift package that brings native-feeling theming to SwiftUI. Theme tokens resolve through SwiftUI's environment system — just like built-in styles — so views use `.foregroundStyle(.themeSurface)` with zero boilerplate.

ThemeKit has two parts:

1. **Core types** — the theming backbone (`ThemeAdaptiveStyle`, `ThemeShapeStyle`, `Theme`, etc.)
2. **Code generation** — a command plugin that reads your config and generates style token files

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
  "colors": ["surface", "onSurface", "primary", "onPrimary"],
  "gradients": ["primary"],
  "shadows": ["card"]
}
```

### 3. Generate theme files

In Xcode: right-click your project → ThemeKit Commands → Generate Theme Files.

This reads your config and generates the style token structs, default values, and `ShapeStyle` extensions.

### 4. Use in views

```swift
Text("Hello")
    .foregroundStyle(.themePrimary)

RoundedRectangle(cornerRadius: 12)
    .fill(.themeSurface)
```

Inject a theme at the root of your app:

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
