import Foundation

public struct Entity: Equatable, Hashable, Sendable {
    public struct SourceRegion: Equatable, Hashable, Sendable {
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

    public let id: EntityID
    public let messageID: MessageID
    public let blockID: BlockID?
    public let kind: EntityKind
    public let rawValue: String
    public let sourceRegion: SourceRegion?

    public init(
        id: EntityID,
        messageID: MessageID,
        blockID: BlockID? = nil,
        kind: EntityKind,
        rawValue: String,
        sourceRegion: SourceRegion? = nil
    ) {
        self.id = id
        self.messageID = messageID
        self.blockID = blockID
        self.kind = kind
        self.rawValue = rawValue
        self.sourceRegion = sourceRegion
    }
}
