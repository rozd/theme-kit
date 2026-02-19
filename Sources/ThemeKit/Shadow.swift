import SwiftUI

nonisolated public enum Shadow: Sendable, Codable, Equatable {
    case none
    case drop(color: Color?, radius: CGFloat, x: CGFloat = 0.0, y: CGFloat = 0.0)
    case inner(color: Color?, radius: CGFloat, x: CGFloat = 0.0, y: CGFloat = 0.0)

    public static func drop(radius: CGFloat, x: CGFloat = 0.0, y: CGFloat = 0.0) -> Shadow {
        .drop(color: nil, radius: radius, x: x, y: y)
    }

    public static func inner(radius: CGFloat, x: CGFloat = 0.0, y: CGFloat = 0.0) -> Shadow {
        .inner(color: nil, radius: radius, x: x, y: y)
    }
}

public extension Shadow {

    nonisolated var shadowStyle: ShadowStyle? {
        switch self {
        case .none:
            return nil
        case .drop(let color, let radius, let x, let y):
            if let color {
                return .drop(color: color, radius: radius, x: x, y: y)
            } else {
                return .drop(radius: radius, x: x, y: y)
            }
        case .inner(let color, let radius, let x, let y):
            if let color {
                return .inner(color: color, radius: radius, x: x, y: y)
            } else {
                return .inner(radius: radius, x: x, y: y)
            }
        }
    }

}

// MARK: - ShapeStyle

extension Shadow: ShapeStyle {

    nonisolated public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        guard let style = shadowStyle else {
            return AnyShapeStyle(.clear)
        }
        return AnyShapeStyle(.shadow(style))
    }
}
