import Foundation
import GRDB

public struct AssignmentRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "assignments"

    public enum Columns {
        public static let id = Column("id")
        public static let messageID = Column("message_id")
        public static let roomID = Column("room_id")
        public static let clusterID = Column("cluster_id")
        public static let confidence = Column("confidence")
        public static let state = Column("state")
        public static let alternativeCandidatesJSON = Column("alternative_candidates_json")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case messageID = "message_id"
        case roomID = "room_id"
        case clusterID = "cluster_id"
        case confidence
        case state
        case alternativeCandidatesJSON = "alternative_candidates_json"
    }

    public enum StateValue: String, Codable, Sendable {
        case settled
        case provisional
    }

    public struct AlternativeCandidatePayload: Codable, Sendable {
        public let roomID: String
        public let clusterID: String?
        public let confidence: Double
    }

    public let id: String
    public let messageID: String
    public let roomID: String
    public let clusterID: String?
    public let confidence: Double
    public let state: StateValue
    public let alternativeCandidatesJSON: Data

    public init(id: AssignmentID, assignment: Assignment) throws {
        self.id = id.rawValue.uuidString
        self.messageID = assignment.messageID.rawValue.uuidString
        self.roomID = assignment.roomID.rawValue.uuidString
        self.clusterID = assignment.clusterID?.rawValue.uuidString
        self.confidence = assignment.confidence.rawValue
        self.state = assignment.state == .settled ? .settled : .provisional
        self.alternativeCandidatesJSON = try JSONEncoder().encode(
            assignment.alternativeCandidates.map {
                AlternativeCandidatePayload(
                    roomID: $0.roomID.rawValue.uuidString,
                    clusterID: $0.clusterID?.rawValue.uuidString,
                    confidence: $0.confidence.rawValue
                )
            }
        )
    }

    public init(domain assignment: Assignment) throws {
        try self.init(id: assignment.id, assignment: assignment)
    }

    public func toDomain() throws -> Assignment {
        let candidates = try JSONDecoder().decode([AlternativeCandidatePayload].self, from: alternativeCandidatesJSON)

        guard let decodedID = UUID(uuidString: id),
              let decodedMessageID = UUID(uuidString: messageID),
              let decodedRoomID = UUID(uuidString: roomID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid assignment UUID payload")
            )
        }

        return Assignment(
            id: AssignmentID(rawValue: decodedID),
            messageID: MessageID(rawValue: decodedMessageID),
            roomID: RoomID(rawValue: decodedRoomID),
            clusterID: clusterID.flatMap(UUID.init(uuidString:)).map(ClusterID.init(rawValue:)),
            confidence: try StorageCoding.decodeConfidence(confidence, field: Columns.confidence.name),
            state: state == .settled ? .settled : .provisional,
            alternativeCandidates: try candidates.map { candidate in
                guard let roomUUID = UUID(uuidString: candidate.roomID) else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: [], debugDescription: "Invalid roomID in alternative candidate: \(candidate.roomID)")
                    )
                }

                return Assignment.AlternativeCandidate(
                    roomID: RoomID(rawValue: roomUUID),
                    clusterID: candidate.clusterID.flatMap(UUID.init(uuidString:)).map(ClusterID.init(rawValue:)),
                    confidence: try StorageCoding.decodeConfidence(candidate.confidence, field: "AlternativeCandidate.confidence")
                )
            }
        )
    }

    public func asDomain() throws -> Assignment {
        try toDomain()
    }
}
