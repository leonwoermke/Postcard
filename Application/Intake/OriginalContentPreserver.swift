import Foundation
import OSLog

public enum OriginalContentPreservationError: Error, Sendable {
    case missingStableExternalIdentifier
}

public struct PreservedOriginalContent: Sendable {
    public struct Availability: Sendable {
        public let hasRawSource: Bool
        public let hasPlainText: Bool
        public let hasHTML: Bool
        public let hasPreviewText: Bool
        public let hasHeaders: Bool
        public let hasAttachments: Bool

        public init(
            hasRawSource: Bool,
            hasPlainText: Bool,
            hasHTML: Bool,
            hasPreviewText: Bool,
            hasHeaders: Bool,
            hasAttachments: Bool
        ) {
            self.hasRawSource = hasRawSource
            self.hasPlainText = hasPlainText
            self.hasHTML = hasHTML
            self.hasPreviewText = hasPreviewText
            self.hasHeaders = hasHeaders
            self.hasAttachments = hasAttachments
        }
    }

    public struct PreservationMetadata: Sendable {
        public let connectorID: ConnectorID
        public let accountID: AccountID
        public let externalMessageID: String
        public let preservedAt: Date
        public let externalThreadReference: String?
        public let externalLabels: [String]
        public let externalMetadata: [String: String]

        public init(
            connectorID: ConnectorID,
            accountID: AccountID,
            externalMessageID: String,
            preservedAt: Date,
            externalThreadReference: String?,
            externalLabels: [String],
            externalMetadata: [String: String]
        ) {
            self.connectorID = connectorID
            self.accountID = accountID
            self.externalMessageID = externalMessageID
            self.preservedAt = preservedAt
            self.externalThreadReference = externalThreadReference
            self.externalLabels = externalLabels
            self.externalMetadata = externalMetadata
        }
    }

    public struct PreservedAttachment: Sendable {
        public let externalAttachmentID: String
        public let fileName: String?
        public let mimeType: String?
        public let byteCount: Int?
        public let inline: Bool
        public let contentID: String?
        public let sourceURL: URL?
        public let rawData: Data?

        public init(
            externalAttachmentID: String,
            fileName: String?,
            mimeType: String?,
            byteCount: Int?,
            inline: Bool,
            contentID: String?,
            sourceURL: URL?,
            rawData: Data?
        ) {
            self.externalAttachmentID = externalAttachmentID
            self.fileName = fileName
            self.mimeType = mimeType
            self.byteCount = byteCount
            self.inline = inline
            self.contentID = contentID
            self.sourceURL = sourceURL
            self.rawData = rawData
        }
    }

    public let metadata: PreservationMetadata
    public let rawSource: Data?
    public let plainText: String?
    public let html: String?
    public let previewText: String?
    public let headers: [TranslatedMessage.Header]
    public let attachments: [PreservedAttachment]
    public let availability: Availability

    public init(
        metadata: PreservationMetadata,
        rawSource: Data?,
        plainText: String?,
        html: String?,
        previewText: String?,
        headers: [TranslatedMessage.Header],
        attachments: [PreservedAttachment],
        availability: Availability
    ) {
        self.metadata = metadata
        self.rawSource = rawSource
        self.plainText = plainText
        self.html = html
        self.previewText = previewText
        self.headers = headers
        self.attachments = attachments
        self.availability = availability
    }
}

public protocol OriginalContentPreserving: Sendable {
    func preserve(from translatedMessage: TranslatedMessage) throws -> PreservedOriginalContent
}

public protocol OriginalContentPreserverClock: Sendable {
    func now() -> Date
}

public struct SystemOriginalContentPreserverClock: OriginalContentPreserverClock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

public final class OriginalContentPreserver: OriginalContentPreserving {
    private static let logger: Logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.OriginalContentPreserver"
    )

    private let clock: any OriginalContentPreserverClock

    public init(clock: any OriginalContentPreserverClock = SystemOriginalContentPreserverClock()) {
        self.clock = clock
    }

    public func preserve(from translatedMessage: TranslatedMessage) throws -> PreservedOriginalContent {
        Self.logger.info(
            "preserve entered. connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public) externalMessageID=\(translatedMessage.externalMessageID, privacy: .public)"
        )

        guard translatedMessage.externalMessageID.isEmpty == false else {
            Self.logger.error(
                "preserve failed. reason=missing_external_message_id connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public)"
            )
            throw OriginalContentPreservationError.missingStableExternalIdentifier
        }

        let rawSource: Data? = translatedMessage.originalContent.rawSource
        let plainText: String? = translatedMessage.body.plainText
        let html: String? = translatedMessage.body.html
        let previewText: String? = translatedMessage.body.previewText
        let headers: [TranslatedMessage.Header] = translatedMessage.headers

        let hasRawSource: Bool = rawSource != nil
        let hasPlainText: Bool = plainText != nil
        let hasHTML: Bool = html != nil
        let hasPreviewText: Bool = previewText != nil
        let hasHeaders: Bool = headers.isEmpty == false
        let hasAttachments: Bool = translatedMessage.attachments.isEmpty == false

        Self.logger.debug(
            """
            preserve decision. connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public) \
            externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) \
            hasRawSource=\(hasRawSource, privacy: .public) \
            hasPlainText=\(hasPlainText, privacy: .public) \
            hasHTML=\(hasHTML, privacy: .public) \
            hasPreviewText=\(hasPreviewText, privacy: .public) \
            attachmentCount=\(translatedMessage.attachments.count, privacy: .public) \
            reason=preserve_all_available_factual_forms
            """
        )

        let preservedAttachments: [PreservedOriginalContent.PreservedAttachment] = translatedMessage.attachments.map { attachment in
            PreservedOriginalContent.PreservedAttachment(
                externalAttachmentID: attachment.externalAttachmentID,
                fileName: attachment.fileName,
                mimeType: attachment.mimeType,
                byteCount: attachment.byteCount,
                inline: attachment.inline,
                contentID: attachment.contentID,
                sourceURL: attachment.sourceURL,
                rawData: attachment.rawData
            )
        }

        let preservedAt: Date = self.clock.now()

        let metadata: PreservedOriginalContent.PreservationMetadata = PreservedOriginalContent.PreservationMetadata(
            connectorID: translatedMessage.connectorID,
            accountID: translatedMessage.accountID,
            externalMessageID: translatedMessage.externalMessageID,
            preservedAt: preservedAt,
            externalThreadReference: translatedMessage.originalContent.externalThreadReference,
            externalLabels: translatedMessage.originalContent.externalLabels,
            externalMetadata: translatedMessage.originalContent.externalMetadata
        )

        let availability: PreservedOriginalContent.Availability = PreservedOriginalContent.Availability(
            hasRawSource: hasRawSource,
            hasPlainText: hasPlainText,
            hasHTML: hasHTML,
            hasPreviewText: hasPreviewText,
            hasHeaders: hasHeaders,
            hasAttachments: hasAttachments
        )

        Self.logger.debug(
            "preserve before side effect. connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public) externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) reason=construct_preserved_output"
        )

        let preservedContent: PreservedOriginalContent = PreservedOriginalContent(
            metadata: metadata,
            rawSource: rawSource,
            plainText: plainText,
            html: html,
            previewText: previewText,
            headers: headers,
            attachments: preservedAttachments,
            availability: availability
        )

        Self.logger.debug(
            "preserve after side effect. connectorID=\(translatedMessage.connectorID.rawValue, privacy: .public) externalMessageID=\(translatedMessage.externalMessageID, privacy: .public) preservedAttachmentCount=\(preservedAttachments.count, privacy: .public)"
        )

        return preservedContent
    }
}
