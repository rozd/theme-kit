// SkipFuseUI's SwiftUI facade has no MeshGradient, which would make any theme config
// using the `meshGradients` category fail to compile on Android — the generated root
// `Theme` struct references the type directly. This shim keeps such configs portable:
// mesh tokens carry their data faithfully and render in a degraded form until real mesh
// support lands (Skip has none today).
//
// THEMEKIT_MESH_UPSTREAM swaps this shim for the real MeshGradient in the skip-fuse-ui
// fork (see MeshGradient+AndroidUpstream.swift) — the two declare the same type name, so
// exactly one side compiles.
#if os(Android) && !THEMEKIT_MESH_UPSTREAM
import SwiftUI

nonisolated public struct MeshGradient: Sendable, Equatable {

    public let width: Int
    public let height: Int
    /// Control points in the unit square, row-major.
    public let points: [SIMD2<Float>]
    /// Colours at the control points, row-major.
    public let colors: [Color]

    nonisolated public init(
        width: Int,
        height: Int,
        points: [SIMD2<Float>],
        colors: [Color]
    ) {
        self.width = width
        self.height = height
        self.points = points
        self.colors = colors
    }

    nonisolated public init(
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

nonisolated extension MeshGradient: Codable {

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

extension MeshGradient: AndroidRenderableStyle {

    /// A diagonal two-stop gradient between the mesh's first and last colours.
    ///
    /// Deliberately degraded and deliberately honest: Compose can only approximate a mesh
    /// below API 33, and blending intermediate colours is impossible here anyway —
    /// SkipFuseUI's `Color` exposes no components to interpolate.
    nonisolated public var androidRendering: AndroidStyleRendering {
        guard let first = colors.first, let last = colors.last else {
            return .unsupported
        }
        return .style(AnyShapeStyle(
            LinearGradient(
                colors: [first, last],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ))
    }
}
#endif
