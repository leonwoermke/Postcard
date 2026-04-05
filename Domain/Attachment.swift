import Foundation

/// A canonical file artifact associated with a Message.
///
/// Attachment records only stable, observable facts about the file:
/// what kind of file it is (AttachmentKind), its metadata, and its
/// relationship to the Message.
///
/// Safety evaluation is contextual and risk-evaluative — it is not a
/// canonical fact. It lives in AttachmentInterpretation, which can be
/// revised independently without touching the canonical record.
public struct Attachment: Equatable, Hashable, Sendable {
    public let id: AttachmentID
    public let messageID: MessageID
    public let kind: AttachmentKind
    public let filename: String?
    public let mimeType: String?
    public let byteSize: Int?
    public let contentID: String?
    public let isInline: Bool

    public init(
        id: AttachmentID = AttachmentID(),
        messageID: MessageID,
        kind: AttachmentKind = .unknown,
        filename: String? = nil,
        mimeType: String? = nil,
        byteSize: Int? = nil,
        contentID: String? = nil,
        isInline: Bool = false
    ) {
        self.id = id
        self.messageID = messageID
        self.kind = kind
        self.filename = filename
        self.mimeType = mimeType
        self.byteSize = byteSize
        self.contentID = contentID
        self.isInline = isInline
    }
}
