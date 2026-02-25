nonisolated public enum ThemeCategory: CaseIterable, Sendable {
    case colors
    case gradients
    case meshGradients
    case shadows

    nonisolated public var structName: String {
        switch self {
        case .colors: "ThemeColors"
        case .gradients: "ThemeGradients"
        case .meshGradients: "ThemeMeshGradients"
        case .shadows: "ThemeShadows"
        }
    }

    nonisolated public var styleType: String {
        switch self {
        case .colors: "Color"
        case .gradients: "Gradient"
        case .meshGradients: "MeshGradient"
        case .shadows: "Shadow"
        }
    }

    nonisolated public var propertyName: String {
        switch self {
        case .colors: "colors"
        case .gradients: "gradients"
        case .meshGradients: "meshGradients"
        case .shadows: "shadows"
        }
    }

    nonisolated public func tokens(from config: ThemeConfig) -> [ThemeToken] {
        switch self {
        case .colors: config.colors ?? []
        case .gradients: config.gradients ?? []
        case .meshGradients: config.meshGradients ?? []
        case .shadows: config.shadows ?? []
        }
    }
}
