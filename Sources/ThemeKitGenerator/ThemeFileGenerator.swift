import Foundation

public struct ThemeFileGenerator: Sendable {

    public init() {}

    public func generate(from config: ThemeConfig) -> [GeneratedFile] {
        var files: [GeneratedFile] = []

        // Static files (same regardless of config)
        files.append(ThemeShapeStyleGenerator().generate())
        files.append(EnvironmentThemeGenerator().generate())

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

        return files
    }

    public func generate(fromJSON data: Data) throws -> [GeneratedFile] {
        let config = try JSONDecoder().decode(ThemeConfig.self, from: data)
        return generate(from: config)
    }
}
