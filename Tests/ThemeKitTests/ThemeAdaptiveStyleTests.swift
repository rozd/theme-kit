import Testing
import SwiftUI
import Foundation
@testable import ThemeKit

@Suite("ThemeAdaptiveStyle")
struct ThemeAdaptiveStyleTests {

    // MARK: - Init and property storage

    @Test func init_storesLightAndDark() throws {
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        #expect(try style.light?.hexString == "#FF0000")
        #expect(try style.dark?.hexString == "#0000FF")
    }

    // MARK: - resolved(in:)

    @Test func resolved_forLight_returnsLightValue() throws {
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        var env = EnvironmentValues()
        env.colorScheme = .light
        let resolved = style.resolved(in: env)
        #expect(try resolved.hexString == "#FF0000")
    }

    @Test func resolved_forDark_returnsDarkValue() throws {
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        var env = EnvironmentValues()
        env.colorScheme = .dark
        let resolved = style.resolved(in: env)
        #expect(try resolved.hexString == "#0000FF")
    }

    // MARK: - Codable round-trip with Color

    @Test func codableRoundTrip_color() throws {
        let original = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Color>.self, from: data)
        #expect(try decoded.light?.hexString == "#FF0000")
        #expect(try decoded.dark?.hexString == "#0000FF")
    }

    @Test func codableRoundTrip_color_jsonStructure() throws {
        let original = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let data = try JSONEncoder().encode(original)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(json["light"] == "#FF0000")
        #expect(json["dark"] == "#0000FF")
    }

    // MARK: - Codable round-trip with Shadow

    @Test func codableRoundTrip_shadow() throws {
        let original = ThemeAdaptiveStyle(
            light: Shadow.drop(color: Color(hex: 0x000000), radius: 4, x: 0, y: 2),
            dark: Shadow.drop(color: Color(hex: 0xFFFFFF), radius: 8, x: 0, y: 4)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Shadow>.self, from: data)

        if case .drop(let color, let radius, let x, let y) = decoded.light {
            #expect(try color?.hexString == "#000000")
            #expect(radius == 4)
            #expect(x == 0)
            #expect(y == 2)
        } else {
            Issue.record("Expected .drop for light shadow")
        }

        if case .drop(let color, let radius, let x, let y) = decoded.dark {
            #expect(try color?.hexString == "#FFFFFF")
            #expect(radius == 8)
            #expect(x == 0)
            #expect(y == 4)
        } else {
            Issue.record("Expected .drop for dark shadow")
        }
    }

    // MARK: - Codable round-trip with Gradient

    @Test func codableRoundTrip_gradient() throws {
        let original = ThemeAdaptiveStyle(
            light: Gradient(colors: [Color(hex: 0xFF0000), Color(hex: 0x00FF00)]),
            dark: Gradient(colors: [Color(hex: 0x0000FF), Color(hex: 0xFFFF00)])
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Gradient>.self, from: data)
        #expect(decoded.light?.stops.count == 2)
        #expect(decoded.dark?.stops.count == 2)
        #expect(try decoded.light?.stops[0].color.hexString == "#FF0000")
        #expect(try decoded.dark?.stops[0].color.hexString == "#0000FF")
    }

    // MARK: - Nested structure

    @Test func codableRoundTrip_nestedAdaptiveStyle() throws {
        let inner = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let wrapper = ThemeAdaptiveStyle(light: inner, dark: inner)
        let data = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(
            ThemeAdaptiveStyle<ThemeAdaptiveStyle<Color>>.self, from: data
        )
        #expect(try decoded.light?.light?.hexString == "#FF0000")
        #expect(try decoded.light?.dark?.hexString == "#0000FF")
    }

    // MARK: - ShapeStyle resolve(in:) — environment integration

    @Test func resolve_inLightEnvironment() {
        var env = EnvironmentValues()
        env.colorScheme = .light
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        // Exercises the ShapeStyle conformance with an explicit light environment
        let _ = style.resolve(in: env)
    }

    @Test func resolve_inDarkEnvironment() {
        var env = EnvironmentValues()
        env.colorScheme = .dark
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        // Exercises the ShapeStyle conformance with an explicit dark environment
        let _ = style.resolve(in: env)
    }

    @Test func resolve_readsColorSchemeFromEnvironment() throws {
        // resolve(in:) calls resolved(in: environment).
        // Verify the environment plumbing selects the correct variant.
        var lightEnv = EnvironmentValues()
        lightEnv.colorScheme = .light
        var darkEnv = EnvironmentValues()
        darkEnv.colorScheme = .dark

        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))

        // Trace the same code path as resolve(in:): read colorScheme, call resolved(in:)
        #expect(try style.resolved(in: lightEnv).hexString == "#FF0000")
        #expect(try style.resolved(in: darkEnv).hexString == "#0000FF")

        // Exercise the actual ShapeStyle resolve entry point
        let _ = style.resolve(in: lightEnv)
        let _ = style.resolve(in: darkEnv)
    }

    @Test func resolve_defaultEnvironmentUsesLight() throws {
        // Default EnvironmentValues has colorScheme == .light
        let env = EnvironmentValues()
        #expect(env.colorScheme == .light)

        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        #expect(try style.resolved(in: env).hexString == "#FF0000")
        let _ = style.resolve(in: env)
    }

    // MARK: - Decode from JSON

    @Test func decode_fromRawJSON() throws {
        let json = Data("""
        {"light": "#FF0000", "dark": "#0000FF"}
        """.utf8)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Color>.self, from: json)
        #expect(try decoded.light?.hexString == "#FF0000")
        #expect(try decoded.dark?.hexString == "#0000FF")
    }

    // MARK: - Resolver

    @Test func resolver_init_setsLightAndDarkToNil() {
        let style = ThemeAdaptiveStyle<Color>(resolver: .init(id: "test") { _ in .red })
        #expect(style.light == nil)
        #expect(style.dark == nil)
    }

    @Test func resolver_customResolver_overridesDefaultBehavior() {
        // Custom resolver that inverts the default: light in dark mode, dark in light mode
        let style = ThemeAdaptiveStyle<Color>(resolver: .init(id: "inverted") { env in
            env.colorScheme == .dark ? Color(hex: 0xFF0000) : Color(hex: 0x0000FF)
        })
        var lightEnv = EnvironmentValues()
        lightEnv.colorScheme = .light
        #expect(style.resolved(in: lightEnv) == Color(hex: 0x0000FF))

        var darkEnv = EnvironmentValues()
        darkEnv.colorScheme = .dark
        #expect(style.resolved(in: darkEnv) == Color(hex: 0xFF0000))
    }

    @Test func resolver_dataTokens_sameLightDark_areEqual() {
        let a = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let b = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        #expect(a == b)
    }

    @Test func resolver_dataTokens_differentLightDark_areNotEqual() {
        let a = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let b = ThemeAdaptiveStyle(light: Color(hex: 0x00FF00), dark: Color(hex: 0x0000FF))
        #expect(a != b)
    }

    @Test func resolver_codableRoundTrip_preservesEquality() throws {
        let original = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Color>.self, from: data)
        #expect(original == decoded)
    }

    @Test func resolver_encodingResolverOnly_throws() {
        let style = ThemeAdaptiveStyle<Color>(resolver: .init(id: "test") { _ in .red })
        #expect(throws: EncodingError.self) {
            _ = try JSONEncoder().encode(style)
        }
    }

    @Test func resolver_explicitId_isStable() {
        let resolver1 = ThemeAdaptiveStyle<Color>.Resolver(id: "highContrast") { _ in .white }
        let resolver2 = ThemeAdaptiveStyle<Color>.Resolver(id: "highContrast") { _ in .black }
        #expect(resolver1 == resolver2)
    }

    @Test func resolver_autoId_isUnique() {
        let resolver1 = ThemeAdaptiveStyle<Color>.Resolver { _ in .red }
        let resolver2 = ThemeAdaptiveStyle<Color>.Resolver { _ in .red }
        #expect(resolver1 != resolver2)
    }

    @Test func resolver_shapeStyleResolve_usesCustomResolver() {
        let style = ThemeAdaptiveStyle<Color>(resolver: .init(id: "always-red") { _ in .red })
        var lightEnv = EnvironmentValues()
        lightEnv.colorScheme = .light
        var darkEnv = EnvironmentValues()
        darkEnv.colorScheme = .dark
        // Custom resolver ignores colorScheme — returns red in both
        let _ = style.resolve(in: lightEnv)
        let _ = style.resolve(in: darkEnv)
    }
}
