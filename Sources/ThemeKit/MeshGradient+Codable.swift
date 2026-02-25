import SwiftUI

nonisolated extension MeshGradient {

    public init(
        width: Int,
        height: Int,
        colors: [Color]
    ) {
        self.init(
            width: width,
            height: height,
            points: MeshGradient.pointsFrom(width: width, height: height),
            colors: colors,
        )
    }
}

// MARK: - Codable

nonisolated extension MeshGradient: @retroactive Codable {

    enum CodingKeys: String, CodingKey {
        case width, height, colors, points
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Int.self, forKey: .width)
        let height = try container.decode(Int.self, forKey: .height)
        let colors = try container.decode([Color].self, forKey: .colors)
        let points = try container.decodeIfPresent([SIMD2<Float>].self, forKey: .points)
        self.init(
            width: width,
            height: height,
            points: points ?? MeshGradient.pointsFrom(width: width, height: height),
            colors: colors,
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)

        switch colors {
        case .colors(let colors):
            try container.encode(colors, forKey: .colors)
        case .resolvedColors(let colors):
            try container.encode(colors, forKey: .colors)
        @unknown default:
            throw EncodingError.invalidValue(
                colors,
                EncodingError.Context(
                    codingPath: [CodingKeys.colors],
                    debugDescription: "Unsupported color type",
                )
            )
        }

        switch locations {
        case .points(let points):
            try container.encode(points, forKey: .points)
        case .bezierPoints(let points):
            try container.encode(points.map(\.position), forKey: .points)
        @unknown default:
            throw EncodingError.invalidValue(
                locations,
                EncodingError.Context(
                    codingPath: [CodingKeys.points],
                    debugDescription: "Unsupported location type",
                )
            )
        }

    }

    static func pointsFrom(width: Int, height: Int) -> [SIMD2<Float>] {
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
