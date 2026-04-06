import Foundation
import GRDB
import OSLog

public enum InitialMigration {
    public static let identifier = "001_initial_schema"

    private static let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Infrastructure.InitialMigration"
    )

    public static func register(on migrator: inout DatabaseMigrator) {
        logger.debug("register(on:) entered. migrationIdentifier=\(identifier, privacy: .public)")

        migrator.registerMigration(identifier) { database in
            logger.info("Initial migration started. migrationIdentifier=\(identifier, privacy: .public)")

            try createCanonicalTables(in: database)
            try createInterpretationTables(in: database)
            try createAdaptiveStateTables(in: database)

            logger.info("Initial migration completed. migrationIdentifier=\(identifier, privacy: .public)")
        }

        logger.info("Registered initial migration. migrationIdentifier=\(identifier, privacy: .public)")
    }

    private static func createCanonicalTables(in database: Database) throws {
        try createAccountsTable(in: database)
        try createMessagesTable(in: database)
        try createMessageBodiesTable(in: database)
        try createParticipantsTable(in: database)
        try createAttachmentsTable(in: database)
        try createContactsTable(in: database)
        try createOrganizationsTable(in: database)
        try createRoomsTable(in: database)
        try createClustersTable(in: database)
        try createAssignmentsTable(in: database)
    }

    private static func createInterpretationTables(in database: Database) throws {
        try createMessageInterpretationsTable(in: database)
        try createBlockInterpretationsTable(in: database)
        try createEntityInterpretationsTable(in: database)
        try createAttachmentInterpretationsTable(in: database)
    }

    private static func createAdaptiveStateTables(in database: Database) throws {
        try createOverridesTable(in: database)
        try createLearningEventsTable(in: database)
        try createAdaptiveProfilesTable(in: database)
        try createPreferencesTable(in: database)
    }

    private static func createAccountsTable(in database: Database) throws {
        try database.create(table: "accounts") { table in
            table.column("id", .text).primaryKey()
            table.column("payload", .blob).notNull()
        }
    }

    private static func createMessagesTable(in database: Database) throws {
        try database.create(table: "messages") { table in
            table.column("id", .text).primaryKey()
            table.column("account_id", .text)
                .notNull()
                .indexed()
                .references("accounts", column: "id", onDelete: .cascade)

            table.column("internet_message_id", .text)
            table.column("subject", .text)
            table.column("sent_at", .datetime)
            table.column("received_at", .datetime)
            table.column("attachment_ids_json", .blob).notNull()
            table.column("in_reply_to_internet_message_id", .text)
            table.column("reference_internet_message_ids_json", .blob).notNull()
            table.column("direction", .text).notNull()
        }
    }

    private static func createMessageBodiesTable(in database: Database) throws {
        try database.create(table: "message_bodies") { table in
            table.column("message_id", .text)
                .primaryKey()
                .references("messages", column: "id", onDelete: .cascade)

            table.column("plain_text", .text)
            table.column("html", .text)
            table.column("normalized_text", .text)
        }
    }

    private static func createParticipantsTable(in database: Database) throws {
        try database.create(table: "participants") { table in
            table.column("id", .text).primaryKey()
            table.column("message_id", .text)
                .notNull()
                .indexed()
                .references("messages", column: "id", onDelete: .cascade)

            table.column("role", .text).notNull()
            table.column("address", .text).notNull()
            table.column("display_name", .text)
        }
    }

    private static func createAttachmentsTable(in database: Database) throws {
        try database.create(table: "attachments") { table in
            table.column("id", .text).primaryKey()
            table.column("message_id", .text)
                .notNull()
                .indexed()
                .references("messages", column: "id", onDelete: .cascade)

            table.column("kind", .text).notNull()
            table.column("kind_other", .text)
            table.column("filename", .text)
            table.column("mime_type", .text)
            table.column("byte_size", .integer)
            table.column("content_id", .text)
            table.column("is_inline", .boolean).notNull()
        }
    }

    private static func createContactsTable(in database: Database) throws {
        try database.create(table: "contacts") { table in
            table.column("id", .text).primaryKey()
            table.column("display_name", .text)
            table.column("preferred_name", .text)
            table.column("email_addresses_json", .blob).notNull()
        }
    }

    private static func createOrganizationsTable(in database: Database) throws {
        try database.create(table: "organizations") { table in
            table.column("id", .text).primaryKey()
            table.column("display_name", .text).notNull()
            table.column("domains_json", .blob).notNull()
            table.column("sender_addresses_json", .blob).notNull()
        }
    }

    private static func createRoomsTable(in database: Database) throws {
        try database.create(table: "rooms") { table in
            table.column("id", .text).primaryKey()
            table.column("anchor_kind", .text).notNull()
            table.column("contact_id", .text)
            table.column("organization_id", .text)
            table.column("title", .text)
            table.column("anchor_title", .text)
        }
    }

    private static func createClustersTable(in database: Database) throws {
        try database.create(table: "clusters") { table in
            table.column("id", .text).primaryKey()
            table.column("room_id", .text)
                .notNull()
                .indexed()
                .references("rooms", column: "id", onDelete: .cascade)

            table.column("kind", .text).notNull()
            table.column("kind_other", .text)
            table.column("title", .text)
        }
    }

    private static func createAssignmentsTable(in database: Database) throws {
        try database.create(table: "assignments") { table in
            table.column("id", .text).primaryKey()

            table.column("message_id", .text)
                .notNull()
                .indexed()
                .unique()
                .references("messages", column: "id", onDelete: .cascade)

            table.column("room_id", .text)
                .notNull()
                .indexed()
                .references("rooms", column: "id", onDelete: .restrict)

            table.column("cluster_id", .text)
                .indexed()
                .references("clusters", column: "id", onDelete: .setNull)

            table.column("confidence", .double).notNull()
            table.column("state", .text).notNull()
            table.column("alternative_candidates_json", .blob).notNull()
        }
    }

    private static func createMessageInterpretationsTable(in database: Database) throws {
        try database.create(table: "message_interpretations") { table in
            table.column("message_id", .text)
                .primaryKey()
                .references("messages", column: "id", onDelete: .cascade)
            table.column("payload", .blob).notNull()
        }
    }

    private static func createBlockInterpretationsTable(in database: Database) throws {
        try database.create(table: "block_interpretations") { table in
            table.column("block_id", .text).primaryKey()
            table.column("payload", .blob).notNull()
        }
    }

    private static func createEntityInterpretationsTable(in database: Database) throws {
        try database.create(table: "entity_interpretations") { table in
            table.column("entity_id", .text).primaryKey()
            table.column("source_descriptor", .blob).notNull()
            table.column("payload", .blob).notNull()
        }
    }

    private static func createAttachmentInterpretationsTable(in database: Database) throws {
        try database.create(table: "attachment_interpretations") { table in
            table.column("attachment_id", .text)
                .primaryKey()
                .references("attachments", column: "id", onDelete: .cascade)
            table.column("payload", .blob).notNull()
        }
    }

    private static func createOverridesTable(in database: Database) throws {
        try database.create(table: "overrides") { table in
            table.column("id", .text).primaryKey()
            table.column("scope_kind", .text).notNull().indexed()
            table.column("message_id", .text).indexed()
            table.column("room_id", .text).indexed()
            table.column("block_id", .text).indexed()
            table.column("entity_id", .text).indexed()
            table.column("payload", .blob).notNull()
        }
    }

    private static func createLearningEventsTable(in database: Database) throws {
        try database.create(table: "learning_events") { table in
            table.column("id", .text).primaryKey()
            table.column("account_id", .text).indexed()
            table.column("message_id", .text).indexed()
            table.column("room_id", .text).indexed()
            table.column("block_id", .text).indexed()
            table.column("entity_id", .text).indexed()
            table.column("payload", .blob).notNull()
        }
    }

    private static func createAdaptiveProfilesTable(in database: Database) throws {
        try database.create(table: "adaptive_profiles") { table in
            table.column("id", .text).primaryKey()
            table.column("account_id", .text).indexed()
            table.column("payload", .blob).notNull()
        }
    }

    private static func createPreferencesTable(in database: Database) throws {
        try database.create(table: "preferences") { table in
            table.column("id", .text).primaryKey()
            table.column("account_id", .text).indexed()
            table.column("payload", .blob).notNull()
        }
    }
}
