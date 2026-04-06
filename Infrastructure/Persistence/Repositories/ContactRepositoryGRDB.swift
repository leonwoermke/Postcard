import Foundation
import GRDB
import OSLog

public final class ContactRepositoryGRDB: ContactRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.ContactRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ contact: Contact) async throws {
        logger.debug(
            "save(contact) entered. contactID=\(contact.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try ContactRecord(domain: contact).save(db)
            }
        } catch {
            logger.error(
                "save(contact) failed. contactID=\(contact.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ contacts: [Contact]) async throws {
        logger.debug(
            "save(contacts) entered. count=\(contacts.count, privacy: .public) reason=batch_upsert"
        )

        guard !contacts.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for contact in contacts {
                    try ContactRecord(domain: contact).save(db)
                }
            }
        } catch {
            logger.error(
                "save(contacts) failed. count=\(contacts.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(id: ContactID) async throws -> Contact {
        logger.debug(
            "fetch(id:) entered. contactID=\(id.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try ContactRecord
                    .filter(ContactRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Contact", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetch(id:) failed. contactID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(ids: [ContactID]) async throws -> [Contact] {
        logger.debug(
            "fetch(ids:) entered. count=\(ids.count, privacy: .public) reason=batch_fetch"
        )

        guard !ids.isEmpty else { return [] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = ids.map { $0.rawValue.uuidString }
                let records = try ContactRecord
                    .filter(rawIDs.contains(ContactRecord.Columns.id))
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

    public func fetchAll() async throws -> [Contact] {
        logger.debug("fetchAll entered. reason=administrative_fetch")

        do {
            return try databaseContainer.reader { db in
                let records = try ContactRecord.fetchAll(db)
                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchAll failed. error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func delete(id: ContactID) async throws {
        logger.debug(
            "delete entered. contactID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try ContactRecord
                    .filter(ContactRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "delete failed. contactID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
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
