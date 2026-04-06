import Foundation
import GRDB

public struct MessageRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "messages"

    public enum Columns {
        public static let id = Column("id")
        public static let accountID = Column("account_id")
        public static let internetMessageID = Column("internet_message_id")
        public static let subject = Column("subject")
        public static let sentAt = Column("sent_at")
        public static let receivedAt = Column("received_at")
        public static let attachmentIDsJSON = Column("attachment_ids_json")
        public static let inReplyToInternetMessageID = Column("in_reply_to_internet_message_id")
        public static let referenceInternetMessageIDsJSON = Column("reference_internet_message_ids_json")
        public static let direction = Column("direction")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case accountID = "account_id"
        case internetMessageID = "internet_message_id"
        case subject
        case sentAt = "sent_at"
        case receivedAt = "received_at"
        case attachmentIDsJSON = "attachment_ids_json"
        case inReplyToInternetMessageID = "in_reply_to_internet_message_id"
        case referenceInternetMessageIDsJSON = "reference_internet_message_ids_json"
        case direction
    }

    public enum DirectionValue: String, Codable, Sendable {
        case inbound
        case outbound
    }

    public let id: String
    public let accountID: String
    public let internetMessageID: String?
    public let subject: String?
    public let sentAt: Date?
    public let receivedAt: Date?
    public let attachmentIDsJSON: Data
    public let inReplyToInternetMessageID: String?
    public let referenceInternetMessageIDsJSON: Data
    public let direction: DirectionValue

    public init(id: MessageID, message: Message) throws {
        self.id = id.rawValue.uuidString
        self.accountID = message.accountID.rawValue.uuidString
        self.internetMessageID = message.internetMessageID
        self.subject = message.subject
        self.sentAt = message.sentAt
        self.receivedAt = message.receivedAt
        self.attachmentIDsJSON = try JSONEncoder().encode(message.attachmentIDs.map(\.rawValue.uuidString))
        self.inReplyToInternetMessageID = message.inReplyToInternetMessageID
        self.referenceInternetMessageIDsJSON = try JSONEncoder().encode(message.referenceInternetMessageIDs)
        self.direction = message.direction == .inbound ? .inbound : .outbound
    }

    public init(domain message: Message) throws {
        try self.init(id: message.id, message: message)
    }

    public func toDomain(
        body: MessageBody,
        participants: [Participant]
    ) throws -> Message {
        let attachmentIDStrings = try JSONDecoder().decode([String].self, from: attachmentIDsJSON)
        let referenceIDs = try JSONDecoder().decode([String].self, from: referenceInternetMessageIDsJSON)

        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        guard let decodedAccountID = UUID(uuidString: accountID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.accountID.name): \(accountID)")
            )
        }

        let decodedAttachmentIDs: [AttachmentID] = try attachmentIDStrings.map { raw in
            guard let uuid = UUID(uuidString: raw) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Invalid UUID in \(Columns.attachmentIDsJSON.name): \(raw)")
                )
            }
            return AttachmentID(rawValue: uuid)
        }

        return Message(
            id: MessageID(rawValue: decodedID),
            accountID: AccountID(rawValue: decodedAccountID),
            internetMessageID: internetMessageID,
            subject: subject,
            body: body,
            participants: participants,
            sentAt: sentAt,
            receivedAt: receivedAt,
            attachmentIDs: decodedAttachmentIDs,
            inReplyToInternetMessageID: inReplyToInternetMessageID,
            referenceInternetMessageIDs: referenceIDs,
            direction: direction == .inbound ? .inbound : .outbound
        )
    }

    public func asDomain(
        body: MessageBody,
        participants: [Participant]
    ) throws -> Message {
        try toDomain(body: body, participants: participants)
    }
}
