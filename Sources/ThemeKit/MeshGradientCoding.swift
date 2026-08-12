import SwiftUI

/// The wire format for mesh gradients, shared by SwiftUI's `MeshGradient` on Apple
/// platforms and by ThemeKit's Android shim.
///
/// Both conformances route through here so the two cannot drift: one JSON shape,
/// one uniform-grid rule, one place to change either.
nonisolated enum MeshGradientCoding {

    nonisolated enum CodingKeys: String, CodingKey {
        case width, height, colors, points
    }

    nonisolated struct Payload: Sendable, Equatable {
        let width: Int
        let height: Int
        let colors: [Color]
        let points: [SIMD2<Float>]
    }

    /// Decodes the shared shape. `points` is optional on the wire — a mesh with evenly
    /// spaced control points need only declare its dimensions and colours.
    nonisolated static func decode(from decoder: Decoder) throws -> Payload {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Int.self, forKey: .width)
        let height = try container.decode(Int.self, forKey: .height)
        let colors = try container.decode([Color].self, forKey: .colors)
        let points = try container.decodeIfPresent([SIMD2<Float>].self, forKey: .points)
        return Payload(
            width: width,
            height: height,
            colors: colors,
            points: points ?? uniformPoints(width: width, height: height)
        )
    }

    /// Encodes the shared shape. `colors` is generic because SwiftUI's `MeshGradient` can
    /// hold either `[Color]` or `[Color.Resolved]`, and both encode to the same JSON.
    nonisolated static func encode<Colors: Encodable>(
        width: Int,
        height: Int,
        colors: Colors,
        points: [SIMD2<Float>],
        to encoder: Encoder
    ) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(colors, forKey: .colors)
        try container.encode(points, forKey: .points)
    }

    /// Control points spread evenly across the unit square, row-major.
    nonisolated static func uniformPoints(width: Int, height: Int) -> [SIMD2<Float>] {
        guard width > 0, height > 0 else {
            return []
        }
        if width == 1 && height == 1 {
            return [SIMD2<Float>(0.0, 0.0)]
        }
        return (0..<height).flatMap { row in
            (0..<width).map { col in
                SIMD2<Float>(
                    width > 1 ? Float(col) / Float(width - 1) : 0.0,
                    height > 1 ? Float(row) / Float(height - 1) : 0.0,
                )
            }
        }
    }
}
