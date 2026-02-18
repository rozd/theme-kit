nonisolated public struct DefaultsGenerator: Sendable {

    nonisolated public init() {}

    nonisolated public func generate(from config: ThemeConfig) -> GeneratedFile {
        var sections: [String] = []

        // Theme.default
        let categoryInits = config.categories.map { category in
            "        \(category.propertyName): .`default`"
        }.joined(separator: ",\n")

        let themeDefault = "    static let `default` = Theme("
        sections.append("""
        nonisolated extension Theme {
        \(themeDefault)
        \(categoryInits)
            )
        }
        """)

        // Per-category defaults
        for category in config.categories {
            let tokens = category.tokens(from: config)
            sections.append(categorySection(category: category, tokens: tokens))
        }

        let content = """
        import SwiftUI
        import ThemeKit

        \(sections.joined(separator: "\n\n"))

        """
        return GeneratedFile(name: "Theme+Defaults.swift", content: content)
    }

    nonisolated func categorySection(category: ThemeCategory, tokens: [ThemeToken]) -> String {
        let maxNameLength = tokens.map(\.name.count).max() ?? 0

        let tokenLines: String
        switch category {
        case .gradients:
            tokenLines = tokens.map { token in
                let padding = String(repeating: " ", count: maxNameLength - token.name.count)
                return """
                        \(token.name):\(padding) .init(
                            light: .init(colors: [<#color#>, <#color#>]),
                            dark:  .init(colors: [<#color#>, <#color#>])
                        )
                """
            }.joined(separator: ",\n")
        default:
            tokenLines = tokens.map { token in
                let padding = String(repeating: " ", count: maxNameLength - token.name.count)
                return "        \(token.name):\(padding) .init(light: <#light#>, dark: <#dark#>)"
            }.joined(separator: ",\n")
        }

        let categoryDefault = "    static let `default` = \(category.structName)("
        return """
        // MARK: - \(category.structName)

        nonisolated extension \(category.structName) {
        \(categoryDefault)
        \(tokenLines)
            )
        }
        """
    }
}
