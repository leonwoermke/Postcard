import Foundation
import GRDB

public struct MessageInterpretationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "message_interpretations"

    public enum Columns {
        public static let messageID = Column("message_id")
        public static let payload = Column("payload")
    }

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case payload
    }

    public let messageID: String
    public let payload: Data

    public init(messageID: MessageID, interpretation: MessageInterpretation) throws {
        self.messageID = messageID.rawValue.uuidString
        self.payload = try StorageCoding.encodePayload(MessageInterpretationPayload(interpretation))
    }

    public init(domain interpretation: MessageInterpretation) throws {
        try self.init(messageID: interpretation.messageID, interpretation: interpretation)
    }

    public func toDomain() throws -> MessageInterpretation {
        guard let decodedMessageID = UUID(uuidString: messageID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.messageID.name): \(messageID)")
            )
        }

        let decodedPayload = try StorageCoding.decodePayload(MessageInterpretationPayload.self, from: payload)
        return decodedPayload.toDomain(messageID: MessageID(rawValue: decodedMessageID))
    }

    public func asDomain() throws -> MessageInterpretation {
        try toDomain()
    }
}

private struct MessageInterpretationPayload: Codable, Sendable {
    enum ReplyExpectationPayload: String, Codable, Sendable {
        case expected
        case optional
        case notExpected
        case unknown

        init(_ value: MessageInterpretation.ReplyExpectation) {
            switch value {
            case .expected: self = .expected
            case .optional: self = .optional
            case .notExpected: self = .notExpected
            case .unknown: self = .unknown
            }
        }

        func toDomain() -> MessageInterpretation.ReplyExpectation {
            switch self {
            case .expected: return .expected
            case .optional: return .optional
            case .notExpected: return .notExpected
            case .unknown: return .unknown
            }
        }
    }

    struct ResolutionPayload<Candidate: Codable & Hashable & Sendable>: Codable, Sendable {
        enum Kind: String, Codable, Sendable {
            case resolved
            case ambiguous
            case unknown
        }

        let kind: Kind
        let resolved: Candidate?
        let ambiguous: [Candidate]?

        init(_ value: InterpretationResolution<Candidate>) {
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

        func toDomain() -> InterpretationResolution<Candidate> {
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
    let resolution: ResolutionPayload<MessageKind>
    let relatedActions: [ActionKind]
    let replyExpectation: ReplyExpectationPayload
    let summary: String?

    init(_ value: MessageInterpretation) {
        self.confidence = value.confidence
        self.resolution = ResolutionPayload(value.resolution)
        self.relatedActions = value.relatedActions
        self.replyExpectation = ReplyExpectationPayload(value.replyExpectation)
        self.summary = value.summary
    }

    func toDomain(messageID: MessageID) -> MessageInterpretation {
        MessageInterpretation(
            messageID: messageID,
            confidence: confidence,
            resolution: resolution.toDomain(),
            relatedActions: relatedActions,
            replyExpectation: replyExpectation.toDomain(),
            summary: summary
        )
    }
}
