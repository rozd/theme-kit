import Testing
import Foundation
@testable import ThemeKitGenerator

@Suite("ThemeToken")
struct ThemeTokenTests {

    // MARK: - Decoding

    @Test func decode_fromString_setsBothFieldsEqual() throws {
        let json = Data(#""surface""#.utf8)
        let token = try JSONDecoder().decode(ThemeToken.self, from: json)
        #expect(token.name == "surface")
        #expect(token.style == "surface")
    }

    @Test func decode_fromObject_setsSeparateFields() throws {
        let json = Data(#"{"name": "primary", "style": "primaryColor"}"#.utf8)
        let token = try JSONDecoder().decode(ThemeToken.self, from: json)
        #expect(token.name == "primary")
        #expect(token.style == "primaryColor")
    }

    @Test func decode_objectMissingName_throws() {
        let json = Data(#"{"style": "primaryColor"}"#.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(ThemeToken.self, from: json)
        }
    }

    @Test func decode_objectMissingStyle_throws() {
        let json = Data(#"{"name": "primary"}"#.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(ThemeToken.self, from: json)
        }
    }

    // MARK: - Encoding

    @Test func encode_equalFields_encodesAsString() throws {
        let token = ThemeToken(name: "surface", style: "surface")
        let data = try JSONEncoder().encode(token)
        let string = String(data: data, encoding: .utf8)
        #expect(string == #""surface""#)
    }

    @Test func encode_differentFields_encodesAsObject() throws {
        let token = ThemeToken(name: "primary", style: "primaryColor")
        let data = try JSONEncoder().encode(token)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(json["name"] == "primary")
        #expect(json["style"] == "primaryColor")
    }

    // MARK: - Round-trip

    @Test func roundTrip_string() throws {
        let original = ThemeToken(name: "surface", style: "surface")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeToken.self, from: data)
        #expect(decoded == original)
    }

    @Test func roundTrip_object() throws {
        let original = ThemeToken(name: "primary", style: "primaryColor")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeToken.self, from: data)
        #expect(decoded == original)
    }
}
