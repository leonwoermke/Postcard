import Foundation
import GRDB

public struct ParticipantRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "participants"

    public enum Columns {
        public static let id = Column("id")
        public static let messageID = Column("message_id")
        public static let role = Column("role")
        public static let address = Column("address")
        public static let displayName = Column("display_name")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case messageID = "message_id"
        case role
        case address
        case displayName = "display_name"
    }

    public enum RoleValue: String, Codable, Sendable {
        case from
        case to
        case cc
        case bcc
        case replyTo
    }

    public let id: String
    public let messageID: String
    public let role: RoleValue
    public let address: String
    public let displayName: String?

    public init(
        storageID: String,
        messageID: MessageID,
        participant: Participant
    ) {
        self.id = storageID
        self.messageID = messageID.rawValue.uuidString
        self.role = Self.encode(participant.role)
        self.address = participant.address
        self.displayName = participant.displayName
    }

    public init(messageID: MessageID, participant: Participant) {
        self.init(
            storageID: StorageCoding.stableParticipantStorageID(messageID: messageID, participant: participant),
            messageID: messageID,
            participant: participant
        )
    }

    public func toDomain() -> Participant {
        Participant(
            role: Self.decode(role),
            address: address,
            displayName: displayName
        )
    }

    public func asDomain() -> Participant {
        toDomain()
    }

    private static func encode(_ role: Participant.Role) -> RoleValue {
        switch role {
        case .from: return .from
        case .to: return .to
        case .cc: return .cc
        case .bcc: return .bcc
        case .replyTo: return .replyTo
        }
    }

    private static func decode(_ role: RoleValue) -> Participant.Role {
        switch role {
        case .from: return .from
        case .to: return .to
        case .cc: return .cc
        case .bcc: return .bcc
        case .replyTo: return .replyTo
        }
    }
}
