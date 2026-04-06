import Foundation
import GRDB
import OSLog

public final class RoomRepositoryGRDB: RoomRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.RoomRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ room: Room) async throws {
        logger.debug(
            "save(room) entered. roomID=\(room.id.rawValue.uuidString, privacy: .public) mode=detail reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try RoomRecord(domain: room).save(db)
            }
        } catch {
            logger.error(
                "save(room) failed. roomID=\(room.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ rooms: [Room]) async throws {
        logger.debug(
            "save(rooms) entered. count=\(rooms.count, privacy: .public) mode=batch reason=upsert"
        )

        guard !rooms.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for room in rooms {
                    try RoomRecord(domain: room).save(db)
                }
            }
        } catch {
            logger.error(
                "save(rooms) failed. count=\(rooms.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(id: RoomID) async throws -> Room {
        logger.debug(
            "fetch(id:) entered. roomID=\(id.rawValue.uuidString, privacy: .public) mode=detail reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try RoomRecord
                    .filter(RoomRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Room", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetch(id:) failed. roomID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetch(ids: [RoomID]) async throws -> [Room] {
        logger.debug(
            "fetch(ids:) entered. count=\(ids.count, privacy: .public) mode=detail reason=batch_fetch"
        )

        guard !ids.isEmpty else { return [] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = ids.map { $0.rawValue.uuidString }
                let records = try RoomRecord
                    .filter(rawIDs.contains(RoomRecord.Columns.id))
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

    public func fetchLookup(by id: RoomID) async throws -> RoomLookup {
        logger.debug(
            "fetchLookup(by:) entered. roomID=\(id.rawValue.uuidString, privacy: .public) mode=lookup reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try RoomRecord
                    .select(
                        RoomRecord.Columns.id,
                        RoomRecord.Columns.anchorKind,
                        RoomRecord.Columns.contactID,
                        RoomRecord.Columns.organizationID,
                        RoomRecord.Columns.title,
                        RoomRecord.Columns.anchorTitle
                    )
                    .filter(RoomRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "RoomLookup", identifier: id.rawValue.uuidString)
                }

                return try record.asLookup()
            }
        } catch {
            logger.error(
                "fetchLookup(by:) failed. roomID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchLookups(by ids: [RoomID]) async throws -> [RoomLookup] {
        logger.debug(
            "fetchLookups(by:) entered. count=\(ids.count, privacy: .public) mode=lookup reason=batch_fetch"
        )

        guard !ids.isEmpty else { return [] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = ids.map { $0.rawValue.uuidString }
                let records = try RoomRecord
                    .select(
                        RoomRecord.Columns.id,
                        RoomRecord.Columns.anchorKind,
                        RoomRecord.Columns.contactID,
                        RoomRecord.Columns.organizationID,
                        RoomRecord.Columns.title,
                        RoomRecord.Columns.anchorTitle
                    )
                    .filter(rawIDs.contains(RoomRecord.Columns.id))
                    .fetchAll(db)

                return try records.map { try $0.asLookup() }
            }
        } catch {
            logger.error(
                "fetchLookups(by:) failed. count=\(ids.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func delete(id: RoomID) async throws {
        logger.debug(
            "delete entered. roomID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try RoomRecord
                    .filter(RoomRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "delete failed. roomID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
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
