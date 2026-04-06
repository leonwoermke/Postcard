import Foundation
import GRDB
import OSLog

public final class OrganizationRepositoryGRDB: OrganizationRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.OrganizationRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ organization: Organization) async throws {
        logger.debug(
            "save(organization) entered. organizationID=\(organization.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try OrganizationRecord(domain: organization).save(db)
            }
        } catch {
            logger.error(
                "save(organization) failed. organizationID=\(organization.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ organizations: [Organization]) async throws {
        logger.debug(
            "save(organizations) entered. count=\(organizations.count, privacy: .public) reason=batch_upsert"
        )

        guard !organizations.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for organization in organizations {
                    try OrganizationRecord(domain: organization).save(db)
                }
            }
        } catch {
            logger.error(
                "save(organizations) failed. count=\(organizations.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(id: OrganizationID) async throws -> Organization {
        logger.debug(
            "fetch(id:) entered. organizationID=\(id.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try OrganizationRecord
                    .filter(OrganizationRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Organization", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetch(id:) failed. organizationID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(ids: [OrganizationID]) async throws -> [Organization] {
        logger.debug(
            "fetch(ids:) entered. count=\(ids.count, privacy: .public) reason=batch_fetch"
        )

        guard !ids.isEmpty else { return [] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = ids.map { $0.rawValue.uuidString }
                let records = try OrganizationRecord
                    .filter(rawIDs.contains(OrganizationRecord.Columns.id))
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

    public func fetchAll() async throws -> [Organization] {
        logger.debug("fetchAll entered. reason=administrative_fetch")

        do {
            return try databaseContainer.reader { db in
                let records = try OrganizationRecord.fetchAll(db)
                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchAll failed. error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func delete(id: OrganizationID) async throws {
        logger.debug(
            "delete entered. organizationID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try OrganizationRecord
                    .filter(OrganizationRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "delete failed. organizationID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
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
