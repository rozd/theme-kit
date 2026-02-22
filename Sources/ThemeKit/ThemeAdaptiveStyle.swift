import SwiftUI

nonisolated public struct ThemeAdaptiveStyle<Style: Sendable & Codable & Equatable>: Sendable, Equatable {

    public let light: Style?
    public let dark: Style?

    public let resolver: Resolver

    nonisolated public init(
        resolver: Resolver,
    ) {
        self.light = nil
        self.dark = nil
        self.resolver = resolver
    }

    nonisolated public init(
        light: Style,
        dark: Style,
    ) {
        self.light = light
        self.dark = dark
        self.resolver = Resolver(id: Self.resolverID(light: light, dark: dark)) { env in
            env.colorScheme == .dark ? dark : light
        }
    }

    private static func resolverID(light: Style, dark: Style) -> String {
        guard let data = try? JSONEncoder().encode([light, dark]) else {
            return UUID().uuidString
        }
        var hasher = Hasher()
        hasher.combine(data)
        return String(hasher.finalize())
    }
}

public extension ThemeAdaptiveStyle {
    nonisolated func resolved(in environment: EnvironmentValues) -> Style {
        resolver.resolve(environment)
    }
}

// MARK: - Resolver

nonisolated public extension ThemeAdaptiveStyle {

    struct Resolver: Sendable {
        public let id: String
        public let resolve: @Sendable (EnvironmentValues) -> Style

        public init(id: String, resolve: @escaping @Sendable (EnvironmentValues) -> Style) {
            self.id = id
            self.resolve = resolve
        }

        public init(resolve: @escaping @Sendable (EnvironmentValues) -> Style) {
            self.init(id: UUID().uuidString, resolve: resolve)
        }
    }
}

nonisolated extension ThemeAdaptiveStyle.Resolver: Equatable {
    public static func == (lhs: ThemeAdaptiveStyle<Style>.Resolver, rhs: ThemeAdaptiveStyle<Style>.Resolver) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

nonisolated extension ThemeAdaptiveStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case light
        case dark
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            light: try container.decode(Style.self, forKey: .light),
            dark: try container.decode(Style.self, forKey: .dark)
        )
    }

    public func encode(to encoder: Encoder) throws {
        guard let light, let dark else {
            throw EncodingError.invalidValue(self, .init(
                codingPath: encoder.codingPath,
                debugDescription: "Cannot encode ThemeAdaptiveStyle with a custom resolver — light/dark values are required for serialization."
            ))
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(light, forKey: .light)
        try container.encode(dark, forKey: .dark)
    }
}
