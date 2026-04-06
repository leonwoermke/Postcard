import Foundation
import GRDB

public struct AttachmentInterpretationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "attachment_interpretations"

    public enum Columns {
        public static let attachmentID = Column("attachment_id")
        public static let payload = Column("payload")
    }

    enum CodingKeys: String, CodingKey {
        case attachmentID = "attachment_id"
        case payload
    }

    public let attachmentID: String
    public let payload: Data

    public init(attachmentID: AttachmentID, interpretation: AttachmentInterpretation) throws {
        self.attachmentID = attachmentID.rawValue.uuidString
        self.payload = try StorageCoding.encodePayload(AttachmentInterpretationPayload(interpretation))
    }

    public init(domain interpretation: AttachmentInterpretation) throws {
        try self.init(attachmentID: interpretation.attachmentID, interpretation: interpretation)
    }

    public func toDomain() throws -> AttachmentInterpretation {
        guard let decodedAttachmentID = UUID(uuidString: attachmentID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.attachmentID.name): \(attachmentID)")
            )
        }

        let decodedPayload = try StorageCoding.decodePayload(AttachmentInterpretationPayload.self, from: payload)
        return decodedPayload.toDomain(attachmentID: AttachmentID(rawValue: decodedAttachmentID))
    }

    public func asDomain() throws -> AttachmentInterpretation {
        try toDomain()
    }
}

private struct AttachmentInterpretationPayload: Codable, Sendable {
    let safetyClassification: SafetyClassification
    let confidence: Confidence
    let explanation: String?

    init(_ value: AttachmentInterpretation) {
        self.safetyClassification = value.safetyClassification
        self.confidence = value.confidence
        self.explanation = value.explanation
    }

    func toDomain(attachmentID: AttachmentID) -> AttachmentInterpretation {
        AttachmentInterpretation(
            attachmentID: attachmentID,
            safetyClassification: safetyClassification,
            confidence: confidence,
            explanation: explanation
        )
    }
}
