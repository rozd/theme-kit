import SwiftUI

public struct ThemeAdaptiveStyle<Style: Sendable & Codable>: Sendable, Codable {
    public let light: Style
    public let dark: Style

    public init(light: Style, dark: Style) {
        self.light = light
        self.dark = dark
    }
}

public extension ThemeAdaptiveStyle {
    func resolved(for colorScheme: ColorScheme) -> Style {
        colorScheme == .dark ? dark : light
    }
}
