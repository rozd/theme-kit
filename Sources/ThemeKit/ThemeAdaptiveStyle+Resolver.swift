import SwiftUI

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

// MARK: - Equatable conformance for Resolver

nonisolated extension ThemeAdaptiveStyle.Resolver: Equatable {
    public static func == (lhs: ThemeAdaptiveStyle<Style>.Resolver, rhs: ThemeAdaptiveStyle<Style>.Resolver) -> Bool {
        lhs.id == rhs.id
    }
}
