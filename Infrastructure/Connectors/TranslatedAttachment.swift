import Foundation

public struct TranslatedAttachment: Sendable {
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
        fileName: String? = nil,
        mimeType: String? = nil,
        byteCount: Int? = nil,
        inline: Bool = false,
        contentID: String? = nil,
        sourceURL: URL? = nil,
        rawData: Data? = nil
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
