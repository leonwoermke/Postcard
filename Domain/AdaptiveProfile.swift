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

    public struct DecayRate: Equatable, Hashable, Sendable, Codable {
        /// Bounded to (0.0, 1.0]. A rate of 1.0 means no decay.
        /// A rate approaching 0.0 means rapid decay.
        public let rawValue: Double

        public init?(_ rawValue: Double) {
            guard rawValue > 0.0 && rawValue <= 1.0 else {
                return nil
            }
            self.rawValue = rawValue
        }

        public static func clamped(_ rawValue: Double) -> DecayRate {
            let boundedValue = min(max(rawValue, Double.leastNormalMagnitude), 1.0)
            return DecayRate(boundedValue)!
        }

        public static let none = DecayRate(1.0)!
        public static let slow = DecayRate(0.95)!
        public static let moderate = DecayRate(0.75)!
        public static let fast = DecayRate(0.5)!
    }

    public enum BlockKindBias: Equatable, Hashable, Sendable {
        case primaryContent
        case supportingContent
        case quote
        case signatureLike
        case tabular
        case actionCluster
        case boilerplate
        case unknown
        case other(String)
    }

    public enum Tendency: Equatable, Hashable, Sendable {
        case messageKindBias(MessageKind, weight: Weight)
        case blockKindBias(BlockKindBias, weight: Weight)
        case entityKindBias(EntityKind, weight: Weight)
        case actionKindBias(ActionKind, weight: Weight)
        case assignmentRoomBias(RoomID, weight: Weight)
        case collapseBias(weight: Weight)
        case elevateBias(weight: Weight)
        case suppressBias(weight: Weight)
    }

    public struct DecayMetadata: Equatable, Hashable, Sendable {
        public let lastUpdatedAt: Date
        public let decayRate: DecayRate?

        public init(
            lastUpdatedAt: Date,
            decayRate: DecayRate? = nil
        ) {
            self.lastUpdatedAt = lastUpdatedAt
            self.decayRate = decayRate
        }
    }

    public let id: AdaptiveProfileID
    public let accountID: AccountID
    public let scope: Scope
    public let tendencies: [Tendency]
    public let evidenceCount: Int
    public let decayMetadata: DecayMetadata

    public init(
        id: AdaptiveProfileID = AdaptiveProfileID(),
        accountID: AccountID,
        scope: Scope,
        tendencies: [Tendency],
        evidenceCount: Int,
        decayMetadata: DecayMetadata
    ) {
        self.id = id
        self.accountID = accountID
        self.scope = scope
        self.tendencies = tendencies
        self.evidenceCount = evidenceCount
        self.decayMetadata = decayMetadata
    }
}

