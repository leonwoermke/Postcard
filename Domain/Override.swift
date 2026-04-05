import Foundation

public struct Override: Equatable, Hashable, Sendable {
    public enum Scope: Equatable, Hashable, Sendable {
        case message(MessageID)
        case block(BlockID)
        case entity(EntityID)
        case room(RoomID)
        case assignment(MessageID)
        case senderAddress(String)
        case pattern(String)
        case global
    }

    public enum Payload: Equatable, Hashable, Sendable {
        case messageKind(InterpretationResolution<MessageKind>)
        case blockKind(InterpretationResolution<BlockInterpretation.Kind>)
        case entityKind(InterpretationResolution<EntityKind>)
        case assignment(roomID: RoomID, clusterID: ClusterID?)
    }

    public let id: OverrideID
    public let scope: Scope
    public let payload: Payload
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: OverrideID = OverrideID(),
        scope: Scope,
        payload: Payload,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.scope = scope
        self.payload = payload
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
