import SwiftUI

// MARK: - Explicit resolution (environment-free)

public extension ThemeAdaptiveStyle {

    /// Resolves the style from its serialized `Defaults` without reading
    /// `EnvironmentValues`.
    ///
    /// This is the resolution path for platforms where environment values
    /// cannot be read outside a view — most notably Android via Skip
    /// (https://skip.dev), where `resolved(in:)` and the `ShapeStyle`
    /// conformances are unavailable. Pass values obtained from `@Environment`
    /// in the calling view:
    ///
    ///     @Environment(\.colorScheme) private var colorScheme
    ///     ...
    ///     let color = theme.colors.primary.resolved(colorScheme: colorScheme)
    ///
    /// Returns `nil` for styles created with a custom `Resolver`, since those
    /// can only resolve against `EnvironmentValues`.
    nonisolated func resolved(
        colorScheme: ColorScheme? = nil,
        sizeClass: UserInterfaceSizeClass? = nil
    ) -> Style? {
        switch defaults {
        case .colorScheme(let light, let dark):
            return colorScheme == .dark ? dark : light
        case .sizeClass(let compact, let regular):
            return sizeClass == .compact ? compact : regular
        case .value(let value):
            return value
        case nil:
            return nil
        }
    }
}
