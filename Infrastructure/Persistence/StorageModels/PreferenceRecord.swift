import Foundation
import GRDB

public struct PreferenceRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "preferences"

    public enum Columns {
        public static let id = Column("id")
        public static let accountID = Column("account_id")
        public static let payload = Column("payload")
    }

    public let id: String
    public let accountID: String?
    public let payload: Data

    public init(id: PreferenceID, preference: Preference) throws {
        self.id = id.rawValue.uuidString

        switch preference.scope {
        case .account(let accountID):
            self.accountID = accountID.rawValue.uuidString
        case .global, .unknown, .other:
            self.accountID = nil
        }

        self.payload = try StorageCoding.encodePayload(PreferencePayload(preference))
    }

    public init(domain preference: Preference) throws {
        try self.init(id: preference.id, preference: preference)
    }

    public func toDomain() throws -> Preference {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        let decodedPayload = try StorageCoding.decodePayload(PreferencePayload.self, from: payload)
        return try decodedPayload.toDomain(id: PreferenceID(rawValue: decodedID))
    }

    public func asDomain() throws -> Preference {
        try toDomain()
    }
}

private struct PreferencePayload: Codable, Sendable {
    let scope: ScopePayload
    let kind: KindPayload
    let value: ValuePayload

    init(_ value: Preference) {
        self.scope = ScopePayload(value.scope)
        self.kind = KindPayload(value.kind)
        self.value = ValuePayload(value.value)
    }

    func toDomain(id: PreferenceID) throws -> Preference {
        Preference(
            id: id,
            scope: try scope.toDomain(),
            kind: kind.toDomain(),
            value: value.toDomain()
        )
    }
}

private struct ScopePayload: Codable, Sendable {
    let tag: String
    let accountID: String?
    let otherValue: String?

    init(_ scope: Preference.Scope) {
        switch scope {
        case .account(let accountID):
            self.tag = "account"
            self.accountID = accountID.rawValue.uuidString
            self.otherValue = nil
        case .global:
            self.tag = "global"
            self.accountID = nil
            self.otherValue = nil
        case .unknown:
            self.tag = "unknown"
            self.accountID = nil
            self.otherValue = nil
        case .other(let value):
            self.tag = "other"
            self.accountID = nil
            self.otherValue = value
        }
    }

    func toDomain() throws -> Preference.Scope {
        switch tag {
        case "account":
            guard let accountID, let uuid = UUID(uuidString: accountID) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Preference.Scope.accountID"))
            }
            return .account(AccountID(rawValue: uuid))
        case "global":
            return .global
        case "unknown":
            return .unknown
        case "other":
            return .other(otherValue ?? "")
        default:
            return .unknown
        }
    }
}

private struct KindPayload: Codable, Sendable {
    let tag: String
    let otherValue: String?

    init(_ kind: Preference.Kind) {
        switch kind {
        case .messageListDensity:
            self.tag = "messageListDensity"
            self.otherValue = nil
        case .roomDensity:
            self.tag = "roomDensity"
            self.otherValue = nil
        case .originalContentVisibility:
            self.tag = "originalContentVisibility"
            self.otherValue = nil
        case .ambiguityHandling:
            self.tag = "ambiguityHandling"
            self.otherValue = nil
        case .compositionGreetingStyle:
            self.tag = "compositionGreetingStyle"
            self.otherValue = nil
        case .compositionClosingStyle:
            self.tag = "compositionClosingStyle"
            self.otherValue = nil
        case .compositionSignatureTemplate:
            self.tag = "compositionSignatureTemplate"
            self.otherValue = nil
        case .compositionFooterEnabled:
            self.tag = "compositionFooterEnabled"
            self.otherValue = nil
        case .quotedThreadInclusion:
            self.tag = "quotedThreadInclusion"
            self.otherValue = nil
        case .unknown:
            self.tag = "unknown"
            self.otherValue = nil
        case .other(let value):
            self.tag = "other"
            self.otherValue = value
        }
    }

    func toDomain() -> Preference.Kind {
        switch tag {
        case "messageListDensity": return .messageListDensity
        case "roomDensity": return .roomDensity
        case "originalContentVisibility": return .originalContentVisibility
        case "ambiguityHandling": return .ambiguityHandling
        case "compositionGreetingStyle": return .compositionGreetingStyle
        case "compositionClosingStyle": return .compositionClosingStyle
        case "compositionSignatureTemplate": return .compositionSignatureTemplate
        case "compositionFooterEnabled": return .compositionFooterEnabled
        case "quotedThreadInclusion": return .quotedThreadInclusion
        case "unknown": return .unknown
        case "other": return .other(otherValue ?? "")
        default: return .unknown
        }
    }
}

private struct ValuePayload: Codable, Sendable {
    let tag: String
    let boolValue: Bool?
    let stringValue: String?
    let otherValue: String?

    init(_ value: Preference.Value) {
        switch value {
        case .boolean(let value):
            self.tag = "boolean"
            self.boolValue = value
            self.stringValue = nil
            self.otherValue = nil
        case .string(let value):
            self.tag = "string"
            self.boolValue = nil
            self.stringValue = value
            self.otherValue = nil
        case .selection(let value):
            self.tag = "selection"
            self.boolValue = nil
            self.stringValue = value
            self.otherValue = nil
        case .unknown:
            self.tag = "unknown"
            self.boolValue = nil
            self.stringValue = nil
            self.otherValue = nil
        case .other(let value):
            self.tag = "other"
            self.boolValue = nil
            self.stringValue = nil
            self.otherValue = value
        }
    }

    func toDomain() -> Preference.Value {
        switch tag {
        case "boolean": return .boolean(boolValue ?? false)
        case "string": return .string(stringValue ?? "")
        case "selection": return .selection(stringValue ?? "")
        case "unknown": return .unknown
        case "other": return .other(otherValue ?? "")
        default: return .unknown
        }
    }
}
