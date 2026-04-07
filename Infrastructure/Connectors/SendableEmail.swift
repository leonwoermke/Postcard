import Foundation

public struct SendableEmail: Sendable {
    public struct Address: Sendable {
        public let address: String
        public let displayName: String?

        public init(
            address: String,
            displayName: String? = nil
        ) {
            self.address = address
            self.displayName = displayName
        }
    }

    public struct Attachment: Sendable {
        public let fileName: String
        public let mimeType: String?
        public let data: Data

        public init(
            fileName: String,
            mimeType: String? = nil,
            data: Data
        ) {
            self.fileName = fileName
            self.mimeType = mimeType
            self.data = data
        }
    }

    public struct ThreadContext: Sendable {
        public let replyToExternalMessageID: String?
        public let inReplyTo: String?
        public let references: [String]

        public init(
            replyToExternalMessageID: String? = nil,
            inReplyTo: String? = nil,
            references: [String] = []
        ) {
            self.replyToExternalMessageID = replyToExternalMessageID
            self.inReplyTo = inReplyTo
            self.references = references
        }
    }

    public let accountID: AccountID
    public let from: SendableEmail.Address?
    public let to: [SendableEmail.Address]
    public let cc: [SendableEmail.Address]
    public let bcc: [SendableEmail.Address]
    public let subject: String
    public let plainTextBody: String
    public let htmlBody: String?
    public let threadContext: SendableEmail.ThreadContext
    public let attachments: [SendableEmail.Attachment]

    public init(
        accountID: AccountID,
        from: SendableEmail.Address? = nil,
        to: [SendableEmail.Address],
        cc: [SendableEmail.Address] = [],
        bcc: [SendableEmail.Address] = [],
        subject: String,
        plainTextBody: String,
        htmlBody: String? = nil,
        threadContext: SendableEmail.ThreadContext = .init(),
        attachments: [SendableEmail.Attachment] = []
    ) {
        self.accountID = accountID
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.plainTextBody = plainTextBody
        self.htmlBody = htmlBody
        self.threadContext = threadContext
        self.attachments = attachments
    }
}
