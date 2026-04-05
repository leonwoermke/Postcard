import Foundation

public struct MessagePreview: Equatable, Hashable, Sendable {
    public let id: MessageID
    public let accountID: AccountID
    public let subject: String?
    public let participants: [Participant]
    public let sentAt: Date?
    public let receivedAt: Date?
    public let direction: Message.Direction
    public let bodyPreview: String?

    public init(
        id: MessageID,
        accountID: AccountID,
        subject: String? = nil,
        participants: [Participant],
        sentAt: Date? = nil,
        receivedAt: Date? = nil,
        direction: Message.Direction,
        bodyPreview: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.subject = subject
        self.participants = participants
        self.sentAt = sentAt
        self.receivedAt = receivedAt
        self.direction = direction
        self.bodyPreview = bodyPreview
    }
}
