import Foundation
import GRDB

public struct LearningEventRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "learning_events"

    public enum Columns {
        public static let id = Column("id")
        public static let accountID = Column("account_id")
        public static let messageID = Column("message_id")
        public static let roomID = Column("room_id")
        public static let blockID = Column("block_id")
        public static let entityID = Column("entity_id")
        public static let senderAddress = Column("sender_address")
        public static let payload = Column("payload")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case accountID = "account_id"
        case messageID = "message_id"
        case roomID = "room_id"
        case blockID = "block_id"
        case entityID = "entity_id"
        case senderAddress = "sender_address"
        case payload
    }

    public let id: String
    public let accountID: String?
    public let messageID: String?
    public let roomID: String?
    public let blockID: String?
    public let entityID: String?
    public let senderAddress: String?
    public let payload: Data

    public init(id: LearningEventID, learningEvent: LearningEvent) throws {
        self.id = id.rawValue.uuidString
        self.accountID = nil

        let scope = LearningEventScopePayload(learningEvent.scope)
        self.messageID = scope.indexMessageID
        self.roomID = scope.indexRoomID
        self.blockID = scope.indexBlockID
        self.entityID = scope.indexEntityID
        self.senderAddress = scope.indexSenderAddress

        self.payload = try StorageCoding.encodePayload(LearningEventPayload(learningEvent))
    }

    public init(domain learningEvent: LearningEvent) throws {
        try self.init(id: learningEvent.id, learningEvent: learningEvent)
    }

    public func toDomain() throws -> LearningEvent {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        let decodedPayload = try StorageCoding.decodePayload(LearningEventPayload.self, from: payload)
        return try decodedPayload.toDomain(id: LearningEventID(rawValue: decodedID))
    }

    public func asDomain() throws -> LearningEvent {
        try toDomain()
    }
}

private struct LearningEventPayload: Codable, Sendable {
    let kind: LearningEventKindPayload
    let scope: LearningEventScopePayload
    let strength: LearningEventStrengthPayload
    let occurredAt: Date

    init(_ value: LearningEvent) {
        self.kind = LearningEventKindPayload(value.kind)
        self.scope = LearningEventScopePayload(value.scope)
        self.strength = LearningEventStrengthPayload(value.strength)
        self.occurredAt = value.occurredAt
    }

    func toDomain(id: LearningEventID) throws -> LearningEvent {
        LearningEvent(
            id: id,
            kind: kind.toDomain(),
            scope: try scope.toDomain(),
            strength: strength.toDomain(),
            occurredAt: occurredAt
        )
    }
}

private struct LearningEventScopePayload: Codable, Sendable {
    let tag: String

    let messageID: String?
    let roomID: String?

    let blockRawValue: String?
    let blockMessageID: String?
    let blockSourceBoundary: Data?

    let entityRawValue: String?
    let entitySourceDescriptor: Data?

    let senderAddress: String?
    let pattern: String?

    var indexMessageID: String? {
        switch tag {
        case "message":
            return messageID
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

    var indexSenderAddress: String? {
        switch tag {
        case "senderAddress":
            return senderAddress
        default:
            return nil
        }
    }

    init(_ scope: LearningEvent.Scope) {
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
            self.senderAddress = nil
            self.pattern = nil
        }
    }

    func toDomain() throws -> LearningEvent.Scope {
        switch tag {
        case "message":
            guard let messageID, let uuid = UUID(uuidString: messageID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid LearningEvent.Scope.messageID"))
            }
            return .message(MessageID(rawValue: uuid))

        case "room":
            guard let roomID, let uuid = UUID(uuidString: roomID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid LearningEvent.Scope.roomID"))
            }
            return .room(RoomID(rawValue: uuid))

        case "block":
            guard let blockMessageID,
                  let messageUUID = UUID(uuidString: blockMessageID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid LearningEvent.Scope.blockMessageID"))
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

        case "senderAddress":
            return .senderAddress(senderAddress ?? "")

        case "pattern":
            return .pattern(pattern ?? "")

        default:
            return .global
        }
    }
}

private enum LearningEventStrengthPayload: String, Codable, Sendable {
    case strong
    case weak

    init(_ value: LearningEvent.Strength) {
        switch value {
        case .strong:
            self = .strong
        case .weak:
            self = .weak
        }
    }

    func toDomain() -> LearningEvent.Strength {
        switch self {
        case .strong:
            return .strong
        case .weak:
            return .weak
        }
    }
}

private struct LearningEventKindPayload: Codable, Sendable {
    let tag: String
    let actionKind: ActionKind?

    init(_ value: LearningEvent.Kind) {
        switch value {
        case .correctedMessageInterpretation:
            self.tag = "correctedMessageInterpretation"
            self.actionKind = nil
        case .correctedBlockInterpretation:
            self.tag = "correctedBlockInterpretation"
            self.actionKind = nil
        case .correctedEntityInterpretation:
            self.tag = "correctedEntityInterpretation"
            self.actionKind = nil
        case .correctedAssignment:
            self.tag = "correctedAssignment"
            self.actionKind = nil
        case .expandedContent:
            self.tag = "expandedContent"
            self.actionKind = nil
        case .collapsedContent:
            self.tag = "collapsedContent"
            self.actionKind = nil
        case .dismissedContent:
            self.tag = "dismissedContent"
            self.actionKind = nil
        case .elevatedContent:
            self.tag = "elevatedContent"
            self.actionKind = nil
        case .interactedWithAction(let actionKind):
            self.tag = "interactedWithAction"
            self.actionKind = actionKind
        case .ignoredAction(let actionKind):
            self.tag = "ignoredAction"
            self.actionKind = actionKind
        }
    }

    func toDomain() -> LearningEvent.Kind {
        switch tag {
        case "correctedMessageInterpretation": return .correctedMessageInterpretation
        case "correctedBlockInterpretation": return .correctedBlockInterpretation
        case "correctedEntityInterpretation": return .correctedEntityInterpretation
        case "correctedAssignment": return .correctedAssignment
        case "expandedContent": return .expandedContent
        case "collapsedContent": return .collapsedContent
        case "dismissedContent": return .dismissedContent
        case "elevatedContent": return .elevatedContent
        case "interactedWithAction": return .interactedWithAction(actionKind ?? .unknown)
        case "ignoredAction": return .ignoredAction(actionKind ?? .unknown)
        default: return .dismissedContent
        }
    }
}
