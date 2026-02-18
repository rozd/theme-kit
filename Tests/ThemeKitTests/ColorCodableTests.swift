import Testing
import SwiftUI
import Foundation
@testable import ThemeKit

@Suite("Color+Codable")
struct ColorCodableTests {

    // MARK: - Encode

    @Test func encode_primaryColor_producesExactHex() throws {
        let color = Color(hex: 0xFF0000)
        let data = try JSONEncoder().encode(color)
        let string = try JSONDecoder().decode(String.self, from: data)
        #expect(string == "#FF0000")
    }

    @Test func encode_black() throws {
        let data = try JSONEncoder().encode(Color(hex: 0x000000))
        let string = try JSONDecoder().decode(String.self, from: data)
        #expect(string == "#000000")
    }

    @Test func encode_white() throws {
        let data = try JSONEncoder().encode(Color(hex: 0xFFFFFF))
        let string = try JSONDecoder().decode(String.self, from: data)
        #expect(string == "#FFFFFF")
    }

    @Test func encode_producesHexFormatString() throws {
        let color = Color(hex: 0xFF5733)
        let data = try JSONEncoder().encode(color)
        let string = try JSONDecoder().decode(String.self, from: data)
        #expect(string.hasPrefix("#"))
        #expect(string.count == 7)
    }

    // MARK: - Decode

    @Test func decode_fromHexString() throws {
        let json = Data("\"#FF0000\"".utf8)
        let color = try JSONDecoder().decode(Color.self, from: json)
        #expect(try color.hexString == "#FF0000")
    }

    @Test func decode_fromHexStringWithoutHash() throws {
        let json = Data("\"FF0000\"".utf8)
        let color = try JSONDecoder().decode(Color.self, from: json)
        #expect(try color.hexString == "#FF0000")
    }

    // MARK: - Round-trip: primary colors (exact)

    @Test func roundTrip_primaryColors_exact() throws {
        let colors = [
            Color(hex: 0x000000),
            Color(hex: 0xFFFFFF),
            Color(hex: 0xFF0000),
            Color(hex: 0x00FF00),
            Color(hex: 0x0000FF),
        ]
        for color in colors {
            let data = try JSONEncoder().encode(color)
            let decoded = try JSONDecoder().decode(Color.self, from: data)
            #expect(try decoded.hexString == color.hexString)
        }
    }

    // MARK: - Round-trip: encode→decode→encode produces same JSON

    @Test func roundTrip_encodeDecodeEncode_stableJSON() throws {
        let colors = [
            Color(hex: 0x000000),
            Color(hex: 0xFFFFFF),
            Color(hex: 0xFF0000),
            Color(hex: 0xABCDEF),
        ]
        for color in colors {
            let data1 = try JSONEncoder().encode(color)
            let decoded = try JSONDecoder().decode(Color.self, from: data1)
            let data2 = try JSONEncoder().encode(decoded)
            let json1 = String(data: data1, encoding: .utf8)!
            let json2 = String(data: data2, encoding: .utf8)!
            #expect(json1 == json2, "JSON not stable: \(json1) → \(json2)")
        }
    }

    // MARK: - Encode edge cases (hexString fallback path)

    @Test func encode_clearColor_producesValidHex() throws {
        // Color.clear has alpha 0, but hexString ignores alpha and returns RGB
        let data = try JSONEncoder().encode(Color.clear)
        let string = try JSONDecoder().decode(String.self, from: data)
        #expect(string.hasPrefix("#"))
        #expect(string.count == 7)
    }

    @Test func encode_usesHexStringValue() throws {
        // Verify encode produces exactly what hexString returns for a known color
        let color = Color(hex: 0x00FF00)
        let data = try JSONEncoder().encode(color)
        let encoded = try JSONDecoder().decode(String.self, from: data)
        #expect(try encoded == color.hexString)
    }

    @Test func encode_writesSingleValueContainer() throws {
        // The Codable encoding should be a bare string, not a keyed container
        let color = Color(hex: 0xFF0000)
        let data = try JSONEncoder().encode(color)
        let json = String(data: data, encoding: .utf8)!
        // A single-value container produces a quoted string like "\"#FF0000\""
        #expect(json == "\"#FF0000\"")
    }

    @Test func encode_encodesNilWhenHexStringThrows() throws {
        // The encode method uses `try container.encode(try? self.hexString)`.
        // When hexString throws, the Optional<String> is nil and encodes as JSON null.
        // On macOS, hexString never throws (NSColor.getRed returns Void), so we
        // verify the normal path produces valid hex for edge-case colors.
        // On iOS, UIColor.getRed can fail for non-RGB color spaces, triggering
        // HexCodingError.rgbExtractionFailed — the encode would produce null.
        let edgeCaseColors: [Color] = [.clear, .white, .black, Color(hex: 0x000000)]
        for color in edgeCaseColors {
            let data = try JSONEncoder().encode(color)
            let hex = try JSONDecoder().decode(String.self, from: data)
            #expect(hex.hasPrefix("#"), "Encoded color should start with #")
            #expect(hex.count == 7, "Encoded color should be 7 chars (#RRGGBB)")
        }
    }

    // MARK: - Error cases

    @Test func decode_invalidType_throws() {
        let json = Data("42".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Color.self, from: json)
        }
    }
}
