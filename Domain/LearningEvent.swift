import Foundation

public struct LearningEvent: Equatable, Hashable, Sendable {
    public enum Scope: Equatable, Hashable, Sendable {
        case message(MessageID)
        case block(BlockID)
        case entity(EntityID)
        case room(RoomID)
        case senderAddress(String)
        case pattern(String)
        case global
    }

    public enum Kind: Equatable, Hashable, Sendable {
        case correctedMessageInterpretation
        case correctedBlockInterpretation
        case correctedEntityInterpretation
        case correctedAssignment
        case expandedContent
        case collapsedContent
        case dismissedContent
        case elevatedContent
        case interactedWithAction(ActionKind)
        case ignoredAction(ActionKind)
    }

    public enum Strength: Equatable, Hashable, Sendable {
        case strong
        case weak
    }

    public let id: LearningEventID
    public let kind: Kind
    public let scope: Scope
    public let strength: Strength
    public let occurredAt: Date

    public init(
        id: LearningEventID = LearningEventID(),
        kind: Kind,
        scope: Scope,
        strength: Strength,
        occurredAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.scope = scope
        self.strength = strength
        self.occurredAt = occurredAt
    }
}
