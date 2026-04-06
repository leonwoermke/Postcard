import Foundation
import GRDB

public struct ClusterRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "clusters"

    public enum Columns {
        public static let id = Column("id")
        public static let roomID = Column("room_id")
        public static let kind = Column("kind")
        public static let kindOther = Column("kind_other")
        public static let title = Column("title")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case roomID = "room_id"
        case kind
        case kindOther = "kind_other"
        case title
    }

    public let id: String
    public let roomID: String
    public let kind: String
    public let kindOther: String?
    public let title: String?

    public init(id: ClusterID, cluster: Cluster) {
        self.id = id.rawValue.uuidString
        self.roomID = cluster.roomID.rawValue.uuidString

        let encodedKind = Self.encodeKind(cluster.kind)
        self.kind = encodedKind.kind
        self.kindOther = encodedKind.other
        self.title = cluster.title
    }

    public init(domain cluster: Cluster) {
        self.init(id: cluster.id, cluster: cluster)
    }

    public func toDomain() throws -> Cluster {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }
        guard let decodedRoomID = UUID(uuidString: roomID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.roomID.name): \(roomID)")
            )
        }

        return Cluster(
            id: ClusterID(rawValue: decodedID),
            roomID: RoomID(rawValue: decodedRoomID),
            kind: Self.decodeKind(kind: kind, other: kindOther),
            title: title
        )
    }

    public func asDomain() throws -> Cluster {
        try toDomain()
    }

    private static func encodeKind(_ kind: Cluster.Kind) -> (kind: String, other: String?) {
        switch kind {
        case .topic: return ("topic", nil)
        case .transaction: return ("transaction", nil)
        case .scheduling: return ("scheduling", nil)
        case .support: return ("support", nil)
        case .unknown: return ("unknown", nil)
        case .other(let value): return ("other", value)
        }
    }

    private static func decodeKind(kind: String, other: String?) -> Cluster.Kind {
        switch kind {
        case "topic": return .topic
        case "transaction": return .transaction
        case "scheduling": return .scheduling
        case "support": return .support
        case "unknown": return .unknown
        case "other": return .other(other ?? "")
        default: return .unknown
        }
    }
}
