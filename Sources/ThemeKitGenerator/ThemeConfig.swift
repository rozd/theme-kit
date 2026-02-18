import Foundation

public struct ThemeConfig: Sendable, Codable, Equatable {
    public let colors: [ThemeToken]?
    public let gradients: [ThemeToken]?
    public let shadows: [ThemeToken]?

    public init(
        colors: [ThemeToken]? = nil,
        gradients: [ThemeToken]? = nil,
        shadows: [ThemeToken]? = nil
    ) {
        self.colors = colors
        self.gradients = gradients
        self.shadows = shadows
    }

    public var categories: [ThemeCategory] {
        ThemeCategory.allCases.filter { category in
            let tokens = category.tokens(from: self)
            return !tokens.isEmpty
        }
    }
}
