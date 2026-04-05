import Foundation

public struct Attachment: Equatable, Hashable, Sendable {
    public let id: AttachmentID
    public let messageID: MessageID
    public let kind: AttachmentKind
    public let safetyClassification: SafetyClassification
    public let filename: String?
    public let mimeType: String?
    public let byteSize: Int?
    public let contentID: String?
    public let isInline: Bool

    public init(
        id: AttachmentID = AttachmentID(),
        messageID: MessageID,
        kind: AttachmentKind = .unknown,
        safetyClassification: SafetyClassification = .safe,
        filename: String? = nil,
        mimeType: String? = nil,
        byteSize: Int? = nil,
        contentID: String? = nil,
        isInline: Bool = false
    ) {
        self.id = id
        self.messageID = messageID
        self.kind = kind
        self.safetyClassification = safetyClassification
        self.filename = filename
        self.mimeType = mimeType
        self.byteSize = byteSize
        self.contentID = contentID
        self.isInline = isInline
    }
}
