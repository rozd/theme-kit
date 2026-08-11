import SwiftUI

// On Android (Skip Fuse), ShapeStyle has no `resolve(in:)` customization point —
// styles render through Compose bridging instead. Resolve tokens explicitly there
// via `resolved(colorScheme:sizeClass:)`.
#if !os(Android)
extension ThemeAdaptiveStyle: ShapeStyle where Style: ShapeStyle {
    nonisolated public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        resolver.resolve(environment)
    }
}
#endif
