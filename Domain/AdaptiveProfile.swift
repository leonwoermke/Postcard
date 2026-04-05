import Foundation

public struct AdaptiveProfile: Equatable, Hashable, Sendable {
    public enum Scope: Equatable, Hashable, Sendable {
        case senderAddress(String)
        case pattern(String)
        case room(RoomID)
        case global
    }

    public enum Tendency: Equatable, Hashable, Sendable {
        case messageKindBias(MessageKind, weight: Double)
        case blockKindBias(BlockInterpretation.Kind, weight: Double)
        case entityKindBias(EntityKind, weight: Double)
        case actionKindBias(ActionKind, weight: Double)
        case assignmentRoomBias(RoomID, weight: Double)
        case collapseBias(weight: Double)
        case elevateBias(weight: Double)
        case suppressBias(weight: Double)
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
