import SwiftUI

nonisolated public struct ThemeAdaptiveStyle<Style: Sendable & Codable & Equatable>: Sendable, Equatable {

    public let defaults: Defaults?

    public let resolver: Resolver

    nonisolated public init(
        resolver: Resolver,
    ) {
        self.defaults = nil
        self.resolver = resolver
    }

    nonisolated public init(
        light: Style,
        dark: Style,
    ) {
        let defaults = Defaults.colorScheme(light: light, dark: dark)
        self.defaults = defaults
        self.resolver = defaults.makeResolver()
    }

    nonisolated public init(
        compact: Style,
        regular: Style,
    ) {
        let defaults = Defaults.sizeClass(compact: compact, regular: regular)
        self.defaults = defaults
        self.resolver = defaults.makeResolver()
    }

    nonisolated public init(
        value: Style,
    ) {
        let defaults = Defaults.value(value)
        self.defaults = defaults
        self.resolver = defaults.makeResolver()
    }
}

// MARK: - Convenience accessors

public extension ThemeAdaptiveStyle {

    var light: Style? {
        guard case .colorScheme(let light, _) = defaults else { return nil }
        return light
    }

    var dark: Style? {
        guard case .colorScheme(_, let dark) = defaults else { return nil }
        return dark
    }

    var compact: Style? {
        guard case .sizeClass(let compact, _) = defaults else { return nil }
        return compact
    }

    var regular: Style? {
        guard case .sizeClass(_, let regular) = defaults else { return nil }
        return regular
    }
}

// MARK: - resolved(in:)

public extension ThemeAdaptiveStyle {
    nonisolated func resolved(in environment: EnvironmentValues) -> Style {
        resolver.resolve(environment)
    }
}

// MARK: - Codable

nonisolated extension ThemeAdaptiveStyle: Codable {

    public init(from decoder: Decoder) throws {
        let defaults = try Defaults(from: decoder)
        self.defaults = defaults
        self.resolver = defaults.makeResolver()
    }

    public func encode(to encoder: Encoder) throws {
        guard let defaults else {
            throw EncodingError.invalidValue(self, .init(
                codingPath: encoder.codingPath,
                debugDescription: "Cannot encode ThemeAdaptiveStyle with a custom resolver — defaults are required for serialization."
            ))
        }
        try defaults.encode(to: encoder)
    }
}
