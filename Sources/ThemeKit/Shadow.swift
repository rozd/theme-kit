import SwiftUI

public enum Shadow: Sendable, Codable {
    case none
    case drop(color: Color? = nil, radius: CGFloat, x: CGFloat = 0.0, y: CGFloat = 0.0)
    case inner(color: Color? = nil, radius: CGFloat, x: CGFloat = 0.0, y: CGFloat = 0.0)
}

public extension Shadow {

    var shadowStyle: ShadowStyle? {
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

    public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        guard let style = shadowStyle else {
            return AnyShapeStyle(.clear)
        }
        return AnyShapeStyle(.shadow(style))
    }
}
