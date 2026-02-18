import SwiftUI

extension Gradient: @retroactive Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let colors = try? container.decode([Color].self) {
            self = .init(colors: colors)
        } else {
            let stopDicts = try container.decode([[String: CGFloat]].self)
            let stops = try stopDicts.map { dict in
                guard let (hex, location) = dict.first else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Empty stop entry"
                    )
                }
                return Stop(color: Color(hex: hex), location: location)
            }
            self = .init(stops: stops)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if hasUniformStops {
            try container.encode(stops.map { $0.color })
        } else {
            let stopDicts = try stops.map { stop -> [String: CGFloat] in
                [try stop.color.hexString: stop.location]
            }
            try container.encode(stopDicts)
        }
    }

    private var hasUniformStops: Bool {
        let count = stops.count
        guard count > 1 else { return true }
        for (i, stop) in stops.enumerated() {
            let expected = CGFloat(i) / CGFloat(count - 1)
            if abs(stop.location - expected) > 0.001 {
                return false
            }
        }
        return true
    }
}
