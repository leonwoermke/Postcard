import Foundation

public struct RoomLookup: Equatable, Hashable, Sendable {
    public let id: RoomID
    public let anchor: Room.Anchor
    public let title: String?

    public init(
        id: RoomID,
        anchor: Room.Anchor,
        title: String? = nil
    ) {
        self.id = id
        self.anchor = anchor
        self.title = title
    }
}
