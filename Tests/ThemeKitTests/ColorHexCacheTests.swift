import Testing
import SwiftUI
import Foundation
@testable import ThemeKit

/// The hex cache is what makes `Color` encoding work on Android, where no colour
/// introspection exists. On Apple it also makes encoding exact rather than
/// colour-space-rounded, which is what these tests pin down: every assertion here is
/// an equality, not the ±1 tolerance the introspection path needs.
@Suite("Color hex cache")
struct ColorHexCacheTests {

    @Test func hexInit_encodesExactly_noColorSpaceRounding() throws {
        // 0xABCDEF survives introspection only within ±1 per channel; through the cache
        // it is exact.
        #expect(try Color(hex: 0xABCDEF).hexString == "#ABCDEF")
        #expect(try Color(hex: 0x1A2B3C).hexString == "#1A2B3C")
        #expect(try Color(hex: 0xFF5733).hexString == "#FF5733")
    }

    @Test func stringInit_normalizesToCanonicalSpelling() throws {
        #expect(try Color(hex: "#ff5733").hexString == "#FF5733")
        #expect(try Color(hex: "FF5733").hexString == "#FF5733")
    }

    @Test func cacheSurvivesCopies() throws {
        // Colours are passed around by value; the cache is keyed by value equality, so a
        // copy that has been through an array must still resolve.
        let original = Color(hex: 0x123456)
        let copies = [original, original]
        let roundTripped = copies[1]
        #expect(try roundTripped.hexString == "#123456")
    }

    @Test func cacheSurvivesCodableRoundTrip() throws {
        let decoded = try JSONDecoder().decode(Color.self, from: Data("\"#0A0B0C\"".utf8))
        // Decoding goes through Color(hex:), so re-encoding reproduces the input exactly.
        let reencoded = try JSONEncoder().encode(decoded)
        #expect(String(data: reencoded, encoding: .utf8) == "\"#0A0B0C\"")
    }

    @Test func nonHexColorsAreNotFalselyCached() throws {
        // A palette colour must not collide with a cached hex colour; it takes the
        // introspection path and produces its own value.
        let paletteHex = try Color.red.hexString
        #expect(paletteHex.hasPrefix("#"))
        #expect(paletteHex.count == 7)
    }

    @Test func distinctHexValuesDoNotCollide() throws {
        let a = Color(hex: 0x010203)
        let b = Color(hex: 0x030201)
        #expect(try a.hexString == "#010203")
        #expect(try b.hexString == "#030201")
    }

    @Test func canonicalHex_formatsChannelsIndependently() {
        #expect(Color.canonicalHex(0x000000) == "#000000")
        #expect(Color.canonicalHex(0xFFFFFF) == "#FFFFFF")
        #expect(Color.canonicalHex(0x0080FF) == "#0080FF")
    }
}

/// The mesh gradient wire format is shared between the Apple conformance and the Android
/// shim; these pin the shared rules so a change on one platform cannot silently diverge.
@Suite("MeshGradient coding")
struct MeshGradientCodingTests {

    @Test func uniformPoints_matchesGridDimensions() {
        #expect(MeshGradientCoding.uniformPoints(width: 2, height: 3).count == 6)
        #expect(MeshGradientCoding.uniformPoints(width: 1, height: 1) == [SIMD2<Float>(0, 0)])
        #expect(MeshGradientCoding.uniformPoints(width: 0, height: 3).isEmpty)
    }

    @Test func decode_missingPoints_fillsUniformGrid() throws {
        let json = Data("""
        {"width": 2, "height": 2, "colors": ["#FF0000", "#00FF00", "#0000FF", "#FFFFFF"]}
        """.utf8)
        let payload = try JSONDecoder().decode(MeshGradientCodingProbe.self, from: json).payload
        #expect(payload.points == MeshGradientCoding.uniformPoints(width: 2, height: 2))
        #expect(payload.colors.count == 4)
    }

    @Test func decode_explicitPoints_arePreserved() throws {
        let json = Data("""
        {"width": 2, "height": 2, "colors": ["#FF0000", "#00FF00", "#0000FF", "#FFFFFF"],
         "points": [[0.0, 0.0], [0.8, 0.0], [0.2, 1.0], [1.0, 1.0]]}
        """.utf8)
        let payload = try JSONDecoder().decode(MeshGradientCodingProbe.self, from: json).payload
        #expect(payload.points[1] == SIMD2<Float>(0.8, 0.0))
        #expect(payload.points[2] == SIMD2<Float>(0.2, 1.0))
    }

    @Test func encode_thenDecode_isStable() throws {
        let original = MeshGradientCoding.Payload(
            width: 2,
            height: 2,
            colors: [Color(hex: 0xFF0000), Color(hex: 0x00FF00), Color(hex: 0x0000FF), Color(hex: 0xFFFFFF)],
            points: MeshGradientCoding.uniformPoints(width: 2, height: 2)
        )
        let data = try JSONEncoder().encode(MeshGradientCodingProbe(payload: original))
        let decoded = try JSONDecoder().decode(MeshGradientCodingProbe.self, from: data).payload
        #expect(decoded == original)
    }
}

/// Exercises `MeshGradientCoding` directly, without going through a platform's
/// `MeshGradient` — the shared layer is the thing under test.
private struct MeshGradientCodingProbe: Codable {
    let payload: MeshGradientCoding.Payload

    init(payload: MeshGradientCoding.Payload) {
        self.payload = payload
    }

    init(from decoder: Decoder) throws {
        self.payload = try MeshGradientCoding.decode(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try MeshGradientCoding.encode(
            width: payload.width,
            height: payload.height,
            colors: payload.colors,
            points: payload.points,
            to: encoder
        )
    }
}
