import Foundation
import GRDB
import OSLog

public final class AttachmentRepositoryGRDB: AttachmentRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.AttachmentRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ attachment: Attachment) async throws {
        logger.debug(
            "save(attachment) entered. attachmentID=\(attachment.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try AttachmentRecord(domain: attachment).save(db)
            }
        } catch {
            logger.error(
                "save(attachment) failed. attachmentID=\(attachment.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ attachments: [Attachment]) async throws {
        logger.debug(
            "save(attachments) entered. count=\(attachments.count, privacy: .public) reason=batch_upsert"
        )

        guard !attachments.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for attachment in attachments {
                    try AttachmentRecord(domain: attachment).save(db)
                }
            }
        } catch {
            logger.error(
                "save(attachments) failed. count=\(attachments.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(id: AttachmentID) async throws -> Attachment {
        logger.debug(
            "fetch(id:) entered. attachmentID=\(id.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try AttachmentRecord
                    .filter(AttachmentRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Attachment", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetch(id:) failed. attachmentID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(ids: [AttachmentID]) async throws -> [Attachment] {
        logger.debug(
            "fetch(ids:) entered. count=\(ids.count, privacy: .public) reason=batch_fetch"
        )

        guard !ids.isEmpty else { return [] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = ids.map { $0.rawValue.uuidString }
                let records = try AttachmentRecord
                    .filter(rawIDs.contains(AttachmentRecord.Columns.id))
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetch(ids:) failed. count=\(ids.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(byMessageID messageID: MessageID) async throws -> [Attachment] {
        logger.debug(
            "fetch(byMessageID:) entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try AttachmentRecord
                    .filter(AttachmentRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetch(byMessageID:) failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func delete(id: AttachmentID) async throws {
        logger.debug(
            "delete entered. attachmentID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try AttachmentRecord
                    .filter(AttachmentRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "delete failed. attachmentID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }
}

private enum RepositoryFailure: LocalizedError {
    case notFound(entity: String, identifier: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let entity, let identifier):
            return "\(entity) not found for identifier \(identifier)"
        }
    }
}
