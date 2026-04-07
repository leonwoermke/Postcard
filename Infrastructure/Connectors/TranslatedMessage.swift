import Foundation

public struct TranslatedMessage: Sendable {
    public struct Participant: Sendable {
        public enum Role: String, Sendable {
            case from
            case to
            case cc
            case bcc
            case replyTo
        }

        public let address: String
        public let displayName: String?
        public let role: Role

        public init(
            address: String,
            displayName: String? = nil,
            role: Participant.Role
        ) {
            self.address = address
            self.displayName = displayName
            self.role = role
        }
    }

    public struct Body: Sendable {
        public let plainText: String?
        public let html: String?
        public let previewText: String?

        public init(
            plainText: String? = nil,
            html: String? = nil,
            previewText: String? = nil
        ) {
            self.plainText = plainText
            self.html = html
            self.previewText = previewText
        }
    }

    public struct Header: Sendable {
        public let name: String
        public let value: String

        public init(
            name: String,
            value: String
        ) {
            self.name = name
            self.value = value
        }
    }

    public struct ReplyContext: Sendable {
        public let messageIDHeader: String?
        public let inReplyTo: String?
        public let references: [String]
        public let replyToAddress: String?
        public let replyToDisplayName: String?

        public init(
            messageIDHeader: String? = nil,
            inReplyTo: String? = nil,
            references: [String] = [],
            replyToAddress: String? = nil,
            replyToDisplayName: String? = nil
        ) {
            self.messageIDHeader = messageIDHeader
            self.inReplyTo = inReplyTo
            self.references = references
            self.replyToAddress = replyToAddress
            self.replyToDisplayName = replyToDisplayName
        }
    }

    public struct OriginalContent: Sendable {
        public let rawSource: Data?
        public let externalThreadReference: String?
        public let externalLabels: [String]
        public let externalMetadata: [String: String]

        public init(
            rawSource: Data? = nil,
            externalThreadReference: String? = nil,
            externalLabels: [String] = [],
            externalMetadata: [String: String] = [:]
        ) {
            self.rawSource = rawSource
            self.externalThreadReference = externalThreadReference
            self.externalLabels = externalLabels
            self.externalMetadata = externalMetadata
        }
    }

    public let connectorID: ConnectorID
    public let accountID: AccountID
    public let externalMessageID: String
    public let subject: String
    public let sentAt: Date
    public let receivedAt: Date?
    public let participants: [TranslatedMessage.Participant]
    public let body: TranslatedMessage.Body
    public let attachments: [TranslatedAttachment]
    public let headers: [TranslatedMessage.Header]
    public let replyContext: TranslatedMessage.ReplyContext
    public let originalContent: TranslatedMessage.OriginalContent

    public init(
        connectorID: ConnectorID,
        accountID: AccountID,
        externalMessageID: String,
        subject: String,
        sentAt: Date,
        receivedAt: Date? = nil,
        participants: [TranslatedMessage.Participant],
        body: TranslatedMessage.Body,
        attachments: [TranslatedAttachment] = [],
        headers: [TranslatedMessage.Header] = [],
        replyContext: TranslatedMessage.ReplyContext = .init(),
        originalContent: TranslatedMessage.OriginalContent = .init()
    ) {
        self.connectorID = connectorID
        self.accountID = accountID
        self.externalMessageID = externalMessageID
        self.subject = subject
        self.sentAt = sentAt
        self.receivedAt = receivedAt
        self.participants = participants
        self.body = body
        self.attachments = attachments
        self.headers = headers
        self.replyContext = replyContext
        self.originalContent = originalContent
    }
}
