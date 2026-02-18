import Foundation

/// Root structure of a theme.json file.
nonisolated public struct ThemeFile: Sendable, Codable, Equatable {
    /// Style token definitions (colors, gradients, shadows).
    public let styles: ThemeConfig

    /// Generation configuration (output path, etc.).
    public let config: GenerationConfig?

    /// Configuration for code generation.
    nonisolated public struct GenerationConfig: Sendable, Codable, Equatable {
        /// Relative path from the generation root where generated files should be written.
        public let outputPath: String

        nonisolated public init(outputPath: String) {
            self.outputPath = outputPath
        }
    }

    nonisolated public init(styles: ThemeConfig, config: GenerationConfig? = nil) {
        self.styles = styles
        self.config = config
    }

    /// The resolved output path, defaulting to "." if no config is present.
    nonisolated public var resolvedOutputPath: String {
        config?.outputPath ?? "."
    }
}

nonisolated public struct ThemeConfig: Sendable, Codable, Equatable {
    public let colors: [ThemeToken]?
    public let gradients: [ThemeToken]?
    public let shadows: [ThemeToken]?

    nonisolated public init(
        colors: [ThemeToken]? = nil,
        gradients: [ThemeToken]? = nil,
        shadows: [ThemeToken]? = nil
    ) {
        self.colors = colors
        self.gradients = gradients
        self.shadows = shadows
    }

    nonisolated public var categories: [ThemeCategory] {
        ThemeCategory.allCases.filter { category in
            let tokens = category.tokens(from: self)
            return !tokens.isEmpty
        }
    }
}
