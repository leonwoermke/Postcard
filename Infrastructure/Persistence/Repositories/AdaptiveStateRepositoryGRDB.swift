import Foundation
import GRDB
import OSLog

public final class AdaptiveStateRepositoryGRDB: AdaptiveStateRepository, @unchecked Sendable {
    private let databaseContainer: DatabaseContainer
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.AdaptiveStateRepositoryGRDB"
    )

    public init(databaseContainer: DatabaseContainer) {
        self.databaseContainer = databaseContainer
    }

    public func save(_ override: Override) async throws {
        logger.debug(
            "save(override) entered. overrideID=\(override.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try OverrideRecord(domain: override).save(db)
            }
        } catch {
            logger.error(
                "save(override) failed. overrideID=\(override.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchOverride(id: OverrideID) async throws -> Override {
        logger.debug(
            "fetchOverride entered. overrideID=\(id.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try OverrideRecord
                    .filter(OverrideRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Override", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetchOverride failed. overrideID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchOverrides(for messageID: MessageID) async throws -> [Override] {
        logger.debug(
            "fetchOverrides entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try OverrideRecord
                    .filter(OverrideRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchOverrides failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteOverride(id: OverrideID) async throws {
        logger.debug(
            "deleteOverride entered. overrideID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try OverrideRecord
                    .filter(OverrideRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteOverride failed. overrideID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ event: LearningEvent) async throws {
        logger.debug(
            "save(learningEvent) entered. learningEventID=\(event.id.rawValue.uuidString, privacy: .public) reason=insert"
        )

        do {
            try databaseContainer.writer { db in
                try LearningEventRecord(domain: event).insert(db)
            }
        } catch {
            logger.error(
                "save(learningEvent) failed. learningEventID=\(event.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchLearningEvents(for messageID: MessageID) async throws -> [LearningEvent] {
        logger.debug(
            "fetchLearningEvents(message) entered. messageID=\(messageID.rawValue.uuidString, privacy: .public) reason=message_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                let records = try LearningEventRecord
                    .filter(LearningEventRecord.Columns.messageID == messageID.rawValue.uuidString)
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchLearningEvents(message) failed. messageID=\(messageID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchLearningEvents(for contactID: ContactID) async throws -> [LearningEvent] {
        logger.debug(
            "fetchLearningEvents(contact) entered. contactID=\(contactID.rawValue.uuidString, privacy: .public) reason=contact_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                guard let contactRecord = try ContactRecord
                    .filter(ContactRecord.Columns.id == contactID.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Contact", identifier: contactID.rawValue.uuidString)
                }

                let contact = try contactRecord.asDomain()
                let emailAddresses = contact.emailAddresses

                guard !emailAddresses.isEmpty else { return [] }

                let records = try LearningEventRecord
                    .filter(emailAddresses.contains(LearningEventRecord.Columns.senderAddress))
                    .fetchAll(db)

                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchLearningEvents(contact) failed. contactID=\(contactID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ profile: AdaptiveProfile) async throws {
        logger.debug(
            "save(adaptiveProfile) entered. adaptiveProfileID=\(profile.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try AdaptiveProfileRecord(domain: profile).save(db)
            }
        } catch {
            logger.error(
                "save(adaptiveProfile) failed. adaptiveProfileID=\(profile.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAdaptiveProfile(for contactID: ContactID) async throws -> AdaptiveProfile {
        logger.debug(
            "fetchAdaptiveProfile(contact) entered. contactID=\(contactID.rawValue.uuidString, privacy: .public) reason=contact_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                guard let contactRecord = try ContactRecord
                    .filter(ContactRecord.Columns.id == contactID.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Contact", identifier: contactID.rawValue.uuidString)
                }

                let contact = try contactRecord.asDomain()
                let emailAddresses = contact.emailAddresses

                guard !emailAddresses.isEmpty else {
                    throw RepositoryFailure.notFound(entity: "AdaptiveProfile", identifier: contactID.rawValue.uuidString)
                }

                let records = try AdaptiveProfileRecord
                    .filter(emailAddresses.contains(AdaptiveProfileRecord.Columns.senderAddress))
                    .fetchAll(db)

                guard let first = records.first else {
                    throw RepositoryFailure.notFound(entity: "AdaptiveProfile", identifier: contactID.rawValue.uuidString)
                }

                if records.count > 1 {
                    throw RepositoryFailure.integrityViolation(
                        reason: "Multiple adaptive profiles matched contact \(contactID.rawValue.uuidString)"
                    )
                }

                return try first.asDomain()
            }
        } catch {
            logger.error(
                "fetchAdaptiveProfile(contact) failed. contactID=\(contactID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAdaptiveProfile(for roomID: RoomID) async throws -> AdaptiveProfile {
        logger.debug(
            "fetchAdaptiveProfile(room) entered. roomID=\(roomID.rawValue.uuidString, privacy: .public) reason=room_lookup"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try AdaptiveProfileRecord
                    .filter(AdaptiveProfileRecord.Columns.roomID == roomID.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "AdaptiveProfile", identifier: roomID.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetchAdaptiveProfile(room) failed. roomID=\(roomID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteAdaptiveProfile(for contactID: ContactID) async throws {
        logger.debug(
            "deleteAdaptiveProfile(contact) entered. contactID=\(contactID.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                guard let contactRecord = try ContactRecord
                    .filter(ContactRecord.Columns.id == contactID.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    return
                }

                let contact = try contactRecord.asDomain()
                let emailAddresses = contact.emailAddresses

                guard !emailAddresses.isEmpty else { return }

                _ = try AdaptiveProfileRecord
                    .filter(emailAddresses.contains(AdaptiveProfileRecord.Columns.senderAddress))
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteAdaptiveProfile(contact) failed. contactID=\(contactID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deleteAdaptiveProfile(for roomID: RoomID) async throws {
        logger.debug(
            "deleteAdaptiveProfile(room) entered. roomID=\(roomID.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try AdaptiveProfileRecord
                    .filter(AdaptiveProfileRecord.Columns.roomID == roomID.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deleteAdaptiveProfile(room) failed. roomID=\(roomID.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func save(_ preference: Preference) async throws {
        logger.debug(
            "save(preference) entered. preferenceID=\(preference.id.rawValue.uuidString, privacy: .public) reason=upsert"
        )

        do {
            try databaseContainer.writer { db in
                try PreferenceRecord(domain: preference).save(db)
            }
        } catch {
            logger.error(
                "save(preference) failed. preferenceID=\(preference.id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchPreference(id: PreferenceID) async throws -> Preference {
        logger.debug(
            "fetchPreference entered. preferenceID=\(id.rawValue.uuidString, privacy: .public) reason=single_fetch"
        )

        do {
            return try databaseContainer.reader { db in
                guard let record = try PreferenceRecord
                    .filter(PreferenceRecord.Columns.id == id.rawValue.uuidString)
                    .fetchOne(db)
                else {
                    throw RepositoryFailure.notFound(entity: "Preference", identifier: id.rawValue.uuidString)
                }

                return try record.asDomain()
            }
        } catch {
            logger.error(
                "fetchPreference failed. preferenceID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func fetchAllPreferences() async throws -> [Preference] {
        logger.debug("fetchAllPreferences entered. reason=full_fetch")

        do {
            return try databaseContainer.reader { db in
                let records = try PreferenceRecord.fetchAll(db)
                return try records.map { try $0.asDomain() }
            }
        } catch {
            logger.error(
                "fetchAllPreferences failed. error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    public func deletePreference(id: PreferenceID) async throws {
        logger.debug(
            "deletePreference entered. preferenceID=\(id.rawValue.uuidString, privacy: .public) reason=delete"
        )

        do {
            try databaseContainer.writer { db in
                _ = try PreferenceRecord
                    .filter(PreferenceRecord.Columns.id == id.rawValue.uuidString)
                    .deleteAll(db)
            }
        } catch {
            logger.error(
                "deletePreference failed. preferenceID=\(id.rawValue.uuidString, privacy: .public) error=\(String(describing: error), privacy: .public)"
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
