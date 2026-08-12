import Foundation
import SwiftUI

extension Color {

    /// Creates a colour from a packed `0xRRGGBB` value, remembering the hex it came from.
    ///
    /// Prefer this over `Color(red:green:blue:)` when authoring theme defaults: a colour built
    /// this way records its canonical `#RRGGBB` spelling at construction, which is what makes
    /// `hexString` — and therefore encoding the theme to JSON — work on Android, where no colour
    /// introspection exists. On Apple platforms it additionally makes encoding byte-exact rather
    /// than round-tripping through a colour space.
    nonisolated public init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
        )
        Color.hexCache.store(Color.canonicalHex(hex), for: self)
    }

    /// Creates a colour from a `#RRGGBB` or `RRGGBB` string, remembering the hex it came from.
    ///
    /// Unparseable input yields black rather than failing; the same encodability contract as
    /// ``init(hex:)-(Int)`` applies.
    nonisolated public init(hex string: String) {
        let hex = string.hasPrefix("#") ? String(string.dropFirst()) : string
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(hex: Int(value))
    }

    /// The colour's `#RRGGBB` spelling.
    ///
    /// Resolves in two ways, in order: colours constructed through `Color(hex:)` return their
    /// recorded spelling exactly; everything else is introspected via UIKit/AppKit. Android has
    /// no introspection path, so a colour that never passed through `Color(hex:)` throws
    /// ``HexCodingError/rgbExtractionFailed`` there — as do Apple catalog colours with no RGB
    /// components.
    nonisolated public var hexString: String {
        get throws {
            // Colours built from a hex value know their exact serialized form. This is
            // the only path that works on Android, and on Apple it is more accurate than
            // introspection, which round-trips through a colour space.
            if let cached = Color.hexCache.value(for: self) {
                return cached
            }
#if canImport(UIKit)
            let color = UIColor(self)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else {
                throw HexCodingError.rgbExtractionFailed
            }
#elseif canImport(AppKit)
            // Catalog colours (Color.red and friends) have no RGB components until they
            // are converted; calling getRed on one raises an ObjC exception, which would
            // abort the process rather than throw.
            guard let color = NSColor(self).usingColorSpace(.sRGB) else {
                throw HexCodingError.rgbExtractionFailed
            }
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
#else
            // No RGB component extraction is available on this platform
            // (SkipFuseUI's Color on Android exposes no resolved components), so only
            // colours that passed through Color(hex:) can be encoded here.
            throw HexCodingError.rgbExtractionFailed
#endif

#if canImport(UIKit) || canImport(AppKit)
            return String(format: "#%02X%02X%02X",
                          Int(r * 255),
                          Int(g * 255),
                          Int(b * 255))
#endif
        }
    }

    /// The canonical `#RRGGBB` spelling of a hex value, by integer maths only.
    nonisolated static func canonicalHex(_ hex: Int) -> String {
        String(format: "#%02X%02X%02X",
               (hex >> 16) & 0xFF,
               (hex >> 8) & 0xFF,
               hex & 0xFF)
    }
}

extension Color {
    /// Why ``Color/hexString`` could not produce a spelling for a colour.
    nonisolated public enum HexCodingError: Error {
        /// The colour has no readable RGB components and was not built through `Color(hex:)`.
        case rgbExtractionFailed
    }
}

// MARK: - Hex cache

extension Color {

    /// Remembers the hex a colour was constructed from, so encoding can reproduce it
    /// exactly — and can work at all on platforms with no colour introspection.
    ///
    /// Keying by `Color` is sound because `Color` is `Hashable` by value on every
    /// supported platform, including SkipFuseUI, whose `Color` hashes over a value-typed
    /// component spec. Copies of a cached colour therefore still hit.
    nonisolated static let hexCache = HexCache()

    nonisolated final class HexCache: @unchecked Sendable {

        /// Themes hold a bounded number of distinct colours, but an app decoding a stream
        /// of remote themes would otherwise grow this forever, so entries are capped and
        /// evicted oldest-first.
        private let capacity = 512

        private let lock = NSLock()
        private var entries: [Color: String] = [:]
        private var order: [Color] = []

        nonisolated func value(for color: Color) -> String? {
            lock.lock()
            defer { lock.unlock() }
            return entries[color]
        }

        nonisolated func store(_ hex: String, for color: Color) {
            lock.lock()
            defer { lock.unlock() }
            guard entries.updateValue(hex, forKey: color) == nil else {
                return
            }
            order.append(color)
            if order.count > capacity {
                let evicted = order.removeFirst()
                entries.removeValue(forKey: evicted)
            }
        }
    }
}
