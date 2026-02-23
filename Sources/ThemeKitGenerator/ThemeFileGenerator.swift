import Foundation

nonisolated public struct ThemeFileGenerator: Sendable {

    nonisolated public init() {}

    nonisolated public func generate(from config: ThemeConfig) -> [GeneratedFile] {
        var files: [GeneratedFile] = []

        // Static files (same regardless of config)
        files.append(ThemeShapeStyleGenerator().generate())
        files.append(EnvironmentThemeGenerator().generate())

        // Conditional static files
        if config.categories.contains(.shadows) {
            files.append(ThemeShadowedStyleGenerator().generate())
        }

        // Theme root struct
        files.append(ThemeStructGenerator().generate(from: config))

        // Theme copyWith
        files.append(CopyWithGenerator().generateForTheme(config: config))

        // Per-category files
        for category in config.categories {
            let tokens = category.tokens(from: config)

            files.append(CategoryStructGenerator().generate(category: category, tokens: tokens))
            files.append(CopyWithGenerator().generateForCategory(category: category, tokens: tokens))
            files.append(ShapeStyleExtensionGenerator().generate(category: category, tokens: tokens))
        }

        // Defaults scaffold (editable by app dev)
        files.append(DefaultsGenerator().generate(from: config))

        return files
    }

    nonisolated public func generate(fromJSON data: Data) throws -> (files: [GeneratedFile], outputPath: String) {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: data)
        var files = generate(from: themeFile.styles)

        // Conditionally add preview file
        if themeFile.shouldGeneratePreview {
            files.append(ThemePreviewGenerator().generate(from: themeFile.styles))
        }

        return (files, themeFile.resolvedOutputPath)
    }
}
