public enum ThemeCategory: CaseIterable, Sendable {
    case colors
    case gradients
    case shadows

    public var structName: String {
        switch self {
        case .colors: "ThemeColors"
        case .gradients: "ThemeGradients"
        case .shadows: "ThemeShadows"
        }
    }

    public var styleType: String {
        switch self {
        case .colors: "Color"
        case .gradients: "Gradient"
        case .shadows: "Shadow"
        }
    }

    public var propertyName: String {
        switch self {
        case .colors: "colors"
        case .gradients: "gradients"
        case .shadows: "shadows"
        }
    }

    public func tokens(from config: ThemeConfig) -> [ThemeToken] {
        switch self {
        case .colors: config.colors ?? []
        case .gradients: config.gradients ?? []
        case .shadows: config.shadows ?? []
        }
    }
}
