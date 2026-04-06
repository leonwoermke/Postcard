import Foundation
import GRDB
import OSLog

public final class MessageRepositoryGRDB: MessageRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.MessageRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ message: Message) async throws {
        logger.debug(
            "save(message) entered. messageID=\(message.id.rawValue.uuidString, privacy: .public) mode=detail reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                logger.debug(
                    "save(message) write begin. messageID=\(message.id.rawValue.uuidString, privacy: .public) participantCount=\(message.participants.count, privacy: .public)"
                )

                try MessageRecord(domain: message).save(db)
                try MessageBodyRecord(messageID: message.id, body: message.body).save(db)

                try ParticipantRecord
                    .filter(ParticipantRecord.Columns.messageID == message.id.rawValue.uuidString)
                    .deleteAll(db)

                for participant in message.participants {
                    try ParticipantRecord(messageID: message.id, participant: participant).save(db)
                }

                logger.debug(
                    "save(message) write complete. messageID=\(message.id.rawValue.uuidString, privacy: .public)"
                )
            }
        } catch {
            logger.error(
                "save(message) failed. messageID=\(message.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ messages: [Message]) async throws {
        logger.debug(
            "save(messages) entered. count=\(messages.count, privacy: .public) mode=batch reason=upsert"
        )

        guard !messages.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for message in messages {
                    try MessageRecord(domain: message).save(db)
                    try MessageBodyRecord(messageID: message.id, body: message.body).save(db)

                    try ParticipantRecord
                        .filter(ParticipantRecord.Columns.messageID == message.id.rawValue.uuidString)
                        .deleteAll(db)

                    for participant in message.participants {
                        try ParticipantRecord(messageID: message.id, participant: participant).save(db)
                    }
                }
            }
        } catch {
            logger.error(
                "save(messages) failed. count=\(messages.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(id: MessageID) async throws -> Message {
        logger.debug(
            "fetch(id:) entered. messageID=\(id.rawValue.uuidString, privacy: .public) mode=detail reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let messageRecord = try MessageRecord
                    .filter(MessageRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Message", identifier: id.rawValue.uuidString)
                }

                guard let bodyRecord = try MessageBodyRecord
                    .filter(MessageBodyRecord.Columns.messageID == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "MessageBody", identifier: id.rawValue.uuidString)
                }

                let participantRecords = try ParticipantRecord
                    .filter(ParticipantRecord.Columns.messageID == id.rawValue.uuidString)
                    .fetchAll(db)

                let participants: [Participant] = participantRecords.map { $0.asDomain() }

                return try messageRecord.asDomain(
                    body: bodyRecord.asDomain(),
                    participants: participants
                )
            }
        } catch {
            logger.error(
                "fetch(id:) failed. messageID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(ids: [MessageID]) async throws -> [Message] {
        logger.debug(
            "fetch(ids:) entered. count=\(ids.count, privacy: .public) mode=detail reason=batch_fetch"
        )

        guard !ids.isEmpty else { return [] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = ids.map { $0.rawValue.uuidString }

                let messageRecords = try MessageRecord
                    .filter(rawIDs.contains(MessageRecord.Columns.id))
                    .fetchAll(db)

                let bodyRecords = try MessageBodyRecord
                    .filter(rawIDs.contains(MessageBodyRecord.Columns.messageID))
                    .fetchAll(db)

                let participantRecords = try ParticipantRecord
                    .filter(rawIDs.contains(ParticipantRecord.Columns.messageID))
                    .fetchAll(db)

                let bodyByMessageID = Dictionary(uniqueKeysWithValues: bodyRecords.map { ($0.messageID, $0) })
                let participantsByMessageID = Dictionary(grouping: participantRecords, by: \.messageID)

                var results: [Message] = []
                results.reserveCapacity(messageRecords.count)

                for messageRecord in messageRecords {
                    guard let bodyRecord = bodyByMessageID[messageRecord.id] else {
                        throw RepositoryFailure.integrityViolation(
                            reason: "Missing MessageBody for message \(messageRecord.id)"
                        )
                    }

                    let participants: [Participant] = (participantsByMessageID[messageRecord.id] ?? []).map { $0.asDomain() }

                    results.append(
                        try messageRecord.asDomain(
                            body: bodyRecord.asDomain(),
                            participants: participants
                        )
                    )
                }

                return results
            }
        } catch {
            logger.error(
                "fetch(ids:) failed. count=\(ids.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func listPreviews(
        in roomID: RoomID,
        limit: Int,
        before: Date?
    ) async throws -> [MessagePreview] {
        logger.debug(
            "listPreviews entered. roomID=\(roomID.rawValue.uuidString, privacy: .public) limit=\(limit, privacy: .public) mode=preview reason=room_list"
        )

        guard limit > 0 else { return [] }

        do {
            return try databaseContainer.reader { db in
                let assignmentRecords = try AssignmentRecord
                    .filter(AssignmentRecord.Columns.roomID == roomID.rawValue.uuidString)
                    .fetchAll(db)

                let messageIDs = assignmentRecords.map(\.messageID)
                guard !messageIDs.isEmpty else { return [] }

                let messageRecords = try MessageRecord
                    .filter(messageIDs.contains(MessageRecord.Columns.id))
                    .fetchAll(db)

                let bodyRecords = try MessageBodyRecord
                    .filter(messageIDs.contains(MessageBodyRecord.Columns.messageID))
                    .fetchAll(db)

                let participantRecords = try ParticipantRecord
                    .filter(messageIDs.contains(ParticipantRecord.Columns.messageID))
                    .fetchAll(db)

                let bodyByMessageID = Dictionary(uniqueKeysWithValues: bodyRecords.map { ($0.messageID, $0) })
                let participantsByMessageID = Dictionary(grouping: participantRecords, by: \.messageID)

                let filteredSorted = messageRecords
                    .filter { record in
                        guard let before else { return true }
                        return record.previewDate < before
                    }
                    .sorted { $0.previewDate > $1.previewDate }
                    .prefix(limit)

                return try filteredSorted.map { record in
                    let participants: [Participant] = (participantsByMessageID[record.id] ?? []).map { $0.asDomain() }
                    let bodyPreview = bodyByMessageID[record.id]?.previewText
                    return try record.asPreview(
                        participants: participants,
                        bodyPreview: bodyPreview
                    )
                }
            }
        } catch {
            logger.error(
                "listPreviews failed. roomID=\(roomID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchPreview(id: MessageID) async throws -> MessagePreview {
        logger.debug(
            "fetchPreview entered. messageID=\(id.rawValue.uuidString, privacy: .public) mode=preview reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let messageRecord = try MessageRecord
                    .filter(MessageRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Message", identifier: id.rawValue.uuidString)
                }

                let bodyRecord = try MessageBodyRecord
                    .filter(MessageBodyRecord.Columns.messageID == id.rawValue.uuidString)
                    .fetchOne(db)

                let participantRecords = try ParticipantRecord
                    .filter(ParticipantRecord.Columns.messageID == id.rawValue.uuidString)
                    .fetchAll(db)

                let participants: [Participant] = participantRecords.map { $0.asDomain() }

                return try messageRecord.asPreview(
                    participants: participants,
                    bodyPreview: bodyRecord?.previewText
                )
            }
        } catch {
            logger.error(
                "fetchPreview failed. messageID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func delete(id: MessageID) async throws {
        logger.debug(
            "delete entered. messageID=\(id.rawValue.uuidString, privacy: .public) mode=detail reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                try ParticipantRecord
                    .filter(ParticipantRecord.Columns.messageID == id.rawValue.uuidString)
                    .deleteAll(db)

                try MessageBodyRecord
                    .filter(MessageBodyRecord.Columns.messageID == id.rawValue.uuidString)
                    .deleteAll(db)

                try AttachmentRecord
                    .filter(AttachmentRecord.Columns.messageID == id.rawValue.uuidString)
                    .deleteAll(db)

                _ = try MessageRecord
                    .filter(MessageRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "delete failed. messageID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }
}

private extension MessageRecord {
    var previewDate: Date {
        sentAt ?? receivedAt ?? .distantPast
    }

    func asPreview(
        participants: [Participant],
        bodyPreview: String?
    ) throws -> MessagePreview {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(MessageRecord.Columns.id.name): \(id)")
            )
        }

        guard let decodedAccountID = UUID(uuidString: accountID) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(MessageRecord.Columns.accountID.name): \(accountID)")
            )
        }

        return MessagePreview(
            id: MessageID(rawValue: decodedID),
            accountID: AccountID(rawValue: decodedAccountID),
            subject: subject,
            participants: participants,
            sentAt: sentAt,
            receivedAt: receivedAt,
            direction: direction == .inbound ? .inbound : .outbound,
            bodyPreview: bodyPreview
        )
    }
}

private enum RepositoryFailure: LocalizedError {
    case notFound(entity: String, identifier: String)
    case integrityViolation(reason: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let entity, let identifier):
            return "\(entity) not found for identifier \(identifier)"
        case .integrityViolation(let reason):
            return "Integrity violation: \(reason)"
        }
    }
}
