import Foundation

public struct Assignment: Equatable, Hashable, Sendable {
    public enum PlacementState: Equatable, Hashable, Sendable {
        case settled
        case provisional
    }

    public struct AlternativeCandidate: Equatable, Hashable, Sendable {
        public let roomID: RoomID
        public let clusterID: ClusterID?
        public let confidence: Confidence

        public init(
            roomID: RoomID,
            clusterID: ClusterID? = nil,
            confidence: Confidence
        ) {
            self.roomID = roomID
            self.clusterID = clusterID
            self.confidence = confidence
        }
    }

    public let id: AssignmentID
    public let messageID: MessageID
    public let roomID: RoomID
    public let clusterID: ClusterID?
    public let confidence: Confidence
    public let state: PlacementState
    public let alternativeCandidates: [AlternativeCandidate]

    public init(
        id: AssignmentID = AssignmentID(),
        messageID: MessageID,
        roomID: RoomID,
        clusterID: ClusterID? = nil,
        confidence: Confidence,
        state: PlacementState,
        alternativeCandidates: [AlternativeCandidate] = []
    ) {
        self.id = id
        self.messageID = messageID
        self.roomID = roomID
        self.clusterID = clusterID
        self.confidence = confidence
        self.state = state
        self.alternativeCandidates = alternativeCandidates
    }
}
