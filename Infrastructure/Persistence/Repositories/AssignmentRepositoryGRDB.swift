import Foundation
import GRDB
import OSLog

public final class AssignmentRepositoryGRDB: AssignmentRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.AssignmentRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ assignment: Assignment) async throws {
        logger.debug(
            "save(assignment) entered. assignmentID=\(assignment.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try AssignmentRecord(domain: assignment).save(db)
            }
        } catch {
            logger.error(
                "save(assignment) failed. assignmentID=\(assignment.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ assignments: [Assignment]) async throws {
        logger.debug(
            "save(assignments) entered. count=\(assignments.count, privacy: .public) reason=batch_upsert"
        )

        guard !assignments.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for assignment in assignments {
                    try AssignmentRecord(domain: assignment).save(db)
                }
            }
        } catch {
            logger.error(
                "save(assignments) failed. count=\(assignments.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ cluster: Cluster) async throws {
        logger.debug(
            "save(cluster) entered. clusterID=\(cluster.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try ClusterRecord(domain: cluster).save(db)
            }
        } catch {
            logger.error(
                "save(cluster) failed. clusterID=\(cluster.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ clusters: [Cluster]) async throws {
        logger.debug(
            "save(clusters) entered. count=\(clusters.count, privacy: .public) reason=batch_upsert"
        )

        guard !clusters.isEmpty else { return }

        do {
            try databaseContainer.writer { db in
                for cluster in clusters {
                    try ClusterRecord(domain: cluster).save(db)
                }
            }
        } catch {
            logger.error(
                "save(clusters) failed. count=\(clusters.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchPrimaryAssignment(for messageID: MessageID) async throws -> Assignment {
        logger.debug(
            "fetchPrimaryAssignment entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try AssignmentRecord
                    .filter(AssignmentRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchAll(db)

                guard let first = records.first else {
                    throw RepositoryFailure.notFound(entity: "Assignment", identifier: messageID.rawValue.uuidString)
                }

                if records.count > 1 {
                    throw RepositoryFailure.integrityViolation(
                        reason: "Multiple assignments found for message \(messageID.rawValue.uuidString)"
                    )
                }

                return try first.asDomain()
            }
        } catch {
            logger.error(
                "fetchPrimaryAssignment failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAssignments(in roomID: RoomID) async throws -> [Assignment] {
        logger.debug(
            "fetchAssignments(in:) entered. roomID=\(roomID.rawValue.uuidString, privacy: .public) reason=room_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try AssignmentRecord
                    .filter(AssignmentRecord.Columns.roomID == roomID.rawValue.uuidString)
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchAssignments(in:) failed. roomID=\(roomID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAssignments(for messageIDs: [MessageID]) async throws -> [MessageID: Assignment] {
        logger.debug(
            "fetchAssignments(for:) entered. count=\(messageIDs.count, privacy: .public) reason=batch_message_lookup"
        )

        guard !messageIDs.isEmpty else { return [:] }

        do {
            return try databaseContainer.reader { db in
                let rawIDs = messageIDs.map { $0.rawValue.uuidString }
                let records = try AssignmentRecord
                    .filter(rawIDs.contains(AssignmentRecord.Columns.messageID))
                    .fetchAll(db)

                let grouped = Dictionary(grouping: records, by: \.messageID)
                var result: [MessageID: Assignment] = [:]
                result.reserveCapacity(grouped.count)

                for (messageIDString, bucket) in grouped {
                    if bucket.count > 1 {
                        throw RepositoryFailure.integrityViolation(
                            reason: "Multiple assignments found for message \(messageIDString)"
                        )
                    }

                    let messageID = MessageID(rawValue: try StorageCoding.decodeUUID(messageIDString, field: AssignmentRecord.Columns.messageID.name))
                    result[messageID] = try bucket[0].asDomain()
                }

                return result
            }
        } catch {
            logger.error(
                "fetchAssignments(for:) failed. count=\(messageIDs.count, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchCluster(id: ClusterID) async throws -> Cluster {
        logger.debug(
            "fetchCluster entered. clusterID=\(id.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try ClusterRecord
                    .filter(ClusterRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Cluster", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetchCluster failed. clusterID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteAssignment(id: AssignmentID) async throws {
        logger.debug(
            "deleteAssignment entered. assignmentID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try AssignmentRecord
                    .filter(AssignmentRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteAssignment failed. assignmentID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteCluster(id: ClusterID) async throws {
        logger.debug(
            "deleteCluster entered. clusterID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try ClusterRecord
                    .filter(ClusterRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteCluster failed. clusterID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
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
