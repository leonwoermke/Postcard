import Foundation

public struct RoomReference: Equatable, Hashable, Sendable {
    public enum Kind: Equatable, Hashable, Sendable {
        case continuation
        case handoff
        case related
        case unknown
        case other(String)
    }

    public let fromRoomID: RoomID
    public let toRoomID: RoomID
    public let kind: Kind
    public let anchorMessageID: MessageID?

    public init(
        fromRoomID: RoomID,
        toRoomID: RoomID,
        kind: Kind = .unknown,
        anchorMessageID: MessageID? = nil
    ) {
        self.fromRoomID = fromRoomID
        self.toRoomID = toRoomID
        self.kind = kind
        self.anchorMessageID = anchorMessageID
    }
}
