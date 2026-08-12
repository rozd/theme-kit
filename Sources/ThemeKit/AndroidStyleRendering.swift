// SkipFuseUI's `ShapeStyle` has no `resolve(in:)` customization point, so a theme
// token cannot render itself on Android. Instead the generated modifier overloads
// resolve a token to its concrete value and ask it, through this protocol, how it
// wants to be drawn with the primitives SkipFuseUI does provide.
#if os(Android)
import SwiftUI

/// The Android rendering strategy for a resolved token value.
///
/// The cases mirror the two distinct primitives SkipFuseUI offers: styles that can
/// be handed to a `ShapeStyle`-taking modifier, and shadows, which are a view
/// modifier rather than a style there.
nonisolated public enum AndroidStyleRendering: Sendable {

    /// Render by passing this style to a `ShapeStyle`-taking modifier.
    case shapeStyle(AnyShapeStyle)

    /// Render by applying `View.shadow(color:radius:x:y:)` to the content.
    case shadow(color: Color?, radius: CGFloat, x: CGFloat, y: CGFloat)

    /// No Android equivalent exists; content renders unstyled.
    case unsupported
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
        .shapeStyle(AnyShapeStyle(self))
    }
}

extension Gradient: AndroidRenderableStyle {
    // SkipFuseUI's `Gradient` is plain data — only `AnyGradient` conforms to
    // `ShapeStyle`. Its bridged form is a top-to-bottom `LinearGradient`, which is
    // what SwiftUI's own `Gradient: ShapeStyle` conformance draws on Apple.
    nonisolated public var androidRendering: AndroidStyleRendering {
        .shapeStyle(AnyShapeStyle(AnyGradient(self)))
    }
}

extension Shadow: AndroidRenderableStyle {
    // Inner shadows have no `View.shadow` equivalent; they need either the
    // `composeModifier` escape hatch or upstream `ShadowStyle` support.
    nonisolated public var androidRendering: AndroidStyleRendering {
        switch self {
        case .drop(let color, let radius, let x, let y):
            return .shadow(color: color, radius: radius, x: x, y: y)
        case .inner, .none:
            return .unsupported
        }
    }
}
#endif
