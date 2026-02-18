import SwiftUI

extension ThemeAdaptiveStyle: ShapeStyle where Style: ShapeStyle {
    nonisolated public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        resolved(for: environment.colorScheme)
    }
}
