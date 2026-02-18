import Testing
import SwiftUI
import Foundation
@testable import ThemeKit

@Suite("ThemeAdaptiveStyle")
struct ThemeAdaptiveStyleTests {

    // MARK: - Init and property storage

    @Test func init_storesLightAndDark() throws {
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        #expect(try style.light.hexString == "#FF0000")
        #expect(try style.dark.hexString == "#0000FF")
    }

    // MARK: - resolved(for:)

    @Test func resolved_forLight_returnsLightValue() throws {
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let resolved = style.resolved(for: .light)
        #expect(try resolved.hexString == "#FF0000")
    }

    @Test func resolved_forDark_returnsDarkValue() throws {
        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let resolved = style.resolved(for: .dark)
        #expect(try resolved.hexString == "#0000FF")
    }

    // MARK: - Codable round-trip with Color

    @Test func codableRoundTrip_color() throws {
        let original = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Color>.self, from: data)
        #expect(try decoded.light.hexString == "#FF0000")
        #expect(try decoded.dark.hexString == "#0000FF")
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
        #expect(decoded.light.stops.count == 2)
        #expect(decoded.dark.stops.count == 2)
        #expect(try decoded.light.stops[0].color.hexString == "#FF0000")
        #expect(try decoded.dark.stops[0].color.hexString == "#0000FF")
    }

    // MARK: - Nested structure

    @Test func codableRoundTrip_nestedAdaptiveStyle() throws {
        let inner = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        let wrapper = ThemeAdaptiveStyle(light: inner, dark: inner)
        let data = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(
            ThemeAdaptiveStyle<ThemeAdaptiveStyle<Color>>.self, from: data
        )
        #expect(try decoded.light.light.hexString == "#FF0000")
        #expect(try decoded.light.dark.hexString == "#0000FF")
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
        // resolve(in:) calls resolved(for: environment.colorScheme).
        // Verify the environment plumbing selects the correct variant.
        var lightEnv = EnvironmentValues()
        lightEnv.colorScheme = .light
        var darkEnv = EnvironmentValues()
        darkEnv.colorScheme = .dark

        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))

        // Trace the same code path as resolve(in:): read colorScheme, call resolved(for:)
        #expect(try style.resolved(for: lightEnv.colorScheme).hexString == "#FF0000")
        #expect(try style.resolved(for: darkEnv.colorScheme).hexString == "#0000FF")

        // Exercise the actual ShapeStyle resolve entry point
        let _ = style.resolve(in: lightEnv)
        let _ = style.resolve(in: darkEnv)
    }

    @Test func resolve_defaultEnvironmentUsesLight() throws {
        // Default EnvironmentValues has colorScheme == .light
        let env = EnvironmentValues()
        #expect(env.colorScheme == .light)

        let style = ThemeAdaptiveStyle(light: Color(hex: 0xFF0000), dark: Color(hex: 0x0000FF))
        #expect(try style.resolved(for: env.colorScheme).hexString == "#FF0000")
        let _ = style.resolve(in: env)
    }

    // MARK: - Decode from JSON

    @Test func decode_fromRawJSON() throws {
        let json = Data("""
        {"light": "#FF0000", "dark": "#0000FF"}
        """.utf8)
        let decoded = try JSONDecoder().decode(ThemeAdaptiveStyle<Color>.self, from: json)
        #expect(try decoded.light.hexString == "#FF0000")
        #expect(try decoded.dark.hexString == "#0000FF")
    }
}
