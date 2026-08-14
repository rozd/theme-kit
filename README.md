# ThemeKit
[![Platforms](https://img.shields.io/badge/Platforms-iOS_|_macOS_|_watchOS_|_tvOS_|_visionOS-blue.svg)](https://developer.apple.com/xcode/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Release](https://img.shields.io/github/v/release/rozd/theme-kit)](https://github.com/rozd/theme-kit/releases)
[![codecov](https://codecov.io/gh/rozd/theme-kit/branch/main/graph/badge.svg)](https://codecov.io/gh/rozd/theme-kit)
[![License](https://img.shields.io/github/license/rozd/theme-kit)](LICENSE)

**Native-feeling theming for SwiftUI, powered by the environment.**

ThemeKit gives your app a design token system that works exactly like SwiftUI's built-in styles. Every token is adaptive — variants resolve automatically based on the environment (color scheme, size class, or any custom axis). You declare your tokens in a simple JSON file (just names, no colors), run one command, and you're ready to use `.foregroundStyle(.surface)` anywhere.

---

## ✨ Features

- 🍎 **SwiftUI Native** — tokens resolve through `ShapeStyle.resolve(in:)`, the same mechanism as `.primary` and `.tint`. No `@Environment` wrappers needed in views.
- 🎭 **Adaptive by Default** — tokens adapt by color scheme (light/dark), size class (compact/regular), or any custom axis via resolvers. The correct variant resolves automatically at render time.
- 🎈 **Minimal Core** — the library is just `ThemeAdaptiveStyle` and a few `Codable` extensions. Everything else is generated.
- 🪄 **Easy Setup** — declare tokens in JSON, run the plugin once, fill in your colors, done. **Zero imports** required in your app code.
- 📖 **Transparent Logic** — the thin core and generated files are easy to read. Each file has a clear, specific role that is obvious at a glance.
- 🎛️ **Full Control** — generated files live in your project, fully readable and yours to extend.
- 🤖 **Skip / Android Ready** — the same call sites render on Android with [Skip](https://skip.dev) (native/Fuse mode). `.foregroundStyle(.primaryColor)` is spelled identically on both platforms — no `#if os(Android)`, no manual resolution.

## 🍿 Demo

https://github.com/user-attachments/assets/f4563c6a-57e2-4356-bd87-72276ec9bf96

[**rozd/theme-kit-demo**](https://github.com/rozd/theme-kit-demo) is a dual-platform [Skip](https://skip.dev) app covering every token category from one shared source tree, with side-by-side iOS and Android screenshots.

## 🛠️ Configurator

You don't need to write JSON by hand, use the [**ThemeKit Configurator**](https://rozd.github.io/theme-kit/) — a visual editor that lets you toggle categories, add tokens, configure style overrides, and copy the finished `theme.json` straight into your project.

## 🚀 Integration

### 1. Add ThemeKit

In Xcode: **File → Add Package Dependencies**, then enter:

```
https://github.com/rozd/theme-kit
```

### 2. Create `theme.json`

Add a `theme.json` to your project root (or use the [Configurator](https://rozd.github.io/theme-kit/) to build it visually). This file is just a list of token **names** — no colors, no gradients, no design values. You're declaring the shape of your design language; actual values come in step 4.

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
  },
  "config": {
    "outputPath": ".",
    "shouldGeneratePreview": true
  }
}
```

> Use the object form `{ "name": ..., "style": ... }` when a token name conflicts with a SwiftUI built-in (e.g. `primary` → `primaryColor`).
>
> Set `"shouldGeneratePreview": true` in the config section to generate a `Theme+Preview.swift` file with a SwiftUI view that displays all your tokens as a visual palette.

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
- A `Theme+Preview.swift` file with a visual preview of all tokens (only when `shouldGeneratePreview` is enabled)

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

<details>
<summary>Advanced</summary>

Beyond light/dark, tokens can adapt by **size class** or hold a **constant value**:

```swift
// Adapt by horizontal size class (compact vs regular)
surface: .init(compact: Color(hex: 0xFFFFFF), regular: Color(hex: 0xF7F5EC))

// Same value in all environments
surface: .init(value: Color(hex: 0xF7F5EC))
```

For full control, use a **custom resolver** — a closure that reads `EnvironmentValues` directly:

```swift
surface: .init(resolver: .init(id: "high-contrast") { env in
    env.colorSchemeContrast == .increased
        ? Color(hex: 0xFFFFFF)
        : Color(hex: 0xF7F5EC)
})
```

The `id` parameter drives `Equatable` — two resolvers with the same `id` are considered equal, which lets SwiftUI skip unnecessary redraws. Omit it to get a unique auto-generated id.

> **Note:** Tokens created with a custom resolver cannot be encoded to JSON, since they have no serializable defaults.

</details>

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
    .fill(.red.card)                  // SwiftUI color + theme shadow (Apple-only)

RoundedRectangle(cornerRadius: 12)
    .fill(.surface.card.innerGlow)    // multiple shadows chained
```

> Chaining onto a **theme** style (`.surface.card`) works everywhere. Chaining onto a **SwiftUI**
> style (`.red.card`) is Apple-only — see [Skip / Android](#-skip--android).

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

## 🤖 Skip / Android

ThemeKit works with [Skip](https://skip.dev) in **native (Skip Fuse) mode**, and Android generation is **opt-in** — by default, generated output is pure Apple SwiftUI. Enable it by adding `"androidSupport": true` to your `theme.json` config:

```json
{
  "styles": { /* tokens */ },
  "config": {
    "outputPath": ".",
    "androidSupport": true
  }
}
```

With it enabled, the call sites are the same ones you write on Apple:

```swift
// This file compiles and renders on iOS and Android. No #if, no manual resolution.
Text("Hello")
    .foregroundStyle(.primaryColor)

RoundedRectangle(cornerRadius: 12)
    .fill(.surface.card)
```

Add ThemeKit to your Skip app the way you'd add any Skip module — the package already ships the `skipstone` plugin and its `Skip/skip.yml` — then generate your theme files as usual. Nothing about the integration steps changes.

<details>
<summary><b>How the same spelling works on both platforms</b></summary>

On Apple, tokens resolve through `ShapeStyle.resolve(in:)`. Skip's SwiftUI facade has no such customization point, and environment values can't be read outside a view body there — so on Android the generator emits a small parallel surface instead: overloads of the style-taking modifiers (`foregroundStyle`, `background`, `border`, `fill`, `stroke`) that wrap your content in a view which reads `@Environment` itself.

Those overloads are constrained to a generated `AndroidShapeStyleAdapter` protocol, which plays exactly the role `ShapeStyle` plays on Apple — the namespace your token accessors hang off, and the constraint that lets `.surface.card` re-bind from a style to a shadowed style mid-chain. Only ThemeKit's own types conform to it, so the overloads can never be ambiguous with Skip's.

</details>

### Support matrix

| Feature | Apple | Android |
|---|:--:|:--:|
| Token data, `Codable` decode, `copyWith` | ✅ | ✅ |
| `.foregroundStyle(.primaryColor)` and friends — identical spelling | ✅ | ✅ |
| Colors, gradients | ✅ | ✅ |
| Shadows | ✅ | drop only — `.inner` is data |
| Mesh gradients | ✅ | degraded — two-stop diagonal¹ |
| Encode theme → JSON | ✅ | `Color(hex:)` colors only |
| `#Preview` | ✅ | ❌ |
| Custom `Resolver` tokens | ✅ | ❌ — resolve to `nil` |
| `.red.card` (shadow on a *SwiftUI* style) | ✅ | ❌ |
| `.tint(.primaryColor)` | ❌ | ❌ |

¹ A real mesh renderer (an AGSL shader on API 33+, this same two-stop fallback below) exists for
skip-ui/skip-fuse-ui, built and verified on forks ahead of upstream PRs. ThemeKit keeps shipping
the degraded shim until that lands in a Skip release, at which point the shim is deleted and the
minimum skip-fuse-ui version bumps.

### Things worth knowing

**Author your defaults with `Color(hex:)`.** A color records its hex spelling at construction, and that recording is the only way `JSONEncoder().encode(theme)` can work on Android — the platform exposes no color components to read back. Colors built with `Color(red:green:blue:)` decode fine but cannot re-encode there.

```swift
// Encodes everywhere.
surface: .init(light: Color(hex: 0xF7F5F2), dark: Color(hex: 0x1A1A1F))
```

The hex format is `#RRGGBB` with **no alpha channel**, so avoid `.opacity(_:)` in token values — the derived color isn't the one that was recorded.

**Custom `Resolver` styles resolve to `nil` on Android** and render unstyled; their closures need an `EnvironmentValues`, which cannot be constructed there. Tokens built from `.colorScheme(light:dark:)`, `.sizeClass(compact:regular:)` or `.value(_:)` are unaffected.

**`.tint(.primaryColor)` isn't supported on either platform.** SwiftUI's `tint(_:)` takes an `S?`, and Swift can't infer an implicit member's base through an optional generic. Resolve explicitly instead:

```swift
.tint(theme.colors.primary.resolved(colorScheme: colorScheme) ?? .accentColor)
```

**Modifier return types.** The Android overloads return `some View`, so a chain that relies on staying a `Text` (`Text(…).foregroundStyle(…).bold()`) degrades to a `View` chain there. Reorder so the `Text`-returning modifiers come first.

**Apple-only projects:** if you don't use Skip, set `SKIP_ZERO=1` when resolving packages to strip every Skip dependency and plugin — ThemeKit then behaves as a plain SwiftPM package. Without it the Skip packages *resolve* but never build for Apple targets, which is the Skip-ecosystem norm.

See [`docs/android-rendering.md`](docs/android-rendering.md) for the full release notes, and [rozd/theme-kit-demo](https://github.com/rozd/theme-kit-demo) for a dual-platform app with side-by-side screenshots.

## ⚙️ How It Works

The generated `ThemeShapeStyle<Style>` bridges your tokens into SwiftUI's style resolution system. It holds a key path into `Theme` and resolves the correct variant at render time:

```swift
struct ThemeShapeStyle<Style: Sendable & Codable & Equatable> {
    let keyPath: KeyPath<Theme, ThemeAdaptiveStyle<Style>>
}

// The ShapeStyle conformance is conditional, and Apple-only — Skip's SwiftUI facade
// has no resolve(in:) customization point. See Skip / Android above for what Android
// gets instead.
#if !os(Android)
extension ThemeShapeStyle: ShapeStyle where Style: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        environment.theme[keyPath: keyPath].resolved(in: environment)
    }
}
#endif
```

This is the same `resolve(in:)` mechanism that powers SwiftUI's built-in `.primary`, `.tint`, and other environment-dependent styles. Your tokens participate in the system as first-class citizens.

For a deep dive, see the [full blog post](https://medium.com/@rozd/building-a-native-feeling-theme-system-in-swiftui-ba5275779df6) or the [implementation details](IMPLEMENTATION_DETAILS.md).
