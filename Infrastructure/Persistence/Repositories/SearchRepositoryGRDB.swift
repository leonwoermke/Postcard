import Foundation
import GRDB
import OSLog

public final class SearchRepositoryGRDB: SearchRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.SearchRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func search(
        query: String,
        scope: SearchScope,
        limit: Int
    ) async throws -> [MessagePreview] {
        logger.debug(
            "search entered. queryLength=\(query.count, privacy: .public) limit=\(limit, privacy: .public) mode=preview reason=search"
        )

        let ids = try await searchIDs(query: query, scope: scope, limit: limit)
        guard !ids.isEmpty else { return [] }

        let messageRepository = MessageRepositoryGRDB(databaseContainer: databaseContainer)
        var previews: [MessagePreview] = []
        previews.reserveCapacity(ids.count)

        for id in ids {
            previews.append(try await messageRepository.fetchPreview(id: id))
        }

        return previews
    }

    public func searchIDs(
        query: String,
        scope: SearchScope,
        limit: Int
    ) async throws -> [MessageID] {
        logger.debug(
            "searchIDs entered. queryLength=\(query.count, privacy: .public) limit=\(limit, privacy: .public) mode=ids reason=search"
        )

        guard !query.isEmpty, limit > 0 else { return [] }

        do {
            return try databaseContainer.reader { db in
                let candidateIDs = try candidateMessageIDs(scope: scope, db: db)
                guard !candidateIDs.isEmpty else { return [] }

                let normalizedQuery = query.lowercased()

                let messageRecords = try MessageRecord
                    .filter(candidateIDs.contains(MessageRecord.Columns.id))
                    .fetchAll(db)

                let bodyRecords = try MessageBodyRecord
                    .filter(candidateIDs.contains(MessageBodyRecord.Columns.messageID))
                    .fetchAll(db)

                let bodyByMessageID = Dictionary(uniqueKeysWithValues: bodyRecords.map { ($0.messageID, $0) })

                let filteredSorted = messageRecords
                    .filter { record in
                        let preview = bodyByMessageID[record.id]?.previewText.lowercased() ?? ""
                        let subject = record.subject?.lowercased() ?? ""
                        return subject.contains(normalizedQuery) || preview.contains(normalizedQuery)
                    }
                    .sorted { $0.previewDate > $1.previewDate }
                    .prefix(limit)

                return try filteredSorted.map { record in
                    guard let uuid = UUID(uuidString: record.id) else {
                        throw DecodingError.dataCorrupted(
                            .init(codingPath: [], debugDescription: "Invalid UUID for \(MessageRecord.Columns.id.name): \(record.id)")
                        )
                    }
                    return MessageID(rawValue: uuid)
                }
            }
        } catch {
            logger.error(
                "searchIDs failed. queryLength=\(query.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    private func candidateMessageIDs(scope: SearchScope, db: Database) throws -> [String] {
        switch scope {
        case .global:
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT id
                FROM messages
                """
            )

            return rows.map { row in
                row["id"]
            }

        case .room(let roomID):
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT message_id
                FROM assignments
                WHERE room_id = ?
                """,
                arguments: [roomID.rawValue.uuidString]
            )

            return rows.map { row in
                row["message_id"]
            }

        case .contact(let contactID):
            guard let contactRecord = try ContactRecord
                .filter(ContactRecord.Columns.id == contactID.rawValue.uuidString)
                .fetchOne(db)
            else {
                return []
            }

            let contact = try contactRecord.asDomain()
            let emails = contact.emailAddresses
            guard !emails.isEmpty else { return [] }

            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT message_id
                FROM participants
                WHERE address IN (\(databaseQuestionMarks(count: emails.count)))
                """,
                arguments: StatementArguments(emails)
            )

            return rows.map { row in
                row["message_id"]
            }
        }
    }

    private func databaseQuestionMarks(count: Int) -> String {
        Array(repeating: "?", count: count).joined(separator: ", ")
    }
}

private extension MessageRecord {
    var previewDate: Date {
        sentAt ?? receivedAt ?? .distantPast
    }
}
