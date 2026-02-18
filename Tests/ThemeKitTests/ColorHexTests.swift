import Testing
import SwiftUI
@testable import ThemeKit

@Suite("Color+Hex")
struct ColorHexTests {

    /// Checks that two hex values are within ±1 per channel (accounts for NSColor color space rounding).
    private func expectHexClose(_ actual: String, _ expected: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let a = Int(actual.dropFirst(), radix: 16)!
        let e = Int(expected.dropFirst(), radix: 16)!
        let dr = abs(((a >> 16) & 0xFF) - ((e >> 16) & 0xFF))
        let dg = abs(((a >> 8) & 0xFF) - ((e >> 8) & 0xFF))
        let db = abs((a & 0xFF) - (e & 0xFF))
        #expect(dr <= 1 && dg <= 1 && db <= 1,
                "Hex \(actual) not close to \(expected) (dr=\(dr) dg=\(dg) db=\(db))",
                sourceLocation: sourceLocation)
    }

    // MARK: - init(hex: Int) — exact for primary colors

    @Test func initHexInt_black() throws {
        #expect(try Color(hex: 0x000000).hexString == "#000000")
    }

    @Test func initHexInt_white() throws {
        #expect(try Color(hex: 0xFFFFFF).hexString == "#FFFFFF")
    }

    @Test func initHexInt_red() throws {
        #expect(try Color(hex: 0xFF0000).hexString == "#FF0000")
    }

    @Test func initHexInt_green() throws {
        #expect(try Color(hex: 0x00FF00).hexString == "#00FF00")
    }

    @Test func initHexInt_blue() throws {
        #expect(try Color(hex: 0x0000FF).hexString == "#0000FF")
    }

    @Test func initHexInt_knownColor_approximate() throws {
        expectHexClose(try Color(hex: 0xFF5733).hexString, "#FF5733")
    }

    // MARK: - init(hex: String)

    @Test func initHexString_withHash() throws {
        // String and Int inits should produce the same result
        #expect(try Color(hex: "#FF5733").hexString == Color(hex: 0xFF5733).hexString)
    }

    @Test func initHexString_withoutHash() throws {
        #expect(try Color(hex: "FF5733").hexString == Color(hex: 0xFF5733).hexString)
    }

    @Test func initHexString_lowercase() throws {
        #expect(try Color(hex: "#ff5733").hexString == Color(hex: "#FF5733").hexString)
    }

    @Test func initHexString_uppercase_exact() throws {
        #expect(try Color(hex: "#FF0000").hexString == "#FF0000")
    }

    // MARK: - hexString format

    @Test func hexString_producesUppercaseFormat() throws {
        let hex = try Color(hex: 0xABCDEF).hexString
        #expect(hex.hasPrefix("#"))
        #expect(hex.count == 7)
        // Verify uppercase
        #expect(hex == hex.uppercased())
    }

    // MARK: - Round-trip: exact for primary colors

    @Test func roundTrip_primaryColors_exact() throws {
        let hexValues = [0x000000, 0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF]
        for hex in hexValues {
            let first = try Color(hex: hex).hexString
            let second = try Color(hex: first).hexString
            #expect(second == first, "Not idempotent for 0x\(String(hex, radix: 16, uppercase: true))")
        }
    }

    // MARK: - Round-trip: approximate for non-primary colors (NSColor color space rounding)

    @Test func roundTrip_nonPrimaryColors_approximate() throws {
        let hexValues = [0x1A2B3C, 0x123456, 0xFF5733, 0xABCDEF]
        for hex in hexValues {
            let first = try Color(hex: hex).hexString
            expectHexClose(first, String(format: "#%06X", hex))
        }
    }

    // MARK: - String init round-trip

    @Test func initHexString_roundTrip_primaryColors() throws {
        let strings = ["#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF"]
        for str in strings {
            #expect(try Color(hex: str).hexString == str)
        }
    }
}
