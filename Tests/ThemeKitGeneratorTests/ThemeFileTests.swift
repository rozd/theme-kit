import Testing
import Foundation
@testable import ThemeKitGenerator

@Suite("ThemeFile")
struct ThemeFileTests {

    @Test func decodesFullConfig() throws {
        let json = Data("""
        {
            "styles": {
                "colors": ["primary"]
            },
            "config": {
                "outputPath": "Generated/Theme"
            }
        }
        """.utf8)

        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: json)
        #expect(themeFile.styles.colors?.count == 1)
        #expect(themeFile.config?.outputPath == "Generated/Theme")
        #expect(themeFile.resolvedOutputPath == "Generated/Theme")
    }

    @Test func decodesWithoutConfig() throws {
        let json = Data("""
        {
            "styles": {
                "colors": ["primary"]
            }
        }
        """.utf8)

        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: json)
        #expect(themeFile.styles.colors?.count == 1)
        #expect(themeFile.config == nil)
        #expect(themeFile.resolvedOutputPath == ".")
    }

    @Test func resolvedOutputPath_usesConfigWhenPresent() {
        let config = ThemeFile.GenerationConfig(outputPath: "Custom/Path")
        let styles = ThemeConfig(colors: [ThemeToken(name: "primary", style: "primary")])
        let themeFile = ThemeFile(styles: styles, config: config)
        #expect(themeFile.resolvedOutputPath == "Custom/Path")
    }

    @Test func resolvedOutputPath_usesDefaultWhenAbsent() {
        let styles = ThemeConfig(colors: [ThemeToken(name: "primary", style: "primary")])
        let themeFile = ThemeFile(styles: styles, config: nil)
        #expect(themeFile.resolvedOutputPath == ".")
    }

    @Test func encodesAndDecodes() throws {
        let original = ThemeFile(
            styles: ThemeConfig(colors: [ThemeToken(name: "surface", style: "surface")]),
            config: ThemeFile.GenerationConfig(outputPath: "UI/Theme")
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeFile.self, from: encoded)

        #expect(decoded == original)
    }
}
