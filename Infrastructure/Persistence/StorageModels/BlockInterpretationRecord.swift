import Foundation
import GRDB

public struct BlockInterpretationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "block_interpretations"

    public enum Columns {
        public static let blockID = Column("block_id")
        public static let messageID = Column("message_id")
        public static let sourceBoundary = Column("source_boundary")
        public static let payload = Column("payload")
    }

    enum CodingKeys: String, CodingKey {
        case blockID = "block_id"
        case messageID = "message_id"
        case sourceBoundary = "source_boundary"
        case payload
    }

    public let blockID: String
    public let messageID: String
    public let sourceBoundary: Data
    public let payload: Data

    public init(blockID: BlockID, interpretation: BlockInterpretation) throws {
        self.blockID = blockID.rawValue
        self.messageID = blockID.messageID.rawValue.uuidString
        self.sourceBoundary = try StorageCoding.encodePayload(blockID.sourceBoundary)
        self.payload = try StorageCoding.encodePayload(BlockInterpretationPayload(interpretation))
    }

    public init(domain interpretation: BlockInterpretation) throws {
        try self.init(blockID: interpretation.blockID, interpretation: interpretation)
    }

    public func toDomain() throws -> BlockInterpretation {
        let decodedMessageID: UUID
        if let uuid = UUID(uuidString: messageID) {
            decodedMessageID = uuid
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.messageID.name): \(messageID)")
            )
        }

        let decodedSourceBoundary = try StorageCoding.decodePayload(
            BlockID.SourceBoundary.self,
            from: sourceBoundary
        )

        let decodedBlockID = BlockID(
            rawValue: blockID,
            messageID: MessageID(rawValue: decodedMessageID),
            sourceBoundary: decodedSourceBoundary
        )

        let decodedPayload = try StorageCoding.decodePayload(
            BlockInterpretationPayload.self,
            from: payload
        )

        return decodedPayload.toDomain(blockID: decodedBlockID)
    }

    public func asDomain() throws -> BlockInterpretation {
        try toDomain()
    }
}

private struct BlockInterpretationPayload: Codable, Sendable {
    let confidence: Confidence
    let resolution: BlockKindResolutionPayload
    let summary: String?

    init(_ interpretation: BlockInterpretation) {
        self.confidence = interpretation.confidence
        self.resolution = BlockKindResolutionPayload(interpretation.resolution)
        self.summary = interpretation.summary
    }

    func toDomain(blockID: BlockID) -> BlockInterpretation {
        BlockInterpretation(
            blockID: blockID,
            confidence: confidence,
            resolution: resolution.toDomain(),
            summary: summary
        )
    }
}

private struct BlockKindResolutionPayload: Codable, Sendable {
    let tag: String
    let resolved: BlockKindPayload?
    let ambiguous: [BlockKindPayload]?

    init(_ resolution: InterpretationResolution<BlockInterpretation.Kind>) {
        switch resolution {
        case .resolved(let kind):
            self.tag = "resolved"
            self.resolved = BlockKindPayload(kind)
            self.ambiguous = nil
        case .ambiguous(let kinds):
            self.tag = "ambiguous"
            self.resolved = nil
            self.ambiguous = kinds.map(BlockKindPayload.init)
        case .unknown:
            self.tag = "unknown"
            self.resolved = nil
            self.ambiguous = nil
        }
    }

    func toDomain() -> InterpretationResolution<BlockInterpretation.Kind> {
        switch tag {
        case "resolved":
            if let resolved {
                return .resolved(resolved.toDomain())
            }
            return .unknown
        case "ambiguous":
            return .ambiguous((ambiguous ?? []).map { $0.toDomain() })
        default:
            return .unknown
        }
    }
}

private struct BlockKindPayload: Codable, Hashable, Sendable {
    let tag: String
    let otherValue: String?

    init(_ kind: BlockInterpretation.Kind) {
        switch kind {
        case .primaryContent:
            self.tag = "primaryContent"
            self.otherValue = nil
        case .supportingContent:
            self.tag = "supportingContent"
            self.otherValue = nil
        case .quote:
            self.tag = "quote"
            self.otherValue = nil
        case .signatureLike:
            self.tag = "signatureLike"
            self.otherValue = nil
        case .tabular:
            self.tag = "tabular"
            self.otherValue = nil
        case .actionCluster:
            self.tag = "actionCluster"
            self.otherValue = nil
        case .boilerplate:
            self.tag = "boilerplate"
            self.otherValue = nil
        case .unknown:
            self.tag = "unknown"
            self.otherValue = nil
        case .other(let value):
            self.tag = "other"
            self.otherValue = value
        }
    }

    func toDomain() -> BlockInterpretation.Kind {
        switch tag {
        case "primaryContent": return .primaryContent
        case "supportingContent": return .supportingContent
        case "quote": return .quote
        case "signatureLike": return .signatureLike
        case "tabular": return .tabular
        case "actionCluster": return .actionCluster
        case "boilerplate": return .boilerplate
        case "unknown": return .unknown
        case "other": return .other(otherValue ?? "")
        default: return .unknown
        }
    }
}
