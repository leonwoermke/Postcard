import Foundation
import GRDB

public struct AdaptiveProfileRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "adaptive_profiles"

    public enum Columns {
        public static let id = Column("id")
        public static let accountID = Column("account_id")
        public static let roomID = Column("room_id")
        public static let senderAddress = Column("sender_address")
        public static let payload = Column("payload")
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountID = "account_id"
        case roomID = "room_id"
        case senderAddress = "sender_address"
        case payload
    }
    
    public let id: String
    public let accountID: String?
    public let roomID: String?
    public let senderAddress: String?
    public let payload: Data

    public init(id: AdaptiveProfileID, adaptiveProfile: AdaptiveProfile) throws {
        self.id = id.rawValue.uuidString
        self.accountID = adaptiveProfile.accountID.rawValue.uuidString

        switch adaptiveProfile.scope {
        case .room(let roomID):
            self.roomID = roomID.rawValue.uuidString
            self.senderAddress = nil
        case .senderAddress(let senderAddress):
            self.roomID = nil
            self.senderAddress = senderAddress
        case .pattern, .global:
            self.roomID = nil
            self.senderAddress = nil
        }

        self.payload = try StorageCoding.encodePayload(AdaptiveProfilePayload(adaptiveProfile))
    }

    public init(domain adaptiveProfile: AdaptiveProfile) throws {
        try self.init(id: adaptiveProfile.id, adaptiveProfile: adaptiveProfile)
    }

    public func toDomain() throws -> AdaptiveProfile {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        let decodedPayload = try StorageCoding.decodePayload(
            AdaptiveProfilePayload.self,
            from: payload
        )
        return try decodedPayload.toDomain(id: AdaptiveProfileID(rawValue: decodedID))
    }

    public func asDomain() throws -> AdaptiveProfile {
        try toDomain()
    }
}

private struct AdaptiveProfilePayload: Codable, Sendable {
    let accountID: String
    let scope: AdaptiveProfileScopePayload
    let tendencies: [AdaptiveProfileTendencyPayload]
    let evidenceCount: Int
    let decayMetadata: AdaptiveProfileDecayMetadataPayload

    init(_ profile: AdaptiveProfile) {
        self.accountID = profile.accountID.rawValue.uuidString
        self.scope = AdaptiveProfileScopePayload(profile.scope)
        self.tendencies = profile.tendencies.map(AdaptiveProfileTendencyPayload.init)
        self.evidenceCount = profile.evidenceCount
        self.decayMetadata = AdaptiveProfileDecayMetadataPayload(profile.decayMetadata)
    }

    func toDomain(id: AdaptiveProfileID) throws -> AdaptiveProfile {
        guard let accountUUID = UUID(uuidString: accountID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid accountID: \(accountID)")
            )
        }

        return AdaptiveProfile(
            id: id,
            accountID: AccountID(rawValue: accountUUID),
            scope: try scope.toDomain(),
            tendencies: try tendencies.map { try $0.toDomain() },
            evidenceCount: evidenceCount,
            decayMetadata: decayMetadata.toDomain()
        )
    }
}

private struct AdaptiveProfileScopePayload: Codable, Sendable {
    let tag: String
    let senderAddress: String?
    let pattern: String?
    let roomID: String?

    init(_ scope: AdaptiveProfile.Scope) {
        switch scope {
        case .senderAddress(let value):
            self.tag = "senderAddress"
            self.senderAddress = value
            self.pattern = nil
            self.roomID = nil
        case .pattern(let value):
            self.tag = "pattern"
            self.senderAddress = nil
            self.pattern = value
            self.roomID = nil
        case .room(let roomID):
            self.tag = "room"
            self.senderAddress = nil
            self.pattern = nil
            self.roomID = roomID.rawValue.uuidString
        case .global:
            self.tag = "global"
            self.senderAddress = nil
            self.pattern = nil
            self.roomID = nil
        }
    }

    func toDomain() throws -> AdaptiveProfile.Scope {
        switch tag {
        case "senderAddress":
            return .senderAddress(senderAddress ?? "")
        case "pattern":
            return .pattern(pattern ?? "")
        case "room":
            guard let roomID, let uuid = UUID(uuidString: roomID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid AdaptiveProfile.Scope.roomID"))
            }
            return .room(RoomID(rawValue: uuid))
        default:
            return .global
        }
    }
}

private struct AdaptiveProfileDecayMetadataPayload: Codable, Sendable {
    let lastUpdatedAt: Date
    let decayRate: AdaptiveProfile.DecayRate?

    init(_ value: AdaptiveProfile.DecayMetadata) {
        self.lastUpdatedAt = value.lastUpdatedAt
        self.decayRate = value.decayRate
    }

    func toDomain() -> AdaptiveProfile.DecayMetadata {
        AdaptiveProfile.DecayMetadata(
            lastUpdatedAt: lastUpdatedAt,
            decayRate: decayRate
        )
    }
}

private struct AdaptiveProfileBlockKindBiasPayload: Codable, Hashable, Sendable {
    let tag: String
    let otherValue: String?

    init(_ value: AdaptiveProfile.BlockKindBias) {
        switch value {
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

    func toDomain() -> AdaptiveProfile.BlockKindBias {
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

private struct AdaptiveProfileTendencyPayload: Codable, Sendable {
    let tag: String
    let messageKind: MessageKind?
    let blockKindBias: AdaptiveProfileBlockKindBiasPayload?
    let entityKind: EntityKind?
    let actionKind: ActionKind?
    let roomID: String?
    let weight: AdaptiveProfile.Weight

    init(_ tendency: AdaptiveProfile.Tendency) {
        switch tendency {
        case .messageKindBias(let messageKind, let weight):
            self.tag = "messageKindBias"
            self.messageKind = messageKind
            self.blockKindBias = nil
            self.entityKind = nil
            self.actionKind = nil
            self.roomID = nil
            self.weight = weight

        case .blockKindBias(let blockKindBias, let weight):
            self.tag = "blockKindBias"
            self.messageKind = nil
            self.blockKindBias = AdaptiveProfileBlockKindBiasPayload(blockKindBias)
            self.entityKind = nil
            self.actionKind = nil
            self.roomID = nil
            self.weight = weight

        case .entityKindBias(let entityKind, let weight):
            self.tag = "entityKindBias"
            self.messageKind = nil
            self.blockKindBias = nil
            self.entityKind = entityKind
            self.actionKind = nil
            self.roomID = nil
            self.weight = weight

        case .actionKindBias(let actionKind, let weight):
            self.tag = "actionKindBias"
            self.messageKind = nil
            self.blockKindBias = nil
            self.entityKind = nil
            self.actionKind = actionKind
            self.roomID = nil
            self.weight = weight

        case .assignmentRoomBias(let roomID, let weight):
            self.tag = "assignmentRoomBias"
            self.messageKind = nil
            self.blockKindBias = nil
            self.entityKind = nil
            self.actionKind = nil
            self.roomID = roomID.rawValue.uuidString
            self.weight = weight

        case .collapseBias(let weight):
            self.tag = "collapseBias"
            self.messageKind = nil
            self.blockKindBias = nil
            self.entityKind = nil
            self.actionKind = nil
            self.roomID = nil
            self.weight = weight

        case .elevateBias(let weight):
            self.tag = "elevateBias"
            self.messageKind = nil
            self.blockKindBias = nil
            self.entityKind = nil
            self.actionKind = nil
            self.roomID = nil
            self.weight = weight

        case .suppressBias(let weight):
            self.tag = "suppressBias"
            self.messageKind = nil
            self.blockKindBias = nil
            self.entityKind = nil
            self.actionKind = nil
            self.roomID = nil
            self.weight = weight
        }
    }

    func toDomain() throws -> AdaptiveProfile.Tendency {
        switch tag {
        case "messageKindBias":
            return .messageKindBias(messageKind ?? .unknown, weight: weight)
        case "blockKindBias":
            return .blockKindBias(blockKindBias?.toDomain() ?? .unknown, weight: weight)
        case "entityKindBias":
            return .entityKindBias(entityKind ?? .unknown, weight: weight)
        case "actionKindBias":
            return .actionKindBias(actionKind ?? .unknown, weight: weight)
        case "assignmentRoomBias":
            guard let roomID, let uuid = UUID(uuidString: roomID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid AdaptiveProfile.Tendency.roomID"))
            }
            return .assignmentRoomBias(RoomID(rawValue: uuid), weight: weight)
        case "collapseBias":
            return .collapseBias(weight: weight)
        case "elevateBias":
            return .elevateBias(weight: weight)
        case "suppressBias":
            return .suppressBias(weight: weight)
        default:
            return .collapseBias(weight: .neutral)
        }
    }
}
