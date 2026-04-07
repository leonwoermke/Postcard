import Foundation
import OSLog

public enum CanonicalMessageBuilderError: Error, Sendable {
    case missingExternalMessageID
    case preservedAccountMismatch(expected: AccountID, actual: AccountID)
    case preservedConnectorMismatch(expected: ConnectorID, actual: ConnectorID)
    case preservedExternalMessageIDMismatch(expected: String, actual: String)
    case preservedAttachmentCountMismatch(expected: Int, actual: Int)
}

public struct CanonicalBuildResult: Sendable {
    public let message: Message
    public let messageBody: MessageBody
    public let participants: [Participant]
    public let attachments: [Attachment]

    public init(
        message: Message,
        messageBody: MessageBody,
        participants: [Participant],
        attachments: [Attachment]
    ) {
        self.message = message
        self.messageBody = messageBody
        self.participants = participants
        self.attachments = attachments
    }
}

public protocol CanonicalIdentifierGenerating: Sendable {
    func makeMessageID(
        accountID: AccountID,
        connectorID: ConnectorID,
        externalMessageID: String
    ) -> MessageID

    func makeAttachmentID(
        messageID: MessageID,
        externalAttachmentID: String,
        index: Int
    ) -> AttachmentID
}

public protocol CanonicalDomainBuilding: Sendable {
    func makeMessage(from seed: CanonicalMessageBuilder.MessageSeed) throws -> Message
    func makeMessageBody(from seed: CanonicalMessageBuilder.MessageBodySeed) throws -> MessageBody
    func makeParticipant(from seed: CanonicalMessageBuilder.ParticipantSeed) throws -> Participant
    func makeAttachment(from seed: CanonicalMessageBuilder.AttachmentSeed) throws -> Attachment
}

public final class CanonicalMessageBuilder {
    public struct MessageSeed: Sendable {
        public let id: MessageID
        public let accountID: AccountID
        public let subject: String
        public let sentAt: Date
        public let receivedAt: Date?
        public let attachmentIDs: [AttachmentID]
        public let externalMessageID: String
        public let messageIDHeader: String?
        public let inReplyTo: String?
        public let references: [String]

        public init(
            id: MessageID,
            accountID: AccountID,
            subject: String,
            sentAt: Date,
            receivedAt: Date?,
            attachmentIDs: [AttachmentID],
            externalMessageID: String,
            messageIDHeader: String?,
            inReplyTo: String?,
            references: [String]
        ) {
            self.id = id
            self.accountID = accountID
            self.subject = subject
            self.sentAt = sentAt
            self.receivedAt = receivedAt
            self.attachmentIDs = attachmentIDs
            self.externalMessageID = externalMessageID
            self.messageIDHeader = messageIDHeader
            self.inReplyTo = inReplyTo
            self.references = references
        }
    }

    public struct MessageBodySeed: Sendable {
        public let messageID: MessageID
        public let plainText: String?
        public let html: String?
        public let previewText: String?
        public let rawSource: Data?

        public init(
            messageID: MessageID,
            plainText: String?,
            html: String?,
            previewText: String?,
            rawSource: Data?
        ) {
            self.messageID = messageID
            self.plainText = plainText
            self.html = html
            self.previewText = previewText
            self.rawSource = rawSource
        }
    }

    public struct ParticipantSeed: Sendable {
        public enum Role: String, Sendable {
            case from
            case to
            case cc
            case bcc
            case replyTo
        }

        public let messageID: MessageID
        public let address: String
        public let displayName: String?
        public let role: Role

        public init(
            messageID: MessageID,
            address: String,
            displayName: String?,
            role: ParticipantSeed.Role
        ) {
            self.messageID = messageID
            self.address = address
            self.displayName = displayName
            self.role = role
        }
    }

    public struct AttachmentSeed: Sendable {
        public let id: AttachmentID
        public let messageID: MessageID
        public let fileName: String?
        public let mimeType: String?
        public let byteCount: Int?
        public let inline: Bool
        public let contentID: String?
        public let sourceURL: URL?
        public let rawData: Data?

        public init(
            id: AttachmentID,
            messageID: MessageID,
            fileName: String?,
            mimeType: String?,
            byteCount: Int?,
            inline: Bool,
            contentID: String?,
            sourceURL: URL?,
            rawData: Data?
        ) {
            self.id = id
            self.messageID = messageID
            self.fileName = fileName
            self.mimeType = mimeType
            self.byteCount = byteCount
            self.inline = inline
            self.contentID = contentID
            self.sourceURL = sourceURL
            self.rawData = rawData
        }
    }

    private static let logger: Logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.CanonicalMessageBuilder"
    )

    private let identifierGenerator: any CanonicalIdentifierGenerating
    private let domainBuilder: any CanonicalDomainBuilding

    public init(
        identifierGenerator: any CanonicalIdentifierGenerating,
        domainBuilder: any CanonicalDomainBuilding
    ) {
        self.identifierGenerator = identifierGenerator
        self.domainBuilder = domainBuilder
    }

    public func build(
        from translatedMessage: TranslatedMessage,
        preservedContent: PreservedOriginalContent
    ) throws -> CanonicalBuildResult {
        Self.logger.info(
            "build entered. connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public) externalMessageID=\(translatedMessage.externalMessageID, privacy: .public)"
        )

        guard translatedMessage.externalMessageID.isEmpty == false else {
            Self.logger.error(
                "build failed. reason=missing_external_message_id connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public)"
            )
            throw CanonicalMessageBuilderError.missingExternalMessageID
        }

        if preservedContent.metadata.accountID != translatedMessage.accountID {
            Self.logger.error(
                "build failed. reason=preserved_account_mismatch externalMessageID=\(translatedMessage.externalMessageID, privacy: .public)"
            )
            throw CanonicalMessageBuilderError.preservedAccountMismatch(
                expected: translatedMessage.accountID,
                actual: preservedContent.metadata.accountID
            )
        }

        if preservedContent.metadata.connectorID != translatedMessage.connectorID {
            Self.logger.error(
                "build failed. reason=preserved_connector_mismatch externalMessageID=\(translatedMessage.externalMessageID, privacy: .public)"
            )
            throw CanonicalMessageBuilderError.preservedConnectorMismatch(
                expected: translatedMessage.connectorID,
                actual: preservedContent.metadata.connectorID
            )
        }

        if preservedContent.metadata.externalMessageID != translatedMessage.externalMessageID {
            Self.logger.error(
                "build failed. reason=preserved_external_message_id_mismatch externalMessageID=\(translatedMessage.externalMessageID, privacy: .public)"
            )
            throw CanonicalMessageBuilderError.preservedExternalMessageIDMismatch(
                expected: translatedMessage.externalMessageID,
                actual: preservedContent.metadata.externalMessageID
            )
        }

        if preservedContent.attachments.count != translatedMessage.attachments.count {
            Self.logger.error(
                "build failed. reason=preserved_attachment_count_mismatch externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) translatedCount=\(translatedMessage.attachments.count, privacy: .public) preservedCount=\(preservedContent.attachments.count, privacy: .public)"
            )
            throw CanonicalMessageBuilderError.preservedAttachmentCountMismatch(
                expected: translatedMessage.attachments.count,
                actual: preservedContent.attachments.count
            )
        }

        let messageID: MessageID = self.identifierGenerator.makeMessageID(
            accountID: translatedMessage.accountID,
            connectorID: translatedMessage.connectorID,
            externalMessageID: translatedMessage.externalMessageID
        )

        let attachmentIDs: [AttachmentID] = preservedContent.attachments.enumerated().map { index, attachment in
            self.identifierGenerator.makeAttachmentID(
                messageID: messageID,
                externalAttachmentID: attachment.externalAttachmentID,
                index: index
            )
        }

        Self.logger.debug(
            "build decision. externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) participantCount=\(translatedMessage.participants.count, privacy: .public) attachmentCount=\(attachmentIDs.count, privacy: .public) reason=construct_canonical_facts_only"
        )

        let messageSeed: CanonicalMessageBuilder.MessageSeed = CanonicalMessageBuilder.MessageSeed(
            id: messageID,
            accountID: translatedMessage.accountID,
            subject: translatedMessage.subject,
            sentAt: translatedMessage.sentAt,
            receivedAt: translatedMessage.receivedAt,
            attachmentIDs: attachmentIDs,
            externalMessageID: translatedMessage.externalMessageID,
            messageIDHeader: translatedMessage.replyContext.messageIDHeader,
            inReplyTo: translatedMessage.replyContext.inReplyTo,
            references: translatedMessage.replyContext.references
        )

        let messageBodySeed: CanonicalMessageBuilder.MessageBodySeed = CanonicalMessageBuilder.MessageBodySeed(
            messageID: messageID,
            plainText: preservedContent.plainText,
            html: preservedContent.html,
            previewText: preservedContent.previewText,
            rawSource: preservedContent.rawSource
        )

        let participantSeeds: [CanonicalMessageBuilder.ParticipantSeed] = translatedMessage.participants.map { participant in
            CanonicalMessageBuilder.ParticipantSeed(
                messageID: messageID,
                address: participant.address,
                displayName: participant.displayName,
                role: Self.mapParticipantRole(participant.role)
            )
        }

        let attachmentSeeds: [CanonicalMessageBuilder.AttachmentSeed] = zip(attachmentIDs, preservedContent.attachments).map { attachmentID, attachment in
            CanonicalMessageBuilder.AttachmentSeed(
                id: attachmentID,
                messageID: messageID,
                fileName: attachment.fileName,
                mimeType: attachment.mimeType,
                byteCount: attachment.byteCount,
                inline: attachment.inline,
                contentID: attachment.contentID,
                sourceURL: attachment.sourceURL,
                rawData: attachment.rawData
            )
        }

        Self.logger.debug(
            "build before side effect. externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) reason=invoke_domain_factories"
        )

        let message: Message = try self.domainBuilder.makeMessage(from: messageSeed)
        let messageBody: MessageBody = try self.domainBuilder.makeMessageBody(from: messageBodySeed)
        let participants: [Participant] = try participantSeeds.map { seed in
            try self.domainBuilder.makeParticipant(from: seed)
        }
        let attachments: [Attachment] = try attachmentSeeds.map { seed in
            try self.domainBuilder.makeAttachment(from: seed)
        }

        let result: CanonicalBuildResult = CanonicalBuildResult(
            message: message,
            messageBody: messageBody,
            participants: participants,
            attachments: attachments
        )

        Self.logger.debug(
            "build after side effect. externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) participantCount=\(participants.count, privacy: .public) attachmentCount=\(attachments.count, privacy: .public)"
        )

        return result
    }

    private static func mapParticipantRole(
        _ role: TranslatedMessage.Participant.Role
    ) -> CanonicalMessageBuilder.ParticipantSeed.Role {
        switch role {
        case .from:
            return .from
        case .to:
            return .to
        case .cc:
            return .cc
        case .bcc:
            return .bcc
        case .replyTo:
            return .replyTo
        }
    }
}
