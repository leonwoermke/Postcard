import Foundation

public struct HomeSnapshotInput: Equatable, Hashable, Sendable {
    public struct RoomEntry: Equatable, Hashable, Sendable {
        public let room: Room
        public let latestMessage: RenderableMessage?
        public let hasProvisionalAssignments: Bool

        public init(
            room: Room,
            latestMessage: RenderableMessage? = nil,
            hasProvisionalAssignments: Bool
        ) {
            self.room = room
            self.latestMessage = latestMessage
            self.hasProvisionalAssignments = hasProvisionalAssignments
        }
    }

    public struct UnresolvedItem: Equatable, Hashable, Sendable {
        public enum Kind: Equatable, Hashable, Sendable {
            case message(MessageID)
            case entity(EntityID)
            case assignment(MessageID)
        }

        public let kind: Kind
        public let confidence: Confidence

        public init(
            kind: Kind,
            confidence: Confidence
        ) {
            self.kind = kind
            self.confidence = confidence
        }
    }

    public let rooms: [RoomEntry]
    public let unresolvedItems: [UnresolvedItem]

    public init(
        rooms: [RoomEntry],
        unresolvedItems: [UnresolvedItem] = []
    ) {
        self.rooms = rooms
        self.unresolvedItems = unresolvedItems
    }
}
