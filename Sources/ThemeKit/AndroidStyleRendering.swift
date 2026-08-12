// SkipFuseUI's `ShapeStyle` has no `resolve(in:)` customization point, so a theme
// token cannot render itself on Android. Instead the generated modifier overloads
// resolve a token to its concrete value and ask it, through this protocol, how it
// wants to be drawn with the primitives SkipFuseUI does provide.
#if os(Android)
import SwiftUI

/// A drop shadow, in the form `View.shadow(color:radius:x:y:)` takes.
nonisolated public struct AndroidShadow: Sendable, Equatable {
    public var color: Color?
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat

    nonisolated public init(color: Color?, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// How a resolved token value is rendered on Android.
///
/// Both fields are optional and independent, because a shadowed style
/// (`.surface.cardShadow`) contributes a fill *and* a shadow, while a plain colour
/// contributes only a fill and a shadow token only a shadow. A value with neither
/// renders the content unstyled — which is also what an unrepresentable token
/// (an inner shadow, a custom `Resolver`) resolves to.
nonisolated public struct AndroidStyleRendering: Sendable {

    public var shapeStyle: AnyShapeStyle?
    public var shadow: AndroidShadow?

    nonisolated public init(shapeStyle: AnyShapeStyle? = nil, shadow: AndroidShadow? = nil) {
        self.shapeStyle = shapeStyle
        self.shadow = shadow
    }

    /// Nothing to draw: the token has no Android equivalent, or could not resolve.
    nonisolated public static let unsupported = AndroidStyleRendering()

    nonisolated public static func style(_ shapeStyle: AnyShapeStyle) -> AndroidStyleRendering {
        AndroidStyleRendering(shapeStyle: shapeStyle)
    }

    nonisolated public static func shadow(_ shadow: AndroidShadow) -> AndroidStyleRendering {
        AndroidStyleRendering(shadow: shadow)
    }

    /// Composes a shadow onto this style, for `.surface.cardShadow` chaining.
    nonisolated public func adding(_ shadow: AndroidShadow?) -> AndroidStyleRendering {
        AndroidStyleRendering(shapeStyle: shapeStyle, shadow: shadow ?? self.shadow)
    }
}

/// A token value that knows how to render itself on Android.
///
/// Conformances live in ThemeKit rather than in generated code because the mapping
/// depends only on the value type, never on an app's theme configuration.
nonisolated public protocol AndroidRenderableStyle {
    var androidRendering: AndroidStyleRendering { get }
}

// MARK: - Conformances

extension Color: AndroidRenderableStyle {
    nonisolated public var androidRendering: AndroidStyleRendering {
        .style(AnyShapeStyle(self))
    }
}

extension Gradient: AndroidRenderableStyle {
    // SkipFuseUI's `Gradient` is plain data — only `AnyGradient` conforms to
    // `ShapeStyle`. Its bridged form is a top-to-bottom `LinearGradient`, which is
    // what SwiftUI's own `Gradient: ShapeStyle` conformance draws on Apple.
    nonisolated public var androidRendering: AndroidStyleRendering {
        .style(AnyShapeStyle(AnyGradient(self)))
    }
}

extension Shadow: AndroidRenderableStyle {
    // Inner shadows have no `View.shadow` equivalent; they need either the
    // `composeModifier` escape hatch or upstream `ShadowStyle` support, so they
    // render as nothing rather than as a wrong-looking drop shadow.
    nonisolated public var androidRendering: AndroidStyleRendering {
        switch self {
        case .drop(let color, let radius, let x, let y):
            return .shadow(AndroidShadow(color: color, radius: radius, x: x, y: y))
        case .inner, .none:
            return .unsupported
        }
    }
}
#endif
