import Foundation
import GRDB

public struct MessageBodyRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "message_bodies"

    public enum Columns {
        public static let messageID = Column("message_id")
        public static let plainText = Column("plain_text")
        public static let html = Column("html")
        public static let normalizedText = Column("normalized_text")
    }

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case plainText = "plain_text"
        case html
        case normalizedText = "normalized_text"
    }

    public let messageID: String
    public let plainText: String?
    public let html: String?
    public let normalizedText: String?

    public init(messageID: MessageID, messageBody: MessageBody) {
        self.messageID = messageID.rawValue.uuidString
        self.plainText = messageBody.plainText
        self.html = messageBody.html
        self.normalizedText = messageBody.normalizedText
    }

    public init(messageID: MessageID, body: MessageBody) {
        self.init(messageID: messageID, messageBody: body)
    }

    public func toDomain() -> MessageBody {
        MessageBody(
            plainText: plainText,
            html: html,
            normalizedText: normalizedText
        )
    }

    public func asDomain() -> MessageBody {
        toDomain()
    }

    public var previewText: String {
        if let normalizedText, !normalizedText.isEmpty { return normalizedText }
        if let plainText, !plainText.isEmpty { return plainText }
        if let html, !html.isEmpty { return html }
        return ""
    }
}
