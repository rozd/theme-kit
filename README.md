# ThemeKit
[![Release](https://img.shields.io/github/v/release/rozd/theme-kit)](https://github.com/rozd/theme-kit/releases)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![License](https://img.shields.io/github/license/rozd/theme-kit)](LICENSE)
[![codecov](https://codecov.io/gh/rozd/theme-kit/branch/main/graph/badge.svg)](https://codecov.io/gh/rozd/theme-kit)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_|_macOS_|_watchOS_|_tvOS_|_visionOS-blue.svg)](https://developer.apple.com/xcode/)

**Native-feeling theming for SwiftUI, powered by the environment.**

ThemeKit gives your app a design token system that works exactly like SwiftUI's built-in styles. Every token is adaptive — light and dark variants resolve automatically based on the system color scheme. You declare your tokens in a simple JSON file (just names, no colors), run one command, and you're ready to use `.foregroundStyle(.surface)` anywhere.

---

## ✨ Features

- 🍎 **SwiftUI Native** — tokens resolve through `ShapeStyle.resolve(in:)`, the same mechanism as `.primary` and `.tint`. No `@Environment` wrappers needed in views.
- 🌗 **Adaptive by Default** — every token carries light and dark variants. The correct one resolves automatically at render time — no manual `colorScheme` checks.
- 📦 **Minimal Core** — the library is just `ThemeAdaptiveStyle` and a few `Codable` extensions. Everything else is generated.
- 🔧 **Easy Setup** — declare tokens in JSON, run the plugin, fill in your colors. Four steps total.
- 🔓 **Full Control** — generated files live in your project, fully readable and yours to extend.

## 🍿 Demo

https://github.com/user-attachments/assets/f4563c6a-57e2-4356-bd87-72276ec9bf96

## 🚀 Integration

### 1. Add ThemeKit

In Xcode: **File → Add Package Dependencies**, then enter:

```
https://github.com/rozd/theme-kit
```

### 2. Create `theme.json`

Add a `theme.json` to your project root. This file is just a list of token **names** — no colors, no gradients, no design values. You're declaring the shape of your design language; actual values come in step 4.

Only include the categories you need — the generated `Theme` struct will match:

```json
{
  "$schema": "https://raw.githubusercontent.com/rozd/theme-kit/main/theme.schema.json",
  "styles": {
    "colors": [
      "surface",
      "onSurface",
      { "name": "primary", "style": "primaryColor" }
    ],
    "gradients": [
        { "name": "primary", "style": "primaryGradient" }
    ]
  }
}
```

> Use the object form `{ "name": ..., "style": ... }` when a token name conflicts with a SwiftUI built-in (e.g. `primary` → `primaryColor`).

### 3. Generate theme files

Right-click your project in the Xcode navigator → **Generate Theme Files**.

<details>
<summary>What gets generated?</summary>

- Token structs (`ThemeColors`, `ThemeGradients`, etc.)
- A root `Theme` container with only the categories you declared
- `ShapeStyle` extensions so tokens work as `.surface`, `.primaryColor`, etc.
- `ThemeShadowedStyle` for chaining shadow tokens onto any style (only when shadows are configured)
- `Environment+Theme.swift` for environment plumbing
- `copyWith` helpers for immutable updates
- A `Theme+Defaults.swift` scaffold for you to fill in

</details>

### 4. Fill in defaults

Open the generated `Theme+Defaults.swift` and replace the placeholders with your design values:

```swift
import SwiftUI
import ThemeKit

nonisolated extension Theme {
    static let `default` = Theme(
        colors: .default,
        gradients: .default
    )
}

// MARK: - ThemeColors

nonisolated extension ThemeColors {
    static let `default` = ThemeColors(
        surface:   .init(light: Color(hex: 0xF7F5EC), dark: Color(hex: 0x1A1A1A)),
        onSurface: .init(light: Color(hex: 0x2D2D2D), dark: Color(hex: 0xF0F0F0)),
        primary:   .init(light: Color(hex: 0x1B8188), dark: Color(hex: 0x3DBCC4))
    )
}

// MARK: - ThemeGradients

nonisolated extension ThemeGradients {
    static let `default` = ThemeGradients(
        primary: .init(
            light: .init(colors: [Color(hex: 0x1B8188), Color(hex: 0x0E4F54)]),
            dark:  .init(colors: [Color(hex: 0x3DBCC4), Color(hex: 0x1B8188)])
        )
    )
}
```

That's it — your theme is ready to use.

## 🎨 Usage

### Use tokens in views

Theme tokens work just like built-in SwiftUI styles:

```swift
Text("Hello, world")
    .foregroundStyle(.onSurface)

RoundedRectangle(cornerRadius: 12)
    .fill(.surface)

Circle()
    .fill(.primaryColor)
```

### Compose shadows

When your config includes shadow tokens, you can chain them onto any style:

```swift
RoundedRectangle(cornerRadius: 12)
    .fill(.surface.card)              // theme color + theme shadow

RoundedRectangle(cornerRadius: 12)
    .fill(.red.card)                  // SwiftUI color + theme shadow

RoundedRectangle(cornerRadius: 12)
    .fill(.surface.card.innerGlow)    // multiple shadows chained
```

### Switch themes at runtime

The generated `Environment+Theme.swift` provides implicit theme injection — every token resolves against `Theme.default` automatically, so things just work with no setup. When you need to switch themes at runtime, override the environment value:

```swift
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

Define alternative themes using `copyWith` for immutable updates:

```swift
extension Theme {
    static let ocean = Theme.default.copyWith(
        colors: ThemeColors.default.copyWith(
            primary: .init(light: .blue, dark: .cyan)
        )
    )
}
```

Then swap themes by updating the state:

```swift
Button("Ocean Theme") {
    theme = .ocean
}
```

### Load themes from JSON

Every type conforms to `Codable`, so themes can come from a remote API, a bundled file, or user preferences:

```swift
let theme = try JSONDecoder().decode(Theme.self, from: data)
```

## ⚙️ How It Works

The generated `ThemeShapeStyle<Style>` bridges your tokens into SwiftUI's style resolution system. It holds a key path into `Theme` and resolves the correct light/dark variant at render time:

```swift
struct ThemeShapeStyle<Style: ShapeStyle>: ShapeStyle {
    let keyPath: KeyPath<Theme, ThemeAdaptiveStyle<Style>>

    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        environment.theme[keyPath: keyPath].resolved(for: environment.colorScheme)
    }
}
```

This is the same `resolve(in:)` mechanism that powers SwiftUI's built-in `.primary`, `.tint`, and other environment-dependent styles. Your tokens participate in the system as first-class citizens.

For a deep dive, see the [full blog post](https://medium.com/@rozd/building-a-native-feeling-theme-system-in-swiftui-ba5275779df6) or the [implementation details](IMPLEMENTATION_DETAILS.md).
