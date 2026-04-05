import Foundation

public struct Block: Equatable, Hashable, Sendable {
    public struct Boundary: Equatable, Hashable, Sendable {
        public let contentForm: ContentForm
        public let range: Range<Int>

        public init(
            contentForm: ContentForm,
            range: Range<Int>
        ) {
            self.contentForm = contentForm
            self.range = range
        }
    }

    public enum ContentForm: Equatable, Hashable, Sendable {
        case plainText
        case html
        case normalizedText
    }

    public let id: BlockID
    public let messageID: MessageID
    public let orderIndex: Int
    public let boundary: Boundary
    public let rawContent: String

    public init(
        id: BlockID,
        messageID: MessageID,
        orderIndex: Int,
        boundary: Boundary,
        rawContent: String
    ) {
        self.id = id
        self.messageID = messageID
        self.orderIndex = orderIndex
        self.boundary = boundary
        self.rawContent = rawContent
    }
}
