import Foundation

public struct AdaptiveProfile: Equatable, Hashable, Sendable {
    public enum Scope: Equatable, Hashable, Sendable {
        case senderAddress(String)
        case pattern(String)
        case room(RoomID)
        case global
    }

    public struct Weight: Equatable, Hashable, Sendable, Codable {
        public let rawValue: Double

        public init?(_ rawValue: Double) {
            guard (-1.0...1.0).contains(rawValue) else {
                return nil
            }

            self.rawValue = rawValue
        }

        public static func clamped(_ rawValue: Double) -> Weight {
            let boundedValue = min(max(rawValue, -1.0), 1.0)
            return Weight(boundedValue)!
        }

        public static let neutral = Weight(0.0)!
        public static let maximum = Weight(1.0)!
        public static let minimum = Weight(-1.0)!
    }

    public enum Tendency: Equatable, Hashable, Sendable {
        case messageKindBias(MessageKind, weight: Weight)
        case blockKindBias(BlockInterpretation.Kind, weight: Weight)
        case entityKindBias(EntityKind, weight: Weight)
        case actionKindBias(ActionKind, weight: Weight)
        case assignmentRoomBias(RoomID, weight: Weight)
        case collapseBias(weight: Weight)
        case elevateBias(weight: Weight)
        case suppressBias(weight: Weight)
    }

    public struct DecayMetadata: Equatable, Hashable, Sendable {
        public let lastUpdatedAt: Date
        public let decayRate: Double?

        public init(
            lastUpdatedAt: Date,
            decayRate: Double? = nil
        ) {
            self.lastUpdatedAt = lastUpdatedAt
            self.decayRate = decayRate
        }
    }

    public let id: AdaptiveProfileID
    public let scope: Scope
    public let tendencies: [Tendency]
    public let evidenceCount: Int
    public let decayMetadata: DecayMetadata

    public init(
        id: AdaptiveProfileID = AdaptiveProfileID(),
        scope: Scope,
        tendencies: [Tendency],
        evidenceCount: Int,
        decayMetadata: DecayMetadata
    ) {
        self.id = id
        self.scope = scope
        self.tendencies = tendencies
        self.evidenceCount = evidenceCount
        self.decayMetadata = decayMetadata
    }
}
