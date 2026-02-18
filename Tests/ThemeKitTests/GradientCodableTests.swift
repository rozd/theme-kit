import Testing
import SwiftUI
import Foundation
@testable import ThemeKit

@Suite("Gradient+Codable")
struct GradientCodableTests {

    // MARK: - Helpers

    private func jsonRoundTrip(_ value: Gradient) throws -> Gradient {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(Gradient.self, from: data)
    }

    private func jsonEncode(_ value: Gradient) throws -> Any {
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Uniform stops (color array format)

    @Test func decode_uniformColorArray() throws {
        let json = Data("[\"#FF0000\",\"#00FF00\"]".utf8)
        let gradient = try JSONDecoder().decode(Gradient.self, from: json)
        #expect(gradient.stops.count == 2)
        #expect(try gradient.stops[0].color.hexString == "#FF0000")
        #expect(try gradient.stops[1].color.hexString == "#00FF00")
    }

    @Test func encode_uniformGradient_producesColorArray() throws {
        let gradient = Gradient(colors: [Color(hex: 0xFF0000), Color(hex: 0x00FF00)])
        let encoded = try jsonEncode(gradient)
        let array = try #require(encoded as? [String])
        #expect(array == ["#FF0000", "#00FF00"])
    }

    @Test func roundTrip_uniformGradient() throws {
        let original = Gradient(colors: [
            Color(hex: 0xFF0000),
            Color(hex: 0x00FF00),
            Color(hex: 0x0000FF),
        ])
        let decoded = try jsonRoundTrip(original)
        #expect(decoded.stops.count == 3)
        #expect(try decoded.stops[0].color.hexString == "#FF0000")
        #expect(try decoded.stops[1].color.hexString == "#00FF00")
        #expect(try decoded.stops[2].color.hexString == "#0000FF")
    }

    // MARK: - Non-uniform stops (dict format)

    @Test func decode_nonUniformStopDicts() throws {
        let json = Data("[{\"#FF0000\":0.0},{\"#00FF00\":0.3},{\"#0000FF\":1.0}]".utf8)
        let gradient = try JSONDecoder().decode(Gradient.self, from: json)
        #expect(gradient.stops.count == 3)
        #expect(try gradient.stops[0].color.hexString == "#FF0000")
        #expect(gradient.stops[0].location == 0.0)
        #expect(try gradient.stops[1].color.hexString == "#00FF00")
        #expect(gradient.stops[1].location == 0.3)
        #expect(try gradient.stops[2].color.hexString == "#0000FF")
        #expect(gradient.stops[2].location == 1.0)
    }

    @Test func encode_nonUniformGradient_producesDictArray() throws {
        let gradient = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x00FF00), location: 0.3),
            .init(color: Color(hex: 0x0000FF), location: 1.0),
        ])
        let encoded = try jsonEncode(gradient)
        let array = try #require(encoded as? [[String: Double]])
        #expect(array.count == 3)
        #expect(array[0]["#FF0000"] == 0.0)
        #expect(array[1]["#00FF00"] == 0.3)
        #expect(array[2]["#0000FF"] == 1.0)
    }

    @Test func roundTrip_nonUniformGradient() throws {
        let original = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x00FF00), location: 0.3),
            .init(color: Color(hex: 0x0000FF), location: 1.0),
        ])
        let decoded = try jsonRoundTrip(original)
        #expect(decoded.stops.count == 3)
        #expect(decoded.stops[1].location == 0.3)
    }

    // MARK: - hasUniformStops logic (tested via encode format)

    @Test func singleStop_encodesAsUniform() throws {
        let gradient = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.5),
        ])
        let encoded = try jsonEncode(gradient)
        // Single stop is always "uniform", encodes as color array
        #expect(encoded is [String])
    }

    @Test func twoStops_atBoundaries_encodesAsUniform() throws {
        let gradient = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x0000FF), location: 1.0),
        ])
        let encoded = try jsonEncode(gradient)
        #expect(encoded is [String])
    }

    @Test func threeStops_evenlySpaced_encodesAsUniform() throws {
        let gradient = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x00FF00), location: 0.5),
            .init(color: Color(hex: 0x0000FF), location: 1.0),
        ])
        let encoded = try jsonEncode(gradient)
        #expect(encoded is [String])
    }

    @Test func threeStops_unevenlySpaced_encodesAsNonUniform() throws {
        let gradient = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x00FF00), location: 0.3),
            .init(color: Color(hex: 0x0000FF), location: 1.0),
        ])
        let encoded = try jsonEncode(gradient)
        #expect(encoded is [[String: Double]])
    }

    @Test func fourStops_evenlySpaced_encodesAsUniform() throws {
        let gradient = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x00FF00), location: CGFloat(1.0 / 3.0)),
            .init(color: Color(hex: 0x0000FF), location: CGFloat(2.0 / 3.0)),
            .init(color: Color(hex: 0xFFFFFF), location: 1.0),
        ])
        let encoded = try jsonEncode(gradient)
        #expect(encoded is [String])
    }

    // MARK: - Edge cases

    @Test func decode_emptyStopDict_throws() {
        let json = Data("[{}]".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Gradient.self, from: json)
        }
    }

    @Test func uniformFormat_preserved_afterRoundTrip() throws {
        let uniform = Gradient(colors: [Color(hex: 0xFF0000), Color(hex: 0x0000FF)])
        let data = try JSONEncoder().encode(uniform)
        let decoded = try JSONDecoder().decode(Gradient.self, from: data)
        let reEncoded = try jsonEncode(decoded)
        #expect(reEncoded is [String], "Uniform gradient should stay in color array format after round-trip")
    }

    @Test func nonUniformFormat_preserved_afterRoundTrip() throws {
        let nonUniform = Gradient(stops: [
            .init(color: Color(hex: 0xFF0000), location: 0.0),
            .init(color: Color(hex: 0x0000FF), location: 0.7),
        ])
        let data = try JSONEncoder().encode(nonUniform)
        let decoded = try JSONDecoder().decode(Gradient.self, from: data)
        let reEncoded = try jsonEncode(decoded)
        #expect(reEncoded is [[String: Double]], "Non-uniform gradient should stay in dict format after round-trip")
    }
}
