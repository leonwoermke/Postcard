import Foundation

public struct ConnectorID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public enum ConnectorAvailability: Sendable {
    case available
    case limited(reason: String)
    case unavailable(reason: String)
}

public struct ConnectorSyncCursor: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ConnectorSyncState: Sendable {
    public enum Mode: String, Sendable {
        case idle
        case incremental
        case catchUp
    }

    public let mode: Mode
    public let cursor: ConnectorSyncCursor?
    public let lastCompletedSyncAt: Date?
    public let hasMoreAvailable: Bool

    public init(
        mode: ConnectorSyncState.Mode,
        cursor: ConnectorSyncCursor?,
        lastCompletedSyncAt: Date?,
        hasMoreAvailable: Bool
    ) {
        self.mode = mode
        self.cursor = cursor
        self.lastCompletedSyncAt = lastCompletedSyncAt
        self.hasMoreAvailable = hasMoreAvailable
    }
}

public struct ConnectorHeader: Sendable {
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

public struct ConnectorRecipient: Sendable {
    public enum Kind: String, Sendable {
        case from
        case to
        case cc
        case bcc
        case replyTo
    }

    public let address: String
    public let displayName: String?
    public let kind: Kind

    public init(
        address: String,
        displayName: String? = nil,
        kind: ConnectorRecipient.Kind
    ) {
        self.address = address
        self.displayName = displayName
        self.kind = kind
    }
}

public struct ConnectorAttachment: Sendable {
    public let externalID: String
    public let fileName: String?
    public let mimeType: String?
    public let byteCount: Int?
    public let inline: Bool

    public init(
        externalID: String,
        fileName: String? = nil,
        mimeType: String? = nil,
        byteCount: Int? = nil,
        inline: Bool = false
    ) {
        self.externalID = externalID
        self.fileName = fileName
        self.mimeType = mimeType
        self.byteCount = byteCount
        self.inline = inline
    }
}

public struct ConnectorInboundMessage: Sendable {
    public let externalMessageID: String
    public let threadReference: String?
    public let subject: String
    public let sentAt: Date
    public let receivedAt: Date?
    public let recipients: [ConnectorRecipient]
    public let plainTextBody: String?
    public let htmlBody: String?
    public let attachments: [ConnectorAttachment]
    public let headers: [ConnectorHeader]
    public let rawSource: Data?

    public init(
        externalMessageID: String,
        threadReference: String? = nil,
        subject: String,
        sentAt: Date,
        receivedAt: Date? = nil,
        recipients: [ConnectorRecipient],
        plainTextBody: String? = nil,
        htmlBody: String? = nil,
        attachments: [ConnectorAttachment] = [],
        headers: [ConnectorHeader] = [],
        rawSource: Data? = nil
    ) {
        self.externalMessageID = externalMessageID
        self.threadReference = threadReference
        self.subject = subject
        self.sentAt = sentAt
        self.receivedAt = receivedAt
        self.recipients = recipients
        self.plainTextBody = plainTextBody
        self.htmlBody = htmlBody
        self.attachments = attachments
        self.headers = headers
        self.rawSource = rawSource
    }
}

public struct ConnectorInboundBatch: Sendable {
    public let messages: [ConnectorInboundMessage]
    public let nextCursor: ConnectorSyncCursor?
    public let hasMoreAvailable: Bool
    public let syncState: ConnectorSyncState

    public init(
        messages: [ConnectorInboundMessage],
        nextCursor: ConnectorSyncCursor?,
        hasMoreAvailable: Bool,
        syncState: ConnectorSyncState
    ) {
        self.messages = messages
        self.nextCursor = nextCursor
        self.hasMoreAvailable = hasMoreAvailable
        self.syncState = syncState
    }
}

public struct ConnectorOutboundAttachment: Sendable {
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

public struct ConnectorSendRequest: Sendable {
    public let accountID: AccountID
    public let subject: String
    public let plainTextBody: String
    public let htmlBody: String?
    public let toAddresses: [String]
    public let ccAddresses: [String]
    public let bccAddresses: [String]
    public let attachments: [ConnectorOutboundAttachment]
    public let replyToExternalMessageID: String?

    public init(
        accountID: AccountID,
        subject: String,
        plainTextBody: String,
        htmlBody: String? = nil,
        toAddresses: [String],
        ccAddresses: [String] = [],
        bccAddresses: [String] = [],
        attachments: [ConnectorOutboundAttachment] = [],
        replyToExternalMessageID: String? = nil
    ) {
        self.accountID = accountID
        self.subject = subject
        self.plainTextBody = plainTextBody
        self.htmlBody = htmlBody
        self.toAddresses = toAddresses
        self.ccAddresses = ccAddresses
        self.bccAddresses = bccAddresses
        self.attachments = attachments
        self.replyToExternalMessageID = replyToExternalMessageID
    }
}

public struct ConnectorSendResult: Sendable {
    public let externalMessageID: String
    public let acceptedAt: Date?

    public init(
        externalMessageID: String,
        acceptedAt: Date? = nil
    ) {
        self.externalMessageID = externalMessageID
        self.acceptedAt = acceptedAt
    }
}

public protocol EmailConnector: Sendable {
    var id: ConnectorID { get }
    var displayName: String { get }

    func availability() async -> ConnectorAvailability
    func currentSyncState() async throws -> ConnectorSyncState
    func fetchInboundBatch(
        after cursor: ConnectorSyncCursor?,
        limit: Int
    ) async throws -> ConnectorInboundBatch
    func send(_ request: ConnectorSendRequest) async throws -> ConnectorSendResult
}
