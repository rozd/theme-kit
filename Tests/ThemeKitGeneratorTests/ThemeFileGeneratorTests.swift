import Testing
import Foundation
@testable import ThemeKitGenerator

@Suite("ThemeFileGenerator")
struct ThemeFileGeneratorTests {

    let fullJSON = Data("""
    {
        "styles": {
            "colors": ["surface", {"name": "primary", "style": "primaryColor"}],
            "gradients": ["primary"]
        }
    }
    """.utf8)

    let colorsOnlyJSON = Data("""
    {
        "styles": {
            "colors": ["surface"]
        }
    }
    """.utf8)

    let shadowsOnlyJSON = Data("""
    {
        "styles": {
            "shadows": ["card", {"name": "inner", "style": "innerGlow"}]
        }
    }
    """.utf8)

    let meshGradientsOnlyJSON = Data("""
    {
        "styles": {
            "meshGradients": ["aurora", {"name": "sunset", "style": "sunsetMesh"}]
        }
    }
    """.utf8)

    let fullWithShadowsJSON = Data("""
    {
        "styles": {
            "colors": ["surface", {"name": "primary", "style": "primaryColor"}],
            "gradients": ["primary"],
            "shadows": ["card"]
        }
    }
    """.utf8)

    // MARK: - File list

    @Test func fullConfig_generatesAllExpectedFiles() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let names = Set(files.map(\.name))

        #expect(names.contains("ThemeShapeStyle.swift"))
        #expect(names.contains("Environment+Theme.swift"))
        #expect(names.contains("Theme.swift"))
        #expect(names.contains("ThemeColors.swift"))
        #expect(names.contains("ThemeGradients.swift"))
        #expect(names.contains("Theme+CopyWith.swift"))
        #expect(names.contains("ThemeColors+CopyWith.swift"))
        #expect(names.contains("ThemeGradients+CopyWith.swift"))
        #expect(names.contains("ShapeStyle+ThemeColors.swift"))
        #expect(names.contains("ShapeStyle+ThemeGradients.swift"))
        #expect(names.contains("Theme+Defaults.swift"))
        #expect(files.count == 11)
    }

    @Test func fullConfig_withAndroidSupport_generatesAllExpectedFiles() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let names = Set(files.map(\.name))

        #expect(names.contains("ThemeShapeStyle.swift"))
        #expect(names.contains("Environment+Theme.swift"))
        #expect(names.contains("Android/View+AndroidThemeStyles.swift"))
        #expect(names.contains("Theme.swift"))
        #expect(names.contains("ThemeColors.swift"))
        #expect(names.contains("ThemeGradients.swift"))
        #expect(names.contains("Theme+CopyWith.swift"))
        #expect(names.contains("ThemeColors+CopyWith.swift"))
        #expect(names.contains("ThemeGradients+CopyWith.swift"))
        #expect(names.contains("ShapeStyle+ThemeColors.swift"))
        #expect(names.contains("ShapeStyle+ThemeGradients.swift"))
        #expect(names.contains("Theme+Defaults.swift"))
        #expect(files.count == 12)
    }

    @Test func colorsOnly_generatesSubset() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let names = Set(files.map(\.name))

        // Static files always present
        #expect(names.contains("ThemeShapeStyle.swift"))
        #expect(names.contains("Environment+Theme.swift"))
        #expect(names.contains("Theme.swift"))
        #expect(names.contains("Theme+CopyWith.swift"))

        // Colors category files
        #expect(names.contains("ThemeColors.swift"))
        #expect(names.contains("ThemeColors+CopyWith.swift"))
        #expect(names.contains("ShapeStyle+ThemeColors.swift"))

        // Defaults scaffold
        #expect(names.contains("Theme+Defaults.swift"))

        // Gradients/Shadows should NOT be present
        #expect(!names.contains("ThemeGradients.swift"))
        #expect(!names.contains("ThemeShadows.swift"))

        #expect(files.count == 8)
    }

    @Test func colorsOnly_withAndroidSupport_generatesSubset() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: colorsOnlyJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let names = Set(files.map(\.name))

        // Static files always present
        #expect(names.contains("ThemeShapeStyle.swift"))
        #expect(names.contains("Environment+Theme.swift"))
        #expect(names.contains("Android/View+AndroidThemeStyles.swift"))
        #expect(names.contains("Theme.swift"))
        #expect(names.contains("Theme+CopyWith.swift"))

        // Colors category files
        #expect(names.contains("ThemeColors.swift"))
        #expect(names.contains("ThemeColors+CopyWith.swift"))
        #expect(names.contains("ShapeStyle+ThemeColors.swift"))

        // Defaults scaffold
        #expect(names.contains("Theme+Defaults.swift"))

        // Gradients/Shadows should NOT be present
        #expect(!names.contains("ThemeGradients.swift"))
        #expect(!names.contains("ThemeShadows.swift"))

        #expect(files.count == 9)
    }

    // MARK: - Generated header

    @Test func allFiles_startWithGeneratedHeader() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        for file in files where file.name != "Theme+Defaults.swift" {
            #expect(file.content.hasPrefix("// Generated by ThemeKit — do not edit"),
                    "File \(file.name) missing generated header")
        }
    }

    @Test func defaultsFile_hasNoGeneratedHeader() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })
        #expect(!defaults.content.hasPrefix("// Generated by ThemeKit"))
    }

    // MARK: - Content patterns

    @Test func themeStruct_containsCategoryProperties() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let themeFile = try #require(files.first { $0.name == "Theme.swift" })

        #expect(themeFile.content.contains("let colors: ThemeColors"))
        #expect(themeFile.content.contains("let gradients: ThemeGradients"))
        #expect(themeFile.content.contains("struct Theme"))
    }

    @Test func categoryStruct_containsTokenProperties() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let colorsFile = try #require(files.first { $0.name == "ThemeColors.swift" })

        #expect(colorsFile.content.contains("let surface: ThemeAdaptiveStyle<Color>"))
        #expect(colorsFile.content.contains("let primary: ThemeAdaptiveStyle<Color>"))
        #expect(colorsFile.content.contains("struct ThemeColors"))
    }

    @Test func shapeStyleExtension_usesCorrectStyleNames() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let colorsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeColors.swift" })

        // "surface" token: name == style, so ShapeStyle property is "surface"
        #expect(colorsExt.content.contains("static var surface: Self"))
        #expect(colorsExt.content.contains("\\.colors.surface"))

        // "primary" token with style "primaryColor"
        #expect(colorsExt.content.contains("static var primaryColor: Self"))
        #expect(colorsExt.content.contains("\\.colors.primary"))
    }

    @Test func shapeStyleExtension_constrainsToCorrectType() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files

        let colorsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeColors.swift" })
        #expect(colorsExt.content.contains("ThemeShapeStyle<Color>"))

        let gradientsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeGradients.swift" })
        #expect(gradientsExt.content.contains("ThemeShapeStyle<Gradient>"))
    }

    @Test func shapeStyleExtension_usesNonisolated() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files

        let colorsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeColors.swift" })
        #expect(colorsExt.content.contains("nonisolated extension ShapeStyle"))

        let gradientsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeGradients.swift" })
        #expect(gradientsExt.content.contains("nonisolated extension ShapeStyle"))
    }

    @Test func shadowShapeStyleExtension_bothBlocksUseNonisolated() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let shadowExt = try #require(files.first { $0.name == "ShapeStyle+ThemeShadows.swift" })

        // Default (flag-off): only Apple block with constrained static and unconstrained instance extensions
        let appleShapeStyleMatches = shadowExt.content.components(separatedBy: "nonisolated extension ShapeStyle")
        #expect(appleShapeStyleMatches.count == 3, "Expected two 'nonisolated extension ShapeStyle' occurrences (splits into 3 parts)")
    }

    @Test func shadowShapeStyleExtension_withAndroidSupport_bothBlocksUseNonisolated() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: shadowsOnlyJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let shadowExt = try #require(files.first { $0.name == "ShapeStyle+ThemeShadows.swift" })

        // With androidSupport: constrained/unconstrained ShapeStyle extensions AND AndroidShapeStyleAdapter extensions
        let appleShapeStyleMatches = shadowExt.content.components(separatedBy: "nonisolated extension ShapeStyle")
        #expect(appleShapeStyleMatches.count == 3, "Expected two ShapeStyle extensions (splits into 3)")

        let androidMatches = shadowExt.content.components(separatedBy: "nonisolated extension AndroidShapeStyleAdapter")
        #expect(androidMatches.count == 3, "Expected two AndroidShapeStyleAdapter extensions (splits into 3)")
    }

    @Test func copyWith_themeUsesOptionalParams() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let copyWith = try #require(files.first { $0.name == "Theme+CopyWith.swift" })

        #expect(copyWith.content.contains("colors: ThemeColors? = nil"))
        #expect(copyWith.content.contains("gradients: ThemeGradients? = nil"))
        #expect(copyWith.content.contains("colors: colors ?? self.colors"))
    }

    @Test func copyWith_categoryUsesOptionalParams() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let copyWith = try #require(files.first { $0.name == "ThemeColors+CopyWith.swift" })

        #expect(copyWith.content.contains("surface: ThemeAdaptiveStyle<Color>? = nil"))
        #expect(copyWith.content.contains("surface: surface ?? self.surface"))
    }

    @Test func themeShapeStyle_containsResolveMethod() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let shapeStyle = try #require(files.first { $0.name == "ThemeShapeStyle.swift" })

        #expect(shapeStyle.content.contains("nonisolated public struct ThemeShapeStyle"))
        #expect(shapeStyle.content.contains("func resolve(in environment: EnvironmentValues)"))
        #expect(shapeStyle.content.contains("environment.theme[keyPath: keyPath]"))
        #expect(shapeStyle.content.contains(".resolved(in: environment)"))
        #expect(!shapeStyle.content.contains("#if !os(Android)"), "Default should not have Android conditional")
    }

    @Test func environmentExtension_containsThemeEntry() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let envFile = try #require(files.first { $0.name == "Environment+Theme.swift" })

        #expect(envFile.content.contains("@Entry public var theme: Theme = .default"))
        #expect(!envFile.content.contains("struct ThemeEnvironmentKey"), "Default should use @Entry, not EnvironmentKey")
    }

    // MARK: - Defaults scaffold

    @Test func defaults_containsThemeExtensionWithCategories() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })

        #expect(defaults.content.contains("extension Theme"))
        #expect(defaults.content.contains("colors: .`default`"))
        #expect(defaults.content.contains("gradients: .`default`"))
    }

    @Test func defaults_containsCategoryDefaults() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })

        #expect(defaults.content.contains("extension ThemeColors"))
        #expect(defaults.content.contains("extension ThemeGradients"))
        #expect(defaults.content.contains("surface:"))
        #expect(defaults.content.contains("primary:"))
    }

    @Test func defaults_colorsUsePlaceholders() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })

        #expect(defaults.content.contains(".init(light: <#light#>, dark: <#dark#>)"))
    }

    @Test func defaults_gradientsUseMultilineFormat() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })

        #expect(defaults.content.contains("light: .init(colors: [<#color#>, <#color#>])"))
        #expect(defaults.content.contains("dark:  .init(colors: [<#color#>, <#color#>])"))
    }

    @Test func defaults_importsThemeKit() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })

        #expect(defaults.content.contains("import SwiftUI"))
        #expect(defaults.content.contains("import ThemeKit"))
    }

    // MARK: - ThemeShapeStyle conformances

    @Test func themeShapeStyle_conformsToEquatable() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let shapeStyle = try #require(files.first { $0.name == "ThemeShapeStyle.swift" })

        #expect(shapeStyle.content.contains("Equatable"))
    }

    @Test func themeShapeStyle_constrainsGenericToSendableAndCodable() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let shapeStyle = try #require(files.first { $0.name == "ThemeShapeStyle.swift" })

        #expect(shapeStyle.content.contains("Style: ShapeStyle & Sendable & Codable & Equatable"))
    }

    @Test func themeShapeStyle_declaresUncheckedSendable() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let shapeStyle = try #require(files.first { $0.name == "ThemeShapeStyle.swift" })

        // Sendability must be asserted on the struct itself — ThemeKit deliberately
        // ships no retroactive `KeyPath: Sendable` conformance.
        #expect(shapeStyle.content.contains("ShapeStyle, Equatable, @unchecked Sendable"))
        #expect(shapeStyle.content.contains("let keyPath: KeyPath<Theme, ThemeAdaptiveStyle<Style>>"))
        #expect(!shapeStyle.content.contains("nonisolated let keyPath"))
    }

    // MARK: - Config Section

    @Test func configSection_providesOutputPath() throws {
        let jsonWithConfig = Data("""
        {
            "styles": {
                "colors": ["surface"]
            },
            "config": {
                "outputPath": "UI/Theme"
            }
        }
        """.utf8)

        let result = try ThemeFileGenerator().generate(fromJSON: jsonWithConfig)
        #expect(result.outputPath == "UI/Theme")
        #expect(!result.files.isEmpty)
    }

    @Test func missingConfig_usesDefaultOutputPath() throws {
        let result = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON)
        #expect(result.outputPath == ".")
    }

    // MARK: - Shadow composition

    @Test func shadowsPresent_generatesThemeShadowedStyle() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let names = Set(files.map(\.name))

        #expect(names.contains("ThemeShadowedStyle.swift"))
    }

    @Test func shadowsAbsent_doesNotGenerateThemeShadowedStyle() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let names = Set(files.map(\.name))

        #expect(!names.contains("ThemeShadowedStyle.swift"))
    }

    @Test func themeShadowedStyle_contentPatterns() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let file = try #require(files.first { $0.name == "ThemeShadowedStyle.swift" })

        // Default (flag-off): struct is ShapeStyle, conformance is unconditional
        #expect(file.content.contains("nonisolated public struct ThemeShadowedStyle<Base: ShapeStyle>: ShapeStyle"))
        #expect(!file.content.contains("#if !os(Android)"), "Default should not have platform conditional")
        #expect(file.content.contains("func resolve(in environment: EnvironmentValues)"))
        #expect(file.content.contains("AnyShapeStyle"))
        #expect(file.content.contains("ThemeShadowedStyle: Equatable where Base: Equatable"))
    }

    @Test func themeShadowedStyle_declaresUncheckedSendable() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let file = try #require(files.first { $0.name == "ThemeShadowedStyle.swift" })

        #expect(file.content.contains("ShapeStyle, @unchecked Sendable"))
        #expect(file.content.contains("let shadowKeyPath: KeyPath<Theme, ThemeAdaptiveStyle<Shadow>>"))
        #expect(!file.content.contains("nonisolated let"))
    }

    @Test func shadowShapeStyle_containsBothStaticAndInstanceProperties() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let shadowExt = try #require(files.first { $0.name == "ShapeStyle+ThemeShadows.swift" })

        // Default (flag-off): single block with both static and instance properties
        #expect(!shadowExt.content.contains("#if !os(Android)"), "Default should not have platform conditional")
        #expect(shadowExt.content.contains("static var card: Self"))
        #expect(shadowExt.content.contains("static var innerGlow: Self"))
        #expect(shadowExt.content.contains("public var card: ThemeShadowedStyle<Self>"))
        #expect(shadowExt.content.contains("public var innerGlow: ThemeShadowedStyle<Self>"))
    }

    @Test func shadowShapeStyle_withAndroidSupport_containsBothBlocksWithProperties() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: shadowsOnlyJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let shadowExt = try #require(files.first { $0.name == "ShapeStyle+ThemeShadows.swift" })

        // With androidSupport: two mutually exclusive blocks
        #expect(shadowExt.content.contains("#if !os(Android)"))
        #expect(shadowExt.content.contains("#else"))
        #expect(shadowExt.content.contains("#endif"))

        // Both versions have static and instance properties
        #expect(shadowExt.content.contains("static var card: Self"))
        #expect(shadowExt.content.contains("static var innerGlow: Self"))
        #expect(shadowExt.content.contains("public var card: ThemeShadowedStyle<Self>"))
        #expect(shadowExt.content.contains("public var innerGlow: ThemeShadowedStyle<Self>"))
    }

    @Test func shadowInstanceProperties_useCorrectNamesAndKeypaths() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let shadowExt = try #require(files.first { $0.name == "ShapeStyle+ThemeShadows.swift" })

        // "card" token: name == style, instance property is "card", keypath uses "card"
        #expect(shadowExt.content.contains("var card: ThemeShadowedStyle<Self> { .init(base: self, shadowKeyPath: \\.shadows.card)"))

        // "inner" token with style "innerGlow": instance property is "innerGlow", keypath uses "inner"
        #expect(shadowExt.content.contains("var innerGlow: ThemeShadowedStyle<Self> { .init(base: self, shadowKeyPath: \\.shadows.inner)"))
    }

    @Test func fullWithShadows_generatesCorrectFileCount() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullWithShadowsJSON).files
        let names = Set(files.map(\.name))

        #expect(names.contains("ThemeShadowedStyle.swift"))
        #expect(names.contains("ThemeShadows.swift"))
        #expect(names.contains("ShapeStyle+ThemeShadows.swift"))
        #expect(files.count == 15)
    }

    @Test func fullWithShadows_withAndroidSupport_generatesCorrectFileCount() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullWithShadowsJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let names = Set(files.map(\.name))

        #expect(names.contains("ThemeShadowedStyle.swift"))
        #expect(names.contains("ThemeShadows.swift"))
        #expect(names.contains("ShapeStyle+ThemeShadows.swift"))
        #expect(names.contains("Android/View+AndroidThemeStyles.swift"))
        #expect(files.count == 16)
    }

    @Test func nonShadowCategories_doNotContainCompositionProperties() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullWithShadowsJSON).files

        let colorsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeColors.swift" })
        // Should not have instance properties, only static properties in both Apple and Android blocks
        #expect(!colorsExt.content.contains("public var"))

        let gradientsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeGradients.swift" })
        // Should not have instance properties, only static properties in both Apple and Android blocks
        #expect(!gradientsExt.content.contains("public var"))
    }

    // MARK: - Mesh gradients

    @Test func meshGradientsOnly_generatesExpectedFiles() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: meshGradientsOnlyJSON).files
        let names = Set(files.map(\.name))

        #expect(names.contains("ThemeShapeStyle.swift"))
        #expect(names.contains("Environment+Theme.swift"))
        #expect(!names.contains("View+ThemeStyles.swift"), "Default should not have View+ThemeStyles.swift")
        #expect(names.contains("Theme.swift"))
        #expect(names.contains("Theme+CopyWith.swift"))
        #expect(names.contains("ThemeMeshGradients.swift"))
        #expect(names.contains("ThemeMeshGradients+CopyWith.swift"))
        #expect(names.contains("ShapeStyle+ThemeMeshGradients.swift"))
        #expect(names.contains("Theme+Defaults.swift"))
        #expect(files.count == 8)
    }

    @Test func meshGradientsCategoryStruct_containsTokenProperties() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: meshGradientsOnlyJSON).files
        let file = try #require(files.first { $0.name == "ThemeMeshGradients.swift" })

        #expect(file.content.contains("let aurora: ThemeAdaptiveStyle<MeshGradient>"))
        #expect(file.content.contains("let sunset: ThemeAdaptiveStyle<MeshGradient>"))
        #expect(file.content.contains("struct ThemeMeshGradients"))
    }

    @Test func meshGradientsShapeStyleExtension_constrainsToCorrectType() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: meshGradientsOnlyJSON).files
        let ext = try #require(files.first { $0.name == "ShapeStyle+ThemeMeshGradients.swift" })

        #expect(ext.content.contains("ThemeShapeStyle<MeshGradient>"))
        #expect(ext.content.contains("static var aurora: Self"))
        #expect(ext.content.contains("static var sunsetMesh: Self"))
    }

    @Test func meshGradientsDefaults_usesMultilineFormat() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: meshGradientsOnlyJSON).files
        let defaults = try #require(files.first { $0.name == "Theme+Defaults.swift" })

        #expect(defaults.content.contains("light: .init(width: 2, height: 2, colors: [<#color#>, <#color#>, <#color#>, <#color#>])"))
        #expect(defaults.content.contains("dark:  .init(width: 2, height: 2, colors: [<#color#>, <#color#>, <#color#>, <#color#>])"))
    }

    // MARK: - Preview generation

    @Test func shouldGeneratePreview_false_doesNotGeneratePreviewFile() throws {
        let jsonWithoutPreview = Data("""
        {
            "styles": {
                "colors": ["surface"]
            },
            "config": {
                "outputPath": ".",
                "shouldGeneratePreview": false
            }
        }
        """.utf8)

        let files = try ThemeFileGenerator().generate(fromJSON: jsonWithoutPreview).files
        let names = Set(files.map(\.name))

        #expect(!names.contains("Theme+Preview.swift"))
    }

    @Test func shouldGeneratePreview_true_generatesPreviewFile() throws {
        let jsonWithPreview = Data("""
        {
            "styles": {
                "colors": ["surface", "primary"]
            },
            "config": {
                "outputPath": ".",
                "shouldGeneratePreview": true
            }
        }
        """.utf8)

        let files = try ThemeFileGenerator().generate(fromJSON: jsonWithPreview).files
        let names = Set(files.map(\.name))

        #expect(names.contains("Theme+Preview.swift"))
    }

    @Test func shouldGeneratePreview_omitted_doesNotGeneratePreviewFile() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let names = Set(files.map(\.name))

        #expect(!names.contains("Theme+Preview.swift"))
    }

    @Test func previewFile_containsCorrectStructure() throws {
        let jsonWithPreview = Data("""
        {
            "styles": {
                "colors": ["surface"],
                "gradients": ["primary"]
            },
            "config": {
                "outputPath": ".",
                "shouldGeneratePreview": true
            }
        }
        """.utf8)

        let files = try ThemeFileGenerator().generate(fromJSON: jsonWithPreview).files
        let previewFile = try #require(files.first { $0.name == "Theme+Preview.swift" })

        #expect(previewFile.content.contains("public struct ThemePreview: View"))
        #expect(previewFile.content.contains("#Preview"))
        #expect(previewFile.content.contains("// MARK: - Colors"))
        #expect(previewFile.content.contains("// MARK: - Gradients"))
    }

    // MARK: - Android render path

    @Test func viewModifiers_generatedAlways() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let names = Set(files.map(\.name))

        #expect(names.contains("Android/View+AndroidThemeStyles.swift"))
    }

    @Test func viewModifiers_containsAndroidBlocks() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let viewModifiers = try #require(files.first { $0.name == "Android/View+AndroidThemeStyles.swift" })

        #expect(viewModifiers.content.contains("#if os(Android)"))
        #expect(viewModifiers.content.contains("nonisolated public protocol AndroidShapeStyleAdapter"))
        #expect(viewModifiers.content.contains("func androidThemeRendering("))
        #expect(viewModifiers.content.contains("AndroidResolvedStyle"))
        #expect(viewModifiers.content.contains("#endif"))
    }

    @Test func viewModifiers_withoutShadows_noShadowedStyleConformance() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: colorsOnlyJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let viewModifiers = try #require(files.first { $0.name == "Android/View+AndroidThemeStyles.swift" })

        #expect(!viewModifiers.content.contains("extension ThemeShadowedStyle: AndroidShapeStyleAdapter"))
    }

    @Test func viewModifiers_withShadows_hasShadowedStyleConformance() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullWithShadowsJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let viewModifiers = try #require(files.first { $0.name == "Android/View+AndroidThemeStyles.swift" })

        #expect(viewModifiers.content.contains("extension ThemeShadowedStyle: AndroidShapeStyleAdapter"))
    }

    @Test func shapeStyleExtensions_mutuallyExclusiveBlocks() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let colorsExt = try #require(files.first { $0.name == "ShapeStyle+ThemeColors.swift" })

        // Must have both #if !os(Android) and #else blocks
        #expect(colorsExt.content.contains("#if !os(Android)"))
        #expect(colorsExt.content.contains("#else"))
        #expect(colorsExt.content.contains("#endif"))

        // Apple block should use ShapeStyle
        #expect(colorsExt.content.contains("nonisolated extension ShapeStyle where Self == ThemeShapeStyle<Color>"))

        // Android block should use AndroidShapeStyleAdapter
        #expect(colorsExt.content.contains("nonisolated extension AndroidShapeStyleAdapter where Self == ThemeShapeStyle<Color>"))
    }

    @Test func themeShapeStyle_unconditionalStruct() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullJSON).files
        let shapeStyle = try #require(files.first { $0.name == "ThemeShapeStyle.swift" })

        #expect(shapeStyle.content.contains("nonisolated public struct ThemeShapeStyle<Style: ShapeStyle & Sendable & Codable & Equatable>: ShapeStyle, Equatable"))
        #expect(!shapeStyle.content.contains("#if !os(Android)"), "Default should not have platform gate")
        #expect(shapeStyle.content.contains("nonisolated public func resolve(in environment: EnvironmentValues) -> some ShapeStyle"))
    }

    @Test func themeShapeStyle_withAndroidSupport_gatedConditionally() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let shapeStyle = try #require(files.first { $0.name == "ThemeShapeStyle.swift" })

        let structIndex = try #require(shapeStyle.content.range(of: "nonisolated public struct ThemeShapeStyle"))
        let gateIndex = try #require(shapeStyle.content.range(of: "#if !os(Android)"))
        #expect(structIndex.lowerBound < gateIndex.lowerBound, "Struct must precede gate")
        #expect(shapeStyle.content.contains("nonisolated public struct ThemeShapeStyle<Style: Sendable & Codable & Equatable>: Equatable, @unchecked Sendable"))
    }

    @Test func viewModifiers_containsVerifiedOverloadSet() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullWithShadowsJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let viewModifiers = try #require(files.first { $0.name == "Android/View+AndroidThemeStyles.swift" })

        #expect(viewModifiers.content.contains("func foregroundStyle<S: AndroidShapeStyleAdapter>"))
        #expect(viewModifiers.content.contains("func background<S: AndroidShapeStyleAdapter>"))
        #expect(viewModifiers.content.contains("func background<S: AndroidShapeStyleAdapter, T: Shape>"))
        #expect(viewModifiers.content.contains("func border<S: AndroidShapeStyleAdapter>"))
        #expect(viewModifiers.content.contains("func fill<S: AndroidShapeStyleAdapter>"))
        #expect(viewModifiers.content.contains("func stroke<S: AndroidShapeStyleAdapter>"))
    }

    @Test func viewModifiers_emitsNoTintOverload() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: fullWithShadowsJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let viewModifiers = try #require(files.first { $0.name == "Android/View+AndroidThemeStyles.swift" })

        // Deliberate omission, not an oversight: `.tint(.primaryColor)` does not compile on
        // Apple, because Swift cannot infer an implicit member's base through tint's
        // optional generic. Emitting it on Android alone would build on one platform and
        // not the other — the exact asymmetry this whole design exists to avoid.
        #expect(!viewModifiers.content.contains("func tint("))
    }

    @Test func themeShadowedStyle_unconditionalStructWithSendable() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: shadowsOnlyJSON).files
        let shadowedStyle = try #require(files.first { $0.name == "ThemeShadowedStyle.swift" })

        // Default (flag-off): struct is `ThemeShadowedStyle<Base: ShapeStyle>: ShapeStyle` with unconditional resolve()
        #expect(shadowedStyle.content.contains("nonisolated public struct ThemeShadowedStyle<Base: ShapeStyle>: ShapeStyle"))
        #expect(shadowedStyle.content.contains("nonisolated public func resolve(in environment: EnvironmentValues) -> some ShapeStyle"))
        #expect(shadowedStyle.content.contains("extension ThemeShadowedStyle: Equatable where Base: Equatable"))
        #expect(!shadowedStyle.content.contains("#if !os(Android)"), "Default should not have platform conditional")
    }

    @Test func themeShadowedStyle_withAndroidSupport_gatedConditionally() throws {
        let themeFile = try JSONDecoder().decode(ThemeFile.self, from: shadowsOnlyJSON)
        let files = try ThemeFileGenerator().generate(from: themeFile.styles, androidSupport: true)
        let shadowedStyle = try #require(files.first { $0.name == "ThemeShadowedStyle.swift" })

        // With androidSupport: struct is unconditional, ShapeStyle conformance is conditional
        #expect(shadowedStyle.content.contains("nonisolated public struct ThemeShadowedStyle<Base: Sendable>: @unchecked Sendable"))
        #expect(shadowedStyle.content.contains("extension ThemeShadowedStyle: Equatable where Base: Equatable"))
        #expect(shadowedStyle.content.contains("#if !os(Android)"))
        #expect(shadowedStyle.content.contains("nonisolated extension ThemeShadowedStyle: ShapeStyle where Base: ShapeStyle"))
    }
}
