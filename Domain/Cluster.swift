import Foundation

public struct Cluster: Equatable, Hashable, Sendable {
    public enum Kind: Equatable, Hashable, Sendable {
        case topic
        case transaction
        case scheduling
        case support
        case unknown
        case other(String)
    }

    public let id: ClusterID
    public let roomID: RoomID
    public let kind: Kind
    public let title: String?

    public init(
        id: ClusterID = ClusterID(),
        roomID: RoomID,
        kind: Kind = .unknown,
        title: String? = nil
    ) {
        self.id = id
        self.roomID = roomID
        self.kind = kind
        self.title = title
    }
}
