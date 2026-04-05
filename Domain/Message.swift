import Foundation

public struct Message: Equatable, Hashable, Sendable {
    public enum Direction: Equatable, Hashable, Sendable {
        case inbound
        case outbound
    }

    public let id: MessageID
    public let accountID: AccountID
    public let internetMessageID: String?
    public let subject: String?
    public let body: MessageBody
    public let participants: [Participant]
    public let sentAt: Date?
    public let receivedAt: Date?
    public let attachments: [Attachment]
    public let inReplyToInternetMessageID: String?
    public let referenceInternetMessageIDs: [String]
    public let direction: Direction

    public init(
        id: MessageID = MessageID(),
        accountID: AccountID,
        internetMessageID: String? = nil,
        subject: String? = nil,
        body: MessageBody,
        participants: [Participant],
        sentAt: Date? = nil,
        receivedAt: Date? = nil,
        attachments: [Attachment] = [],
        inReplyToInternetMessageID: String? = nil,
        referenceInternetMessageIDs: [String] = [],
        direction: Direction
    ) {
        self.id = id
        self.accountID = accountID
        self.internetMessageID = internetMessageID
        self.subject = subject
        self.body = body
        self.participants = participants
        self.sentAt = sentAt
        self.receivedAt = receivedAt
        self.attachments = attachments
        self.inReplyToInternetMessageID = inReplyToInternetMessageID
        self.referenceInternetMessageIDs = referenceInternetMessageIDs
        self.direction = direction
    }
}
