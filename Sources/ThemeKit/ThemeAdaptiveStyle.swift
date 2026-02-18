import SwiftUI

nonisolated public struct ThemeAdaptiveStyle<Style: Sendable & Codable & Equatable>: Sendable, Codable, Equatable {
    public let light: Style
    public let dark: Style

    nonisolated public init(light: Style, dark: Style) {
        self.light = light
        self.dark = dark
    }
}

public extension ThemeAdaptiveStyle {
    nonisolated func resolved(for colorScheme: ColorScheme) -> Style {
        colorScheme == .dark ? dark : light
    }
}
