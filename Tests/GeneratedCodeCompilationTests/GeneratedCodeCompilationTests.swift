import Testing
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
}
