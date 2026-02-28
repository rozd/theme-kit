import SwiftUI
import ThemeKit

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
        surface: .init(light: Color(red: 1, green: 1, blue: 1), dark: Color(red: 0, green: 0, blue: 0)),
        primary: .init(light: Color(red: 0, green: 0.5, blue: 1), dark: Color(red: 0, green: 0.8, blue: 1))
    )
}

// MARK: - ThemeGradients

nonisolated extension ThemeGradients {
    public static let `default` = ThemeGradients(
        primary: .init(
            light: .init(colors: [Color(red: 0, green: 0.5, blue: 1), Color(red: 0.5, green: 0, blue: 1)]),
            dark:  .init(colors: [Color(red: 0, green: 0.8, blue: 1), Color(red: 0.3, green: 0, blue: 0.5)])
        )
    )
}

// MARK: - ThemeMeshGradients

nonisolated extension ThemeMeshGradients {
    public static let `default` = ThemeMeshGradients(
        aurora: .init(
            light: .init(width: 2, height: 2, colors: [
                Color(red: 0, green: 0.5, blue: 1), Color(red: 0.5, green: 0, blue: 1),
                Color(red: 0, green: 0.8, blue: 0.8), Color(red: 0, green: 0.8, blue: 0.3),
            ]),
            dark: .init(width: 2, height: 2, colors: [
                Color(red: 0.3, green: 0, blue: 0.5), Color(red: 0.5, green: 0, blue: 1),
                Color(red: 0, green: 0.5, blue: 0.5), Color(red: 0, green: 0.7, blue: 0.5),
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
