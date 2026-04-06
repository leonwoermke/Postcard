import Foundation
import GRDB

public struct AttachmentRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "attachments"

    public enum Columns {
        public static let id = Column("id")
        public static let messageID = Column("message_id")
        public static let kind = Column("kind")
        public static let kindOther = Column("kind_other")
        public static let filename = Column("filename")
        public static let mimeType = Column("mime_type")
        public static let byteSize = Column("byte_size")
        public static let contentID = Column("content_id")
        public static let isInline = Column("is_inline")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case messageID = "message_id"
        case kind
        case kindOther = "kind_other"
        case filename
        case mimeType = "mime_type"
        case byteSize = "byte_size"
        case contentID = "content_id"
        case isInline = "is_inline"
    }

    public let id: String
    public let messageID: String
    public let kind: String
    public let kindOther: String?
    public let filename: String?
    public let mimeType: String?
    public let byteSize: Int?
    public let contentID: String?
    public let isInline: Bool

    public init(id: AttachmentID, attachment: Attachment) {
        self.id = id.rawValue.uuidString
        self.messageID = attachment.messageID.rawValue.uuidString

        let encodedKind = Self.encodeKind(attachment.kind)
        self.kind = encodedKind.kind
        self.kindOther = encodedKind.other

        self.filename = attachment.filename
        self.mimeType = attachment.mimeType
        self.byteSize = attachment.byteSize
        self.contentID = attachment.contentID
        self.isInline = attachment.isInline
    }

    public init(domain attachment: Attachment) {
        self.init(id: attachment.id, attachment: attachment)
    }

    public func toDomain() throws -> Attachment {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        guard let decodedMessageID = UUID(uuidString: messageID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.messageID.name): \(messageID)")
            )
        }

        return Attachment(
            id: AttachmentID(rawValue: decodedID),
            messageID: MessageID(rawValue: decodedMessageID),
            kind: Self.decodeKind(kind: kind, other: kindOther),
            filename: filename,
            mimeType: mimeType,
            byteSize: byteSize,
            contentID: contentID,
            isInline: isInline
        )
    }

    public func asDomain() throws -> Attachment {
        try toDomain()
    }

    private static func encodeKind(_ kind: AttachmentKind) -> (kind: String, other: String?) {
        switch kind {
        case .document: return ("document", nil)
        case .calendarInvite: return ("calendarInvite", nil)
        case .contact: return ("contact", nil)
        case .inlineImage: return ("inlineImage", nil)
        case .dataFile: return ("dataFile", nil)
        case .archive: return ("archive", nil)
        case .unsafe: return ("unsafe", nil)
        case .unknown: return ("unknown", nil)
        case .other(let value): return ("other", value)
        }
    }

    private static func decodeKind(kind: String, other: String?) -> AttachmentKind {
        switch kind {
        case "document": return .document
        case "calendarInvite": return .calendarInvite
        case "contact": return .contact
        case "inlineImage": return .inlineImage
        case "dataFile": return .dataFile
        case "archive": return .archive
        case "unsafe": return .unsafe
        case "unknown": return .unknown
        case "other": return .other(other ?? "")
        default: return .unknown
        }
    }
}
