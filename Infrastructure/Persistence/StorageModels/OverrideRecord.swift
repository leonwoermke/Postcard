import Foundation
import GRDB

public struct OverrideRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "overrides"

    public enum Columns {
        public static let id = Column("id")
        public static let scopeKind = Column("scope_kind")
        public static let messageID = Column("message_id")
        public static let roomID = Column("room_id")
        public static let blockID = Column("block_id")
        public static let entityID = Column("entity_id")
        public static let payload = Column("payload")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case scopeKind = "scope_kind"
        case messageID = "message_id"
        case roomID = "room_id"
        case blockID = "block_id"
        case entityID = "entity_id"
        case payload
    }

    public let id: String
    public let scopeKind: String
    public let messageID: String?
    public let roomID: String?
    public let blockID: String?
    public let entityID: String?
    public let payload: Data

    public init(id: OverrideID, override overrideValue: Override) throws {
        self.id = id.rawValue.uuidString

        let scopePayload = OverrideScopePayload(overrideValue.scope)
        self.scopeKind = scopePayload.tag
        self.messageID = scopePayload.indexMessageID
        self.roomID = scopePayload.indexRoomID
        self.blockID = scopePayload.indexBlockID
        self.entityID = scopePayload.indexEntityID

        self.payload = try StorageCoding.encodePayload(OverridePayloadRecord(overrideValue))
    }

    public init(domain overrideValue: Override) throws {
        try self.init(id: overrideValue.id, override: overrideValue)
    }

    public func toDomain() throws -> Override {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        let decodedPayload = try StorageCoding.decodePayload(
            OverridePayloadRecord.self,
            from: payload
        )

        return try decodedPayload.toDomain(id: OverrideID(rawValue: decodedID))
    }

    public func asDomain() throws -> Override {
        try toDomain()
    }
}

private struct OverridePayloadRecord: Codable, Sendable {
    let scope: OverrideScopePayload
    let payload: OverridePayloadPayload
    let createdAt: Date
    let updatedAt: Date

    init(_ overrideValue: Override) {
        self.scope = OverrideScopePayload(overrideValue.scope)
        self.payload = OverridePayloadPayload(overrideValue.payload)
        self.createdAt = overrideValue.createdAt
        self.updatedAt = overrideValue.updatedAt
    }

    func toDomain(id: OverrideID) throws -> Override {
        Override(
            id: id,
            scope: try scope.toDomain(),
            payload: try payload.toDomain(),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct OverrideScopePayload: Codable, Sendable {
    let tag: String

    let messageID: String?
    let roomID: String?

    let blockRawValue: String?
    let blockMessageID: String?
    let blockSourceBoundary: Data?

    let entityRawValue: String?
    let entitySourceDescriptor: Data?

    let assignmentMessageID: String?
    let senderAddress: String?
    let pattern: String?

    var indexMessageID: String? {
        switch tag {
        case "message":
            return messageID
        case "assignment":
            return assignmentMessageID
        default:
            return nil
        }
    }

    var indexRoomID: String? {
        switch tag {
        case "room":
            return roomID
        default:
            return nil
        }
    }

    var indexBlockID: String? {
        switch tag {
        case "block":
            return blockRawValue
        default:
            return nil
        }
    }

    var indexEntityID: String? {
        switch tag {
        case "entity":
            return entityRawValue
        default:
            return nil
        }
    }

    init(_ scope: Override.Scope) {
        switch scope {
        case .message(let id):
            self.tag = "message"
            self.messageID = id.rawValue.uuidString
            self.roomID = nil
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = nil
            self.senderAddress = nil
            self.pattern = nil

        case .block(let id):
            self.tag = "block"
            self.messageID = nil
            self.roomID = nil
            self.blockRawValue = id.rawValue
            self.blockMessageID = id.messageID.rawValue.uuidString
            self.blockSourceBoundary = try? StorageCoding.encodePayload(id.sourceBoundary)
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = nil
            self.senderAddress = nil
            self.pattern = nil

        case .entity(let id):
            self.tag = "entity"
            self.messageID = nil
            self.roomID = nil
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = id.rawValue
            self.entitySourceDescriptor = try? StorageCoding.encodePayload(id.sourceDescriptor)
            self.assignmentMessageID = nil
            self.senderAddress = nil
            self.pattern = nil

        case .room(let id):
            self.tag = "room"
            self.messageID = nil
            self.roomID = id.rawValue.uuidString
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = nil
            self.senderAddress = nil
            self.pattern = nil

        case .assignment(let id):
            self.tag = "assignment"
            self.messageID = nil
            self.roomID = nil
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = id.rawValue.uuidString
            self.senderAddress = nil
            self.pattern = nil

        case .senderAddress(let value):
            self.tag = "senderAddress"
            self.messageID = nil
            self.roomID = nil
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = nil
            self.senderAddress = value
            self.pattern = nil

        case .pattern(let value):
            self.tag = "pattern"
            self.messageID = nil
            self.roomID = nil
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = nil
            self.senderAddress = nil
            self.pattern = value

        case .global:
            self.tag = "global"
            self.messageID = nil
            self.roomID = nil
            self.blockRawValue = nil
            self.blockMessageID = nil
            self.blockSourceBoundary = nil
            self.entityRawValue = nil
            self.entitySourceDescriptor = nil
            self.assignmentMessageID = nil
            self.senderAddress = nil
            self.pattern = nil
        }
    }

    func toDomain() throws -> Override.Scope {
        switch tag {
        case "message":
            guard let messageID, let uuid = UUID(uuidString: messageID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Override.Scope.messageID"))
            }
            return .message(MessageID(rawValue: uuid))

        case "block":
            guard let blockMessageID,
                  let messageUUID = UUID(uuidString: blockMessageID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Override.Scope.blockMessageID"))
            }

            let sourceBoundary = try StorageCoding.decodePayload(
                BlockID.SourceBoundary.self,
                from: blockSourceBoundary ?? Data()
            )

            return .block(
                BlockID(
                    rawValue: blockRawValue ?? "",
                    messageID: MessageID(rawValue: messageUUID),
                    sourceBoundary: sourceBoundary
                )
            )

        case "entity":
            let sourceDescriptor = try StorageCoding.decodePayload(
                EntityID.SourceDescriptor.self,
                from: entitySourceDescriptor ?? Data()
            )

            return .entity(
                EntityID(
                    rawValue: entityRawValue ?? "",
                    sourceDescriptor: sourceDescriptor
                )
            )

        case "room":
            guard let roomID, let uuid = UUID(uuidString: roomID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Override.Scope.roomID"))
            }
            return .room(RoomID(rawValue: uuid))

        case "assignment":
            guard let assignmentMessageID, let uuid = UUID(uuidString: assignmentMessageID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Override.Scope.assignmentMessageID"))
            }
            return .assignment(MessageID(rawValue: uuid))

        case "senderAddress":
            return .senderAddress(senderAddress ?? "")

        case "pattern":
            return .pattern(pattern ?? "")

        default:
            return .global
        }
    }
}

private struct OverridePayloadPayload: Codable, Sendable {
    let tag: String
    let messageKindResolution: MessageKindResolutionPayload?
    let blockKindResolution: BlockKindResolutionPayload?
    let entityKindResolution: EntityKindResolutionPayload?
    let assignmentRoomID: String?
    let assignmentClusterID: String?

    init(_ payload: Override.Payload) {
        switch payload {
        case .messageKind(let resolution):
            self.tag = "messageKind"
            self.messageKindResolution = MessageKindResolutionPayload(resolution)
            self.blockKindResolution = nil
            self.entityKindResolution = nil
            self.assignmentRoomID = nil
            self.assignmentClusterID = nil

        case .blockKind(let resolution):
            self.tag = "blockKind"
            self.messageKindResolution = nil
            self.blockKindResolution = BlockKindResolutionPayload(resolution)
            self.entityKindResolution = nil
            self.assignmentRoomID = nil
            self.assignmentClusterID = nil

        case .entityKind(let resolution):
            self.tag = "entityKind"
            self.messageKindResolution = nil
            self.blockKindResolution = nil
            self.entityKindResolution = EntityKindResolutionPayload(resolution)
            self.assignmentRoomID = nil
            self.assignmentClusterID = nil

        case .assignment(let roomID, let clusterID):
            self.tag = "assignment"
            self.messageKindResolution = nil
            self.blockKindResolution = nil
            self.entityKindResolution = nil
            self.assignmentRoomID = roomID.rawValue.uuidString
            self.assignmentClusterID = clusterID?.rawValue.uuidString
        }
    }

    func toDomain() throws -> Override.Payload {
        switch tag {
        case "messageKind":
            return .messageKind(messageKindResolution?.toDomain() ?? .unknown)

        case "blockKind":
            return .blockKind(blockKindResolution?.toDomain() ?? .unknown)

        case "entityKind":
            return .entityKind(entityKindResolution?.toDomain() ?? .unknown)

        case "assignment":
            guard let assignmentRoomID,
                  let roomUUID = UUID(uuidString: assignmentRoomID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Override.Payload.assignmentRoomID"))
            }

            let cluster = assignmentClusterID.flatMap(UUID.init(uuidString:)).map(ClusterID.init(rawValue:))

            return .assignment(
                roomID: RoomID(rawValue: roomUUID),
                clusterID: cluster
            )

        default:
            return .messageKind(.unknown)
        }
    }
}

private struct MessageKindResolutionPayload: Codable, Sendable {
    let tag: String
    let resolved: MessageKind?
    let ambiguous: [MessageKind]?

    init(_ resolution: InterpretationResolution<MessageKind>) {
        switch resolution {
        case .resolved(let value):
            self.tag = "resolved"
            self.resolved = value
            self.ambiguous = nil
        case .ambiguous(let values):
            self.tag = "ambiguous"
            self.resolved = nil
            self.ambiguous = values
        case .unknown:
            self.tag = "unknown"
            self.resolved = nil
            self.ambiguous = nil
        }
    }

    func toDomain() -> InterpretationResolution<MessageKind> {
        switch tag {
        case "resolved":
            return resolved.map { .resolved($0) } ?? .unknown
        case "ambiguous":
            return .ambiguous(ambiguous ?? [])
        default:
            return .unknown
        }
    }
}

private struct EntityKindResolutionPayload: Codable, Sendable {
    let tag: String
    let resolved: EntityKind?
    let ambiguous: [EntityKind]?

    init(_ resolution: InterpretationResolution<EntityKind>) {
        switch resolution {
        case .resolved(let value):
            self.tag = "resolved"
            self.resolved = value
            self.ambiguous = nil
        case .ambiguous(let values):
            self.tag = "ambiguous"
            self.resolved = nil
            self.ambiguous = values
        case .unknown:
            self.tag = "unknown"
            self.resolved = nil
            self.ambiguous = nil
        }
    }

    func toDomain() -> InterpretationResolution<EntityKind> {
        switch tag {
        case "resolved":
            return resolved.map { .resolved($0) } ?? .unknown
        case "ambiguous":
            return .ambiguous(ambiguous ?? [])
        default:
            return .unknown
        }
    }
}

private struct BlockKindResolutionPayload: Codable, Sendable {
    let tag: String
    let resolved: BlockKindPayload?
    let ambiguous: [BlockKindPayload]?

    init(_ resolution: InterpretationResolution<BlockInterpretation.Kind>) {
        switch resolution {
        case .resolved(let value):
            self.tag = "resolved"
            self.resolved = BlockKindPayload(value)
            self.ambiguous = nil
        case .ambiguous(let values):
            self.tag = "ambiguous"
            self.resolved = nil
            self.ambiguous = values.map(BlockKindPayload.init)
        case .unknown:
            self.tag = "unknown"
            self.resolved = nil
            self.ambiguous = nil
        }
    }

    func toDomain() -> InterpretationResolution<BlockInterpretation.Kind> {
        switch tag {
        case "resolved":
            return resolved.map { .resolved($0.toDomain()) } ?? .unknown
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
