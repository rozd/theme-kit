import Foundation
import SwiftUI

extension Color {

    nonisolated init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
        )
        Color.hexCache.store(Color.canonicalHex(hex), for: self)
    }

    nonisolated init(hex string: String) {
        let hex = string.hasPrefix("#") ? String(string.dropFirst()) : string
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(hex: Int(value))
    }

    nonisolated var hexString: String {
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
    nonisolated enum HexCodingError: Error {
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
