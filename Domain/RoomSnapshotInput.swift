import Foundation

public struct RoomSnapshotInput: DerivedProjectionInput {
    public struct MessageEntry: Equatable, Hashable, Sendable {
        public let renderableMessage: RenderableMessage
        public let isProvisionalAssignment: Bool

        public init(
            renderableMessage: RenderableMessage,
            isProvisionalAssignment: Bool
        ) {
            self.renderableMessage = renderableMessage
            self.isProvisionalAssignment = isProvisionalAssignment
        }
    }

    public struct ClusterEntry: Equatable, Hashable, Sendable {
        public let cluster: Cluster

        public init(cluster: Cluster) {
            self.cluster = cluster
        }
    }

    public let room: Room
    public let messages: [MessageEntry]
    public let clusters: [ClusterEntry]
    public let references: [RoomReference]

    public init(
        room: Room,
        messages: [MessageEntry],
        clusters: [ClusterEntry] = [],
        references: [RoomReference] = []
    ) {
        self.room = room
        self.messages = messages
        self.clusters = clusters
        self.references = references
    }
}
