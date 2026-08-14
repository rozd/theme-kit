// The THEMEKIT_MESH_UPSTREAM side of the mesh gradient gate: compiled instead of the
// MeshGradient+Android.swift shim when building against a skip-fuse-ui that ships the real
// MeshGradient (the local fork today; a release later). It gives the upstream type the same
// ThemeKit surface the shim has — the uniform-grid convenience initializer, the shared JSON
// wire format via MeshGradientCoding, and the Android render hook.
#if os(Android) && THEMEKIT_MESH_UPSTREAM
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
        try MeshGradientCoding.encode(
            width: width, height: height, colors: colors, points: points, to: encoder
        )
    }
}

// MARK: - Rendering

extension MeshGradient: AndroidResolvableStyle {

    /// The real mesh: SkipFuseUI's MeshGradient renders through skip-ui's AGSL shader on
    /// API 33+ and degrades to a two-stop gradient below that on its own.
    nonisolated public var androidResolvedStyle: AndroidResolvedStyle {
        return .style(AnyShapeStyle(self))
    }
}
#endif
