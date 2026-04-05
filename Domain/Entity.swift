import Foundation

public struct Entity: Equatable, Hashable, Sendable {
    public struct SourceRegion: Equatable, Hashable, Sendable, Codable {
        public let sourceRegion: EntityID.SourceRegion

        public init(sourceRegion: EntityID.SourceRegion) {
            self.sourceRegion = sourceRegion
        }
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
