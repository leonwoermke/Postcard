import Foundation

public struct Block: Equatable, Hashable, Sendable {
    public struct Boundary: Equatable, Hashable, Sendable, Codable {
        public let sourceBoundary: BlockID.SourceBoundary

        public init(sourceBoundary: BlockID.SourceBoundary) {
            self.sourceBoundary = sourceBoundary
        }
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
