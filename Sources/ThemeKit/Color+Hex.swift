import SwiftUI

extension Color {

    nonisolated init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
        )
    }

    nonisolated init(hex string: String) {
        let hex = string.hasPrefix("#") ? String(string.dropFirst()) : string
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(hex: Int(value))
    }

    nonisolated var hexString: String {
        get throws {
#if canImport(UIKit)
            let color = UIColor(self)
#elseif canImport(AppKit)
            let color = NSColor(self)
#endif
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

#if canImport(UIKit)
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else {
                throw HexCodingError.rgbExtractionFailed
            }
#else
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif

            return String(format: "#%02X%02X%02X",
                          Int(r * 255),
                          Int(g * 255),
                          Int(b * 255))
        }
    }
}

extension Color {
    nonisolated enum HexCodingError: Error {
        case rgbExtractionFailed
    }
}
