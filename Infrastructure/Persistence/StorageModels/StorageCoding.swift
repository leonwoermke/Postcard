// Postcard/Infrastructure/Persistence/StorageModels/StorageCoding.swift

import Foundation

enum StorageCoding {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    static func encodePayload<Value: Encodable>(_ value: Value) throws -> Data {
        try encoder.encode(value)
    }

    static func decodePayload<Value: Decodable>(
        _ type: Value.Type,
        from data: Data
    ) throws -> Value {
        try decoder.decode(type, from: data)
    }

    static func decodeUUID(_ value: String, field: String) throws -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(field): \(value)")
            )
        }

        return uuid
    }

    static func decodeOptionalUUID(_ value: String?, field: String) throws -> UUID? {
        guard let value else { return nil }
        return try decodeUUID(value, field: field)
    }

    static func decodeConfidence(_ value: Double, field: String) throws -> Confidence {
        guard let confidence = Confidence(value) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid Confidence for \(field): \(value)")
            )
        }

        return confidence
    }

    static func stableParticipantStorageID(
        messageID: MessageID,
        participant: Participant
    ) -> String {
        let displayName = participant.displayName ?? ""
        return [
            messageID.rawValue.uuidString.lowercased(),
            encodeParticipantRole(participant.role),
            participant.address.lowercased(),
            displayName.lowercased()
        ].joined(separator: "|")
    }

    private static func encodeParticipantRole(_ role: Participant.Role) -> String {
        switch role {
        case .from: return "from"
        case .to: return "to"
        case .cc: return "cc"
        case .bcc: return "bcc"
        case .replyTo: return "replyTo"
        }
    }
}
