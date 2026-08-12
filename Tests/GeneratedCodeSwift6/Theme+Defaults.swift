import SwiftUI
import ThemeKit

// Values are authored with `Color(hex:)` rather than `Color(red:green:blue:)` for two reasons:
// it is what the README recommends (only hex-constructed colours can encode on Android), and
// because this target imports ThemeKit *without* `@testable`, compiling it is what proves that
// initializer is genuinely public — across every Swift language mode these fixtures cover.

nonisolated extension Theme {
    public static let `default` = Theme(
        colors: .`default`,
        gradients: .`default`,
        meshGradients: .`default`,
        shadows: .`default`
    )
}

// MARK: - ThemeColors

nonisolated extension ThemeColors {
    public static let `default` = ThemeColors(
        surface: .init(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x000000)),
        primary: .init(light: Color(hex: 0x0080FF), dark: Color(hex: 0x00CCFF))
    )
}

// MARK: - ThemeGradients

nonisolated extension ThemeGradients {
    public static let `default` = ThemeGradients(
        primary: .init(
            light: .init(colors: [Color(hex: 0x0080FF), Color(hex: 0x8000FF)]),
            dark:  .init(colors: [Color(hex: 0x00CCFF), Color(hex: 0x4D0080)])
        )
    )
}

// MARK: - ThemeMeshGradients

nonisolated extension ThemeMeshGradients {
    public static let `default` = ThemeMeshGradients(
        aurora: .init(
            light: .init(width: 2, height: 2, colors: [
                Color(hex: 0x0080FF), Color(hex: 0x8000FF),
                Color(hex: 0x00CCCC), Color(hex: 0x00CC4D),
            ]),
            dark: .init(width: 2, height: 2, colors: [
                Color(hex: 0x4D0080), Color(hex: 0x8000FF),
                Color(hex: 0x008080), Color(hex: 0x00B380),
            ])
        )
    )
}

// MARK: - ThemeShadows

nonisolated extension ThemeShadows {
    public static let `default` = ThemeShadows(
        card:  .init(light: .drop(radius: 4), dark: .drop(radius: 4)),
        inner: .init(light: .inner(radius: 2), dark: .inner(radius: 2))
    )
}
