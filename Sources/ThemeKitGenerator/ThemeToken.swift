import Foundation

nonisolated public struct ThemeToken: Sendable, Equatable {
    public let name: String
    public let style: String

    nonisolated public init(name: String, style: String) {
        self.name = name
        self.style = style
    }
}

extension ThemeToken: Decodable {
    nonisolated public init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let string = try? singleValue.decode(String.self) {
            self.name = string
            self.style = string
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.style = try container.decode(String.self, forKey: .style)
        }
    }
}

extension ThemeToken: Encodable {
    nonisolated public func encode(to encoder: Encoder) throws {
        if name == style {
            var container = encoder.singleValueContainer()
            try container.encode(name)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(style, forKey: .style)
        }
    }
}

private extension ThemeToken {
    nonisolated enum CodingKeys: String, CodingKey {
        case name, style
    }
}
