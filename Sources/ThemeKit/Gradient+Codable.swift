import SwiftUI

nonisolated extension Gradient: @retroactive Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let colors = try? container.decode([Color].self) {
            self = .init(colors: colors)
        } else {
            let stopDicts = try container.decode([[String: CGFloat]].self)
            let pairs = try stopDicts.map { dict -> (hex: String, location: CGFloat) in
                guard let (hex, location) = dict.first else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Empty stop entry"
                    )
                }
                return (hex, location)
            }
#if os(Android)
            // SkipFuseUI's Gradient.Stop has no public initializer; build the
            // gradient from colors, then overwrite the public stop locations.
            var gradient = Gradient(colors: pairs.map { Color(hex: $0.hex) })
            for (index, pair) in pairs.enumerated() {
                gradient.stops[index].location = pair.location
            }
            self = gradient
#else
            self = .init(stops: pairs.map { Stop(color: Color(hex: $0.hex), location: $0.location) })
#endif
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
