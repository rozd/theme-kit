import Testing
import SwiftUI
import GeneratedCodeSwift5
import GeneratedCodeSwift5MainActor
import GeneratedCodeSwift6
import GeneratedCodeSwift6MainActor

/// Verifies that ThemeKit-generated code compiles under all 4 combinations
/// of Swift language mode (5/6) and default actor isolation (nonisolated/MainActor).
///
/// The primary verification is compilation itself — if these targets build, the
/// generated code is compatible with that configuration. The tests below perform
/// minimal runtime checks to confirm the types are usable.
@Suite("Generated Code Compilation")
struct GeneratedCodeCompilationTests {

    @Test func swift5_typesAreUsable() {
        let theme = GeneratedCodeSwift5.Theme.default
        _ = theme.colors.surface
        _ = theme.gradients.primary
        _ = theme.meshGradients.aurora
        _ = theme.shadows.card
    }

    @Test func swift5MainActor_typesAreUsable() {
        let theme = GeneratedCodeSwift5MainActor.Theme.default
        _ = theme.colors.surface
        _ = theme.gradients.primary
        _ = theme.meshGradients.aurora
        _ = theme.shadows.card
    }

    @Test func swift6_typesAreUsable() {
        let theme = GeneratedCodeSwift6.Theme.default
        _ = theme.colors.surface
        _ = theme.gradients.primary
        _ = theme.meshGradients.aurora
        _ = theme.shadows.card
    }

    @Test func swift6MainActor_typesAreUsable() {
        let theme = GeneratedCodeSwift6MainActor.Theme.default
        _ = theme.colors.surface
        _ = theme.gradients.primary
        _ = theme.meshGradients.aurora
        _ = theme.shadows.card
    }

    // MARK: - Sendability

    /// Requires its argument to be `Sendable`. Calls fail to compile if the
    /// generated style types lose their `Sendable` conformance.
    private func requireSendable<T: Sendable>(_ value: T) -> T { value }

    /// The generated style types store a `KeyPath` into `Theme` and must be
    /// `Sendable` on their own — ThemeKit intentionally ships no retroactive
    /// `KeyPath: Sendable` conformance, which would leak into every consumer
    /// and conflict with libraries that manage key-path sendability themselves.
    @Test func generatedStyles_areSendable() {
        _ = requireSendable(GeneratedCodeSwift5.ThemeShapeStyle(keyPath: \.colors.surface))
        _ = requireSendable(GeneratedCodeSwift5MainActor.ThemeShapeStyle(keyPath: \.colors.surface))
        _ = requireSendable(GeneratedCodeSwift6.ThemeShapeStyle(keyPath: \.colors.surface))
        _ = requireSendable(GeneratedCodeSwift6MainActor.ThemeShapeStyle(keyPath: \.colors.surface))

        _ = requireSendable(GeneratedCodeSwift5.ThemeShadowedStyle(base: Color.red, shadowKeyPath: \.shadows.card))
        _ = requireSendable(GeneratedCodeSwift5MainActor.ThemeShadowedStyle(base: Color.red, shadowKeyPath: \.shadows.card))
        _ = requireSendable(GeneratedCodeSwift6.ThemeShadowedStyle(base: Color.red, shadowKeyPath: \.shadows.card))
        _ = requireSendable(GeneratedCodeSwift6MainActor.ThemeShadowedStyle(base: Color.red, shadowKeyPath: \.shadows.card))
    }

    /// Generated styles must survive a hop across an actor boundary.
    @Test func generatedStyles_canCrossActorBoundary() async {
        let style = GeneratedCodeSwift6.ThemeShapeStyle(keyPath: \.colors.surface)
        let shadowed = GeneratedCodeSwift6MainActor.ThemeShadowedStyle(base: Color.red, shadowKeyPath: \.shadows.card)

        await Task { @Sendable in
            _ = style
            _ = shadowed
        }.value
    }
}
