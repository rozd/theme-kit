# Android rendering support

Draft release notes for the next 0.x minor. **Not tagged yet** — this lands on the integration
branch, and the single merge into `main` plus the release tag happen together at the end of the
Android roadmap, not per phase.

## Summary

Before this release, ThemeKit *compiled* for Android but did not render there. Every generated
`ShapeStyle` extension was gated behind `#if !os(Android)`, so Android code had to resolve tokens by
hand:

```swift
// Before — Android only.
@Environment(\.theme) var theme
@Environment(\.colorScheme) var colorScheme

Text("Hello")
    .foregroundStyle(theme.colors.primary.resolved(colorScheme: colorScheme) ?? .primary)
```

Now the Apple spelling works unchanged on both platforms:

```swift
// After — iOS and Android, same file, no #if.
Text("Hello")
    .foregroundStyle(.primaryColor)
```

## Added

- **Android render path.** The generator emits `View+ThemeStyles.swift`, containing a
  `ThemeStyleResolving` protocol plus overloads of `foregroundStyle`, `background(_:ignoresSafeAreaEdges:)`,
  `background(_:in:)`, `border(_:width:)`, `Shape.fill` and `Shape.stroke(_:lineWidth:)`. Each wraps its
  content in a view that reads `@Environment` itself, because Skip's SwiftUI facade has no
  `ShapeStyle.resolve(in:)` customization point and no environment access outside a view body.
  `ThemeStyleResolving` plays the role `ShapeStyle` plays on Apple: the namespace the token accessors
  hang off, and the constraint that lets `.surface.card` re-bind from a style to a shadowed style
  mid-chain.
- **Theme encoding on Android.** `Color(hex:)` records a color's canonical `#RRGGBB` at construction,
  so `JSONEncoder().encode(theme)` now succeeds there. Android exposes no color components to read
  back, so this recording is the only route. On Apple it additionally makes encoding byte-exact
  rather than round-tripping through a color space.
- **`Color(hex:)` is public API** — along with `Color(hex: String)`, `hexString`, and
  `Color.HexCodingError`. Authoring theme defaults with hex is what makes them encodable on Android,
  so keeping the initializer internal made that impossible from outside the package.
- **`MeshGradient` on Android.** ThemeKit ships its own, sharing a wire format with the Apple
  conformance through an internal `MeshGradientCoding` layer so the two cannot drift. A
  `meshGradients` config previously could not compile on Android at all; it now compiles and renders
  a degraded two-stop diagonal between the mesh's first and last colors.
- **[rozd/theme-kit-demo](https://github.com/rozd/theme-kit-demo)** — a dual-platform Skip app
  exercising every token category from one shared source tree, with iOS/Android screenshots as the
  parity baseline.

## Changed

- `ThemeShapeStyle<Style>`'s constraint relaxes from `Style: ShapeStyle & Sendable & Codable & Equatable`
  to `Style: Sendable & Codable & Equatable`, and its `ShapeStyle` conformance becomes a conditional,
  Apple-only extension. The old constraint was unsatisfiable on Android for two of four categories —
  `Shadow`'s `ShapeStyle` conformance is Apple-gated, and Skip's `Gradient` is not a `ShapeStyle` at
  all. Apple call sites are unaffected.
- `ThemeShadowedStyle<Base>` likewise drops its `Base: ShapeStyle` requirement, with `Equatable`
  unconditional and `ShapeStyle` conditional.
- Generated `ShapeStyle+*.swift` files now emit two mutually exclusive blocks — the Apple
  `extension ShapeStyle where Self == …` form and the Android `extension ThemeStyleResolving where Self == …`
  form. Emitting both would be a redeclaration.
- `Color.hexString` on macOS converts to sRGB before reading components. Previously, calling it on a
  catalog color (`Color.red`) raised an Objective-C exception that **aborted the process** instead of
  throwing. Pre-existing bug, surfaced by the new tests.

## Known limitations

| Area | Behaviour on Android |
|---|---|
| Custom `Resolver` tokens | Resolve to `nil` and render unstyled — their closures need an `EnvironmentValues`, which cannot be constructed there. |
| Inner shadows | Data only. Skip's SwiftUI facade has no inner-shadow equivalent; drop shadows render normally. |
| Mesh gradients | Degraded to a two-stop diagonal. Real mesh rendering needs upstream Compose work. |
| Encoding `Color(red:green:blue:)` colors | Fails. Only hex-constructed colors carry a recorded spelling. Decode → `copyWith` → encode — the loop remote themes use — is fully covered. |
| `.red.card` (a shadow chained onto a *SwiftUI* style) | Unavailable. Letting `Color` conform to `ThemeStyleResolving` would make `.foregroundStyle(.red)` ambiguous with Skip's own modifier. |
| Modifier return types | The overloads return `some View`, so `Text(…).foregroundStyle(…).bold()` degrades to a `View` chain. Put the `Text`-returning modifiers first. |
| `#Preview` | Unavailable — no macros in Skip's SwiftUI facade. |
| Alpha in hex values | The `#RRGGBB` wire format has no alpha channel, so avoid `.opacity(_:)` in token values. |

`.tint(.primaryColor)` is **not** supported on either platform, and no overload is emitted for it:
SwiftUI's `tint(_:)` takes an `S?`, and Swift cannot infer an implicit member's base through an
optional generic. Emitting it on Android alone would produce code that builds on one platform and not
the other — precisely the failure mode this design exists to prevent.

## Notes for Apple-only consumers

ThemeKit's manifest now carries Skip dependencies and the `skipstone` plugin. They **resolve** but
never build for Apple targets, which is the Skip-ecosystem norm. To strip them entirely, set
`SKIP_ZERO=1` when resolving packages; ThemeKit then behaves as a plain SwiftPM package. CI verifies
that path on every change.
