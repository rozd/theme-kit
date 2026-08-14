import Testing
import Foundation
@testable import ThemeKitGenerator

@Suite("ThemeViewModifiersGenerator")
struct ThemeViewModifiersGeneratorTests {

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
            "shadows": ["card"]
        }
    }
    """.utf8)

    let fullWithShadowsJSON = Data("""
    {
        "styles": {
            "colors": ["surface"],
            "shadows": ["card"]
        }
    }
    """.utf8)

    // MARK: - Shadow application invariant

    @Test("Every wrapper view applies shadows via .themeShadow")
    func allWrapperViewsApplyShadows() throws {
        // This test exists because ThemeBackgroundShapeView once dropped the shadow silently.
        // It verifies the structural invariant: every emitted wrapper view that resolves a
        // style must apply the shadow on every code path through .themeShadow(rendering.shadow).
        // The test is written to automatically cover any new wrapper added later.

        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })
        let content = viewModifiers.content

        // Extract all wrapper view struct declarations
        let structPattern = "nonisolated struct \\w+<.*>: View \\{"
        let regex = try NSRegularExpression(pattern: structPattern)
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

        #expect(!matches.isEmpty, "Expected to find wrapper view structs")

        // For each wrapper view, verify it contains .themeShadow( in its body
        for match in matches {
            if let range = Range(match.range, in: content) {
                let structStart = range.lowerBound
                // Find the closing brace of this struct
                var braceCount = 0
                var structEnd = structStart
                var foundOpening = false

                for index in content[structStart...].indices {
                    let char = content[index]
                    if char == "{" {
                        foundOpening = true
                        braceCount += 1
                    } else if char == "}" {
                        braceCount -= 1
                        if foundOpening && braceCount == 0 {
                            structEnd = index
                            break
                        }
                    }
                }

                let structContent = String(content[structStart...structEnd])
                // Only check if this is a wrapper view (has "body: some View" and calls themeRendering)
                if structContent.contains("body: some View") && structContent.contains("themeRendering") {
                    #expect(structContent.contains(".themeShadow("),
                             "Wrapper view struct starting at \(structStart) must apply shadow via .themeShadow()")
                }
            }
        }
    }

    // MARK: - ThemeBackgroundShapeView regression

    @Test("ThemeBackgroundShapeView applies shadow to filled shape, not to content")
    func backgroundShapeView_shadowAppliesToShape() throws {
        // Regression test for the specific bug: ThemeBackgroundShapeView must apply
        // the shadow to the filled shape, not directly to content.

        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })
        let content = viewModifiers.content

        #expect(content.contains("struct ThemeBackgroundShapeView"),
                "ThemeBackgroundShapeView must be emitted")

        // Extract the ThemeBackgroundShapeView struct body
        guard let structStart = content.range(of: "nonisolated struct ThemeBackgroundShapeView") else {
            #expect(false, "Could not find ThemeBackgroundShapeView struct")
            return
        }

        var braceCount = 0
        var foundOpening = false
        var structEnd = structStart.lowerBound

        for index in content[structStart.lowerBound...].indices {
            let char = content[index]
            if char == "{" {
                foundOpening = true
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if foundOpening && braceCount == 0 {
                    structEnd = index
                    break
                }
            }
        }

        let structContent = String(content[structStart.lowerBound...structEnd])

        // The new correct form: shadow applied to shape.fill(...)
        #expect(structContent.contains("shape.fill(shapeStyle, style: fillStyle)"),
                "Must have shape.fill with shapeStyle and fillStyle")
        #expect(structContent.contains(".themeShadow(rendering.shadow)"),
                "Must apply themeShadow to the filled shape")

        // Should NOT have the old buggy form: shadowing content directly
        #expect(!structContent.contains("content.background(shapeStyle, in: shape"),
                "Must NOT apply shadow directly to content.background — shadow goes on shape.fill")

        // The shadow should appear after the shape.fill call
        if let fillRange = structContent.range(of: "shape.fill(shapeStyle, style: fillStyle)"),
           let shadowRange = structContent.range(of: ".themeShadow(rendering.shadow)") {
            #expect(fillRange.lowerBound < shadowRange.lowerBound,
                    "Shadow application must come after shape.fill")
        }
    }

    // MARK: - Default shadow color centralization

    @Test("Magic shadow color literal moved to AndroidShadow.resolvedColor")
    func shadowColorNotInTemplate() throws {
        // Verify that the magic literal `Color(.sRGBLinear, white: 0, opacity: 0.33)`
        // no longer appears in the emitted template — it now lives in ThemeKit's
        // AndroidShadow.resolvedColor property.

        let files = try ThemeFileGenerator().generate(fromJSON: fullWithShadowsJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })

        // The literal should not appear anywhere in the generated code
        #expect(!viewModifiers.content.contains("Color(.sRGBLinear, white: 0, opacity: 0.33)"),
                "Default shadow color must not appear in template — use AndroidShadow.resolvedColor")
    }

    // MARK: - Platform guards

    @Test("Generated file wrapped in #if os(Android) guard")
    func generatedFile_hasAndroidGuard() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })
        let content = viewModifiers.content

        #expect(content.contains("#if os(Android)"),
                "Must have opening #if os(Android) guard")
        #expect(content.contains("#endif"),
                "Must have closing #endif")

        // Verify the guard wraps the substantial content
        if let guardStart = content.range(of: "#if os(Android)"),
           let guardEnd = content.range(of: "#endif") {
            let guardedContent = String(content[guardStart.upperBound..<guardEnd.lowerBound])
            #expect(guardedContent.contains("protocol ThemeStyleResolving"),
                    "Protocol definition must be inside guard")
            #expect(guardedContent.contains("struct ThemeStyledView"),
                    "ThemeStyledView must be inside guard")
            #expect(guardedContent.contains("struct ThemeBackgroundShapeView"),
                    "ThemeBackgroundShapeView must be inside guard")
        }
    }

    // MARK: - Conditional conformances

    @Test("hasShadows=false does not emit ThemeShadowedStyle conformance")
    func withoutShadows_noConformance() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })

        #expect(!viewModifiers.content.contains("extension ThemeShadowedStyle: ThemeStyleResolving"),
                "ThemeShadowedStyle conformance should not be emitted when hasShadows=false")
    }

    @Test("hasShadows=true emits ThemeShadowedStyle conformance")
    func withShadows_hasConformance() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: fullWithShadowsJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })

        #expect(viewModifiers.content.contains("extension ThemeShadowedStyle: ThemeStyleResolving"),
                "ThemeShadowedStyle conformance must be emitted when hasShadows=true")
    }

    @Test("All wrapper views emitted regardless of hasShadows flag")
    func wrappers_emittedAlways() throws {
        // The three wrapper views are emitted unconditionally, even when hasShadows=false,
        // because a standalone shadow-only token resolves to a shadow-only rendering.

        let filesWithoutShadows = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiersNoShadows = try #require(
            filesWithoutShadows.first { $0.name == "View+ThemeStyles.swift" }
        )

        #expect(viewModifiersNoShadows.content.contains("struct ThemeStyledView"),
                "ThemeStyledView must be emitted even without shadows")
        #expect(viewModifiersNoShadows.content.contains("struct ThemeBackgroundShapeView"),
                "ThemeBackgroundShapeView must be emitted even without shadows")
        #expect(viewModifiersNoShadows.content.contains("struct ThemeStyledShapeView"),
                "ThemeStyledShapeView must be emitted even without shadows")

        // Verify they all use .themeShadow even when hasShadows=false
        #expect(viewModifiersNoShadows.content.contains(".themeShadow(rendering.shadow)"),
                ".themeShadow calls must be unconditional in all wrappers")
    }

    // MARK: - Wrapper body consistency

    @Test("ThemeStyledView uses themeShadow")
    func themeStyledView_usesShadow() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })

        let content = viewModifiers.content
        guard let start = content.range(of: "nonisolated struct ThemeStyledView") else {
            #expect(false, "ThemeStyledView not found")
            return
        }

        var braceCount = 0
        var foundOpening = false
        var end = start.lowerBound

        for index in content[start.lowerBound...].indices {
            let char = content[index]
            if char == "{" {
                foundOpening = true
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if foundOpening && braceCount == 0 {
                    end = index
                    break
                }
            }
        }

        let structContent = String(content[start.lowerBound...end])
        #expect(structContent.contains("styled(rendering).themeShadow(rendering.shadow)"),
                "ThemeStyledView body must call .themeShadow on styled result")
    }

    @Test("ThemeStyledShapeView uses themeShadow")
    func themeStyledShapeView_usesShadow() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })

        let content = viewModifiers.content
        guard let start = content.range(of: "nonisolated struct ThemeStyledShapeView") else {
            #expect(false, "ThemeStyledShapeView not found")
            return
        }

        var braceCount = 0
        var foundOpening = false
        var end = start.lowerBound

        for index in content[start.lowerBound...].indices {
            let char = content[index]
            if char == "{" {
                foundOpening = true
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if foundOpening && braceCount == 0 {
                    end = index
                    break
                }
            }
        }

        let structContent = String(content[start.lowerBound...end])
        #expect(structContent.contains("filled(rendering).themeShadow(rendering.shadow)"),
                "ThemeStyledShapeView body must call .themeShadow on filled result")
    }

    // MARK: - File structure

    @Test("File is named View+ThemeStyles.swift")
    func fileName() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = files.first { $0.name == "View+ThemeStyles.swift" }

        #expect(viewModifiers != nil, "Must generate View+ThemeStyles.swift")
    }

    @Test("File starts with generated header")
    func hasGeneratedHeader() throws {
        let files = try ThemeFileGenerator().generate(fromJSON: colorsOnlyJSON).files
        let viewModifiers = try #require(files.first { $0.name == "View+ThemeStyles.swift" })

        #expect(viewModifiers.content.hasPrefix("// Generated by ThemeKit — do not edit"),
                "File must start with generated header")
    }
}
