import SwiftUI

nonisolated public extension ThemeAdaptiveStyle {

    enum Defaults: Sendable, Equatable {
        case colorScheme(light: Style, dark: Style)
        case sizeClass(compact: Style, regular: Style)
        case value(Style)

        func makeResolver() -> Resolver {
            switch self {
            case .colorScheme(let light, let dark):
                Resolver(id: Self.resolverID(self)) { env in
                    env.colorScheme == .dark ? dark : light
                }
            case .sizeClass(let compact, let regular):
                Resolver(id: Self.resolverID(self)) { env in
                    env.horizontalSizeClass == .compact ? compact : regular
                }
            case .value(let style):
                Resolver(id: Self.resolverID(self)) { _ in
                    style
                }
            }
        }

        private static func resolverID(_ defaults: Defaults) -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            guard let data = try? encoder.encode(defaults) else {
                return UUID().uuidString
            }
            var hasher = Hasher()
            hasher.combine(data)
            return String(hasher.finalize())
        }
    }
}

// MARK: - Codable

extension ThemeAdaptiveStyle.Defaults: Codable {

    private enum ColorSchemeCodingKeys: String, CodingKey {
        case light, dark
    }

    private enum SizeClassCodingKeys: String, CodingKey {
        case compact, regular
    }

    public init(from decoder: Decoder) throws {
        // Try keyed container first for colorScheme / sizeClass
        if let container = try? decoder.container(keyedBy: ColorSchemeCodingKeys.self),
           container.contains(.light) {
            self = .colorScheme(
                light: try container.decode(Style.self, forKey: .light),
                dark: try container.decode(Style.self, forKey: .dark)
            )
        } else if let container = try? decoder.container(keyedBy: SizeClassCodingKeys.self),
                  container.contains(.compact) {
            self = .sizeClass(
                compact: try container.decode(Style.self, forKey: .compact),
                regular: try container.decode(Style.self, forKey: .regular)
            )
        } else {
            // Plain value
            let container = try decoder.singleValueContainer()
            self = .value(try container.decode(Style.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .colorScheme(let light, let dark):
            var container = encoder.container(keyedBy: ColorSchemeCodingKeys.self)
            try container.encode(light, forKey: .light)
            try container.encode(dark, forKey: .dark)
        case .sizeClass(let compact, let regular):
            var container = encoder.container(keyedBy: SizeClassCodingKeys.self)
            try container.encode(compact, forKey: .compact)
            try container.encode(regular, forKey: .regular)
        case .value(let style):
            var container = encoder.singleValueContainer()
            try container.encode(style)
        }
    }
}
