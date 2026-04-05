import Foundation

public struct Confidence: Equatable, Hashable, Sendable, Codable {
    public let rawValue: Double

    public init?(_ rawValue: Double) {
        guard (0.0...1.0).contains(rawValue) else {
            return nil
        }

        self.rawValue = rawValue
    }

    public static func clamped(_ rawValue: Double) -> Confidence {
        let boundedValue = min(max(rawValue, 0.0), 1.0)
        return Confidence(boundedValue)!
    }

    public func adjusted(by delta: Double) -> Confidence {
        Confidence.clamped(rawValue + delta)
    }

    public static let zero = Confidence(0.0)!
    public static let half = Confidence(0.5)!
    public static let full = Confidence(1.0)!
}
