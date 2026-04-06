import Foundation
import GRDB

public struct EntityInterpretationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "entity_interpretations"

    public enum Columns {
        public static let entityID = Column("entity_id")
        public static let messageID = Column("message_id")
        public static let sourceDescriptor = Column("source_descriptor")
        public static let payload = Column("payload")
    }

    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case messageID = "message_id"
        case sourceDescriptor = "source_descriptor"
        case payload
    }

    public let entityID: String
    public let messageID: String
    public let sourceDescriptor: Data
    public let payload: Data

    public init(entityID: EntityID, interpretation: EntityInterpretation) throws {
        self.entityID = entityID.rawValue
        self.messageID = entityID.sourceDescriptor.messageID.rawValue.uuidString
        self.sourceDescriptor = try StorageCoding.encodePayload(entityID.sourceDescriptor)
        self.payload = try StorageCoding.encodePayload(EntityInterpretationPayload(interpretation))
    }

    public init(domain interpretation: EntityInterpretation) throws {
        try self.init(entityID: interpretation.entityID, interpretation: interpretation)
    }

    public func toDomain() throws -> EntityInterpretation {
        let decodedSourceDescriptor = try StorageCoding.decodePayload(
            EntityID.SourceDescriptor.self,
            from: sourceDescriptor
        )

        let decodedPayload = try StorageCoding.decodePayload(
            EntityInterpretationPayload.self,
            from: payload
        )

        return decodedPayload.toDomain(
            entityID: EntityID(
                rawValue: entityID,
                sourceDescriptor: decodedSourceDescriptor
            )
        )
    }

    public func asDomain() throws -> EntityInterpretation {
        try toDomain()
    }
}

private struct EntityInterpretationPayload: Codable, Sendable {
    struct ResolutionPayload: Codable, Sendable {
        enum Kind: String, Codable, Sendable {
            case resolved
            case ambiguous
            case unknown
        }

        let kind: Kind
        let resolved: EntityKind?
        let ambiguous: [EntityKind]?

        init(_ value: InterpretationResolution<EntityKind>) {
            switch value {
            case .resolved(let candidate):
                self.kind = .resolved
                self.resolved = candidate
                self.ambiguous = nil
            case .ambiguous(let candidates):
                self.kind = .ambiguous
                self.resolved = nil
                self.ambiguous = candidates
            case .unknown:
                self.kind = .unknown
                self.resolved = nil
                self.ambiguous = nil
            }
        }

        func toDomain() -> InterpretationResolution<EntityKind> {
            switch kind {
            case .resolved:
                return resolved.map(InterpretationResolution.resolved) ?? .unknown
            case .ambiguous:
                return .ambiguous(ambiguous ?? [])
            case .unknown:
                return .unknown
            }
        }
    }

    let confidence: Confidence
    let resolution: ResolutionPayload
    let relatedActions: [ActionKind]
    let expiryContext: ExpiryContext?
    let summary: String?

    init(_ interpretation: EntityInterpretation) {
        self.confidence = interpretation.confidence
        self.resolution = ResolutionPayload(interpretation.resolution)
        self.relatedActions = interpretation.relatedActions
        self.expiryContext = interpretation.expiryContext
        self.summary = interpretation.summary
    }

    func toDomain(entityID: EntityID) -> EntityInterpretation {
        EntityInterpretation(
            entityID: entityID,
            confidence: confidence,
            resolution: resolution.toDomain(),
            relatedActions: relatedActions,
            expiryContext: expiryContext,
            summary: summary
        )
    }
}
