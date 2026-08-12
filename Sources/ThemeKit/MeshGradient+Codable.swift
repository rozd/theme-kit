import SwiftUI

// MeshGradient is not available in SkipFuseUI's SwiftUI facade on Android; ThemeKit
// ships a shim there (MeshGradient+Android.swift) that shares this JSON format via
// MeshGradientCoding.
#if !os(Android)

nonisolated extension MeshGradient {

    public init(
        width: Int,
        height: Int,
        colors: [Color]
    ) {
        self.init(
            width: width,
            height: height,
            points: MeshGradientCoding.uniformPoints(width: width, height: height),
            colors: colors,
        )
    }
}

// MARK: - Codable

nonisolated extension MeshGradient: @retroactive Codable {

    public init(from decoder: Decoder) throws {
        let payload = try MeshGradientCoding.decode(from: decoder)
        self.init(
            width: payload.width,
            height: payload.height,
            points: payload.points,
            colors: payload.colors,
        )
    }

    public func encode(to encoder: Encoder) throws {
        let points: [SIMD2<Float>]
        switch locations {
        case .points(let value):
            points = value
        case .bezierPoints(let value):
            // Only the positions survive; bezier control points have no wire form.
            points = value.map(\.position)
        @unknown default:
            throw EncodingError.invalidValue(
                locations,
                EncodingError.Context(
                    codingPath: [MeshGradientCoding.CodingKeys.points],
                    debugDescription: "Unsupported location type",
                )
            )
        }

        switch colors {
        case .colors(let value):
            try MeshGradientCoding.encode(
                width: width, height: height, colors: value, points: points, to: encoder
            )
        case .resolvedColors(let value):
            try MeshGradientCoding.encode(
                width: width, height: height, colors: value, points: points, to: encoder
            )
        @unknown default:
            throw EncodingError.invalidValue(
                colors,
                EncodingError.Context(
                    codingPath: [MeshGradientCoding.CodingKeys.colors],
                    debugDescription: "Unsupported color type",
                )
            )
        }
    }
}

#endif
