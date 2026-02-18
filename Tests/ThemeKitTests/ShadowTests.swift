import Testing
import SwiftUI
import Foundation
@testable import ThemeKit

@Suite("Shadow")
struct ShadowTests {

    // MARK: - Helpers

    private func jsonRoundTrip(_ value: Shadow) throws -> Shadow {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(Shadow.self, from: data)
    }

    // MARK: - Codable: .none

    @Test func codable_none() throws {
        let decoded = try jsonRoundTrip(.none)
        if case .none = decoded {} else {
            Issue.record("Expected .none, got \(decoded)")
        }
    }

    // MARK: - Codable: .drop

    @Test func codable_drop_fullParams() throws {
        let original = Shadow.drop(color: Color(hex: 0x000000), radius: 4, x: 1, y: 2)
        let decoded = try jsonRoundTrip(original)
        if case .drop(let color, let radius, let x, let y) = decoded {
            #expect(try color?.hexString == "#000000")
            #expect(radius == 4)
            #expect(x == 1)
            #expect(y == 2)
        } else {
            Issue.record("Expected .drop, got \(decoded)")
        }
    }

    @Test func codable_drop_minimalParams() throws {
        let original = Shadow.drop(radius: 5)
        let decoded = try jsonRoundTrip(original)
        if case .drop(let color, let radius, let x, let y) = decoded {
            #expect(color == nil)
            #expect(radius == 5)
            #expect(x == 0)
            #expect(y == 0)
        } else {
            Issue.record("Expected .drop, got \(decoded)")
        }
    }

    @Test func codable_drop_withColor_noOffset() throws {
        let original = Shadow.drop(color: Color(hex: 0xFF0000), radius: 10)
        let decoded = try jsonRoundTrip(original)
        if case .drop(let color, let radius, let x, let y) = decoded {
            #expect(try color?.hexString == "#FF0000")
            #expect(radius == 10)
            #expect(x == 0)
            #expect(y == 0)
        } else {
            Issue.record("Expected .drop, got \(decoded)")
        }
    }

    // MARK: - Codable: .inner

    @Test func codable_inner_fullParams() throws {
        let original = Shadow.inner(color: Color(hex: 0xABCDEF), radius: 6, x: 3, y: 4)
        let decoded = try jsonRoundTrip(original)
        if case .inner(let color, let radius, let x, let y) = decoded {
            #expect(try color?.hexString == "#ABCDEF")
            #expect(radius == 6)
            #expect(x == 3)
            #expect(y == 4)
        } else {
            Issue.record("Expected .inner, got \(decoded)")
        }
    }

    @Test func codable_inner_minimalParams() throws {
        let original = Shadow.inner(radius: 3)
        let decoded = try jsonRoundTrip(original)
        if case .inner(let color, let radius, let x, let y) = decoded {
            #expect(color == nil)
            #expect(radius == 3)
            #expect(x == 0)
            #expect(y == 0)
        } else {
            Issue.record("Expected .inner, got \(decoded)")
        }
    }

    // MARK: - shadowStyle property

    @Test func shadowStyle_none_returnsNil() {
        #expect(Shadow.none.shadowStyle == nil)
    }

    @Test func shadowStyle_drop_withColor_returnsDropStyle() {
        let shadow = Shadow.drop(color: Color(hex: 0x000000), radius: 4, x: 0, y: 2)
        #expect(shadow.shadowStyle != nil)
    }

    @Test func shadowStyle_drop_withoutColor_returnsDropStyle() {
        let shadow = Shadow.drop(radius: 4, x: 0, y: 2)
        #expect(shadow.shadowStyle != nil)
    }

    @Test func shadowStyle_inner_withColor_returnsInnerStyle() {
        let shadow = Shadow.inner(color: Color(hex: 0x000000), radius: 4, x: 0, y: 2)
        #expect(shadow.shadowStyle != nil)
    }

    @Test func shadowStyle_inner_withoutColor_returnsInnerStyle() {
        let shadow = Shadow.inner(radius: 4, x: 0, y: 2)
        #expect(shadow.shadowStyle != nil)
    }

    // MARK: - ShapeStyle resolve (smoke test)

    @Test func shapeStyleResolve_none_doesNotCrash() {
        let env = EnvironmentValues()
        let _ = Shadow.none.resolve(in: env)
    }

    @Test func shapeStyleResolve_drop_doesNotCrash() {
        let env = EnvironmentValues()
        let _ = Shadow.drop(color: Color(hex: 0x000000), radius: 4).resolve(in: env)
    }

    @Test func shapeStyleResolve_inner_doesNotCrash() {
        let env = EnvironmentValues()
        let _ = Shadow.inner(radius: 4).resolve(in: env)
    }
}
