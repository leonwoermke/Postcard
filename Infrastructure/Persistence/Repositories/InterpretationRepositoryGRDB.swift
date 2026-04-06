import Foundation
import GRDB
import OSLog

public final class InterpretationRepositoryGRDB: InterpretationRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.InterpretationRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ interpretation: MessageInterpretation) async throws {
        logger.debug(
            "save(messageInterpretation) entered. messageID=\(interpretation.messageID.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try MessageInterpretationRecord(domain: interpretation).save(db)
            }
        } catch {
            logger.error(
                "save(messageInterpretation) failed. messageID=\(interpretation.messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchMessageInterpretation(for messageID: MessageID) async throws -> MessageInterpretation {
        logger.debug(
            "fetchMessageInterpretation entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try MessageInterpretationRecord
                    .filter(MessageInterpretationRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "MessageInterpretation", identifier: messageID.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetchMessageInterpretation failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ interpretation: BlockInterpretation) async throws {
        logger.debug(
            "save(blockInterpretation) entered. blockID=\(interpretation.blockID.rawValue, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try BlockInterpretationRecord(domain: interpretation).save(db)
            }
        } catch {
            logger.error(
                "save(blockInterpretation) failed. blockID=\(interpretation.blockID.rawValue, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchBlockInterpretations(for messageID: MessageID) async throws -> [BlockInterpretation] {
        logger.debug(
            "fetchBlockInterpretations entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try BlockInterpretationRecord
                    .filter(BlockInterpretationRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchBlockInterpretations failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ interpretation: EntityInterpretation) async throws {
        logger.debug(
            "save(entityInterpretation) entered. entityID=\(interpretation.entityID.rawValue, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try EntityInterpretationRecord(domain: interpretation).save(db)
            }
        } catch {
            logger.error(
                "save(entityInterpretation) failed. entityID=\(interpretation.entityID.rawValue, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchEntityInterpretations(for messageID: MessageID) async throws -> [EntityInterpretation] {
        logger.debug(
            "fetchEntityInterpretations entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try EntityInterpretationRecord
                    .filter(EntityInterpretationRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchEntityInterpretations failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ interpretation: AttachmentInterpretation) async throws {
        logger.debug(
            "save(attachmentInterpretation) entered. attachmentID=\(interpretation.attachmentID.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try AttachmentInterpretationRecord(domain: interpretation).save(db)
            }
        } catch {
            logger.error(
                "save(attachmentInterpretation) failed. attachmentID=\(interpretation.attachmentID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAttachmentInterpretation(for attachmentID: AttachmentID) async throws -> AttachmentInterpretation {
        logger.debug(
            "fetchAttachmentInterpretation entered. attachmentID=\(attachmentID.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try AttachmentInterpretationRecord
                    .filter(AttachmentInterpretationRecord.Columns.attachmentID == attachmentID.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "AttachmentInterpretation", identifier: attachmentID.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetchAttachmentInterpretation failed. attachmentID=\(attachmentID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAttachmentInterpretations(for messageID: MessageID) async throws -> [AttachmentInterpretation] {
        logger.debug(
            "fetchAttachmentInterpretations entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let sql = """
                SELECT ai.*
                FROM \(AttachmentInterpretationRecord.databaseTableName) ai
                INNER JOIN \(AttachmentRecord.databaseTableName) a
                    ON ai.\(AttachmentInterpretationRecord.Columns.attachmentID.name) = a.\(AttachmentRecord.Columns.id.name)
                WHERE a.\(AttachmentRecord.Columns.messageID.name) = ?
                """

                let records = try AttachmentInterpretationRecord.fetchAll(
                    db,
                    sql: sql,
                    arguments: [messageID.rawValue.uuidString]
                )

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchAttachmentInterpretations failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteMessageInterpretation(for messageID: MessageID) async throws {
        logger.debug(
            "deleteMessageInterpretation entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try MessageInterpretationRecord
                    .filter(MessageInterpretationRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteMessageInterpretation failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteBlockInterpretations(for messageID: MessageID) async throws {
        logger.debug(
            "deleteBlockInterpretations entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try BlockInterpretationRecord
                    .filter(BlockInterpretationRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteBlockInterpretations failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteEntityInterpretations(for messageID: MessageID) async throws {
        logger.debug(
            "deleteEntityInterpretations entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try EntityInterpretationRecord
                    .filter(EntityInterpretationRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteEntityInterpretations failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteAttachmentInterpretation(for attachmentID: AttachmentID) async throws {
        logger.debug(
            "deleteAttachmentInterpretation entered. attachmentID=\(attachmentID.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try AttachmentInterpretationRecord
                    .filter(AttachmentInterpretationRecord.Columns.attachmentID == attachmentID.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteAttachmentInterpretation failed. attachmentID=\(attachmentID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
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
