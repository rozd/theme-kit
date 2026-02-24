import Testing
import Foundation
@testable import ThemeKitGenerator

@Suite("ThemeConfig")
struct ThemeConfigTests {

    // MARK: - Decoding

    @Test func decode_fullConfig() throws {
        let json = Data("""
        {
            "colors": ["surface", {"name": "primary", "style": "primaryColor"}],
            "gradients": ["primary"],
            "meshGradients": ["aurora"],
            "shadows": ["card"]
        }
        """.utf8)
        let config = try JSONDecoder().decode(ThemeConfig.self, from: json)
        #expect(config.colors?.count == 2)
        #expect(config.gradients?.count == 1)
        #expect(config.meshGradients?.count == 1)
        #expect(config.shadows?.count == 1)
    }

    @Test func decode_partialConfig_colorsOnly() throws {
        let json = Data("""
        {
            "colors": ["surface"]
        }
        """.utf8)
        let config = try JSONDecoder().decode(ThemeConfig.self, from: json)
        #expect(config.colors?.count == 1)
        #expect(config.gradients == nil)
        #expect(config.shadows == nil)
    }

    @Test func decode_emptyObject() throws {
        let json = Data("{}".utf8)
        let config = try JSONDecoder().decode(ThemeConfig.self, from: json)
        #expect(config.colors == nil)
        #expect(config.gradients == nil)
        #expect(config.meshGradients == nil)
        #expect(config.shadows == nil)
    }

    // MARK: - Categories computed property

    @Test func categories_fullConfig_returnsAll() throws {
        let config = ThemeConfig(
            colors: [ThemeToken(name: "surface", style: "surface")],
            gradients: [ThemeToken(name: "primary", style: "primary")],
            meshGradients: [ThemeToken(name: "aurora", style: "aurora")],
            shadows: [ThemeToken(name: "card", style: "card")]
        )
        let categories = config.categories
        #expect(categories.count == 4)
        #expect(categories[0] == .colors)
        #expect(categories[1] == .gradients)
        #expect(categories[2] == .meshGradients)
        #expect(categories[3] == .shadows)
    }

    @Test func categories_colorsOnly() {
        let config = ThemeConfig(
            colors: [ThemeToken(name: "surface", style: "surface")]
        )
        let categories = config.categories
        #expect(categories.count == 1)
        #expect(categories[0] == .colors)
    }

    @Test func categories_emptyConfig_returnsEmpty() {
        let config = ThemeConfig()
        #expect(config.categories.isEmpty)
    }

    @Test func categories_emptyArray_excluded() {
        let config = ThemeConfig(colors: [])
        #expect(config.categories.isEmpty)
    }

    @Test func categories_nilAndNonNil_mixed() {
        let config = ThemeConfig(
            colors: nil,
            gradients: [ThemeToken(name: "primary", style: "primary")],
            shadows: nil
        )
        let categories = config.categories
        #expect(categories.count == 1)
        #expect(categories[0] == .gradients)
    }

    @Test func categories_meshGradientsOnly() {
        let config = ThemeConfig(
            meshGradients: [ThemeToken(name: "aurora", style: "aurora")]
        )
        let categories = config.categories
        #expect(categories.count == 1)
        #expect(categories[0] == .meshGradients)
    }
}
