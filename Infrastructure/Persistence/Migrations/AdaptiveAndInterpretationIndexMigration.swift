import Foundation
import GRDB

enum AdaptiveAndInterpretationIndexMigration {
    static func register(on migrator: inout DatabaseMigrator) {
        migrator.registerMigration("phase3_adaptive_and_interpretation_indexes") { db in
            try db.alter(table: AdaptiveProfileRecord.databaseTableName) { table in
                table.add(column: "room_id", .text)
                table.add(column: "sender_address", .text)
            }

            try db.alter(table: LearningEventRecord.databaseTableName) { table in
                table.add(column: "sender_address", .text)
            }

            try db.alter(table: EntityInterpretationRecord.databaseTableName) { table in
                table.add(column: "message_id", .text)
            }

            try db.create(index: "idx_adaptive_profiles_room_id", on: AdaptiveProfileRecord.databaseTableName, columns: ["room_id"], ifNotExists: true)
            try db.create(index: "idx_adaptive_profiles_sender_address", on: AdaptiveProfileRecord.databaseTableName, columns: ["sender_address"], ifNotExists: true)
            try db.create(index: "idx_learning_events_sender_address", on: LearningEventRecord.databaseTableName, columns: ["sender_address"], ifNotExists: true)
            try db.create(index: "idx_entity_interpretations_message_id", on: EntityInterpretationRecord.databaseTableName, columns: ["message_id"], ifNotExists: true)

            try backfillAdaptiveProfiles(db)
            try backfillLearningEvents(db)
            try backfillEntityInterpretations(db)
        }
    }

    private static func backfillAdaptiveProfiles(_ db: Database) throws {
        struct Row: FetchableRecord, Decodable {
            let id: String
            let payload: Data
        }

        let rows = try Row.fetchAll(
            db,
            sql: "SELECT id, payload FROM \(AdaptiveProfileRecord.databaseTableName)"
        )

        for row in rows {
            let payload = try JSONDecoder().decode(AdaptiveProfileMigrationPayload.self, from: row.payload)

            let roomID: String?
            let senderAddress: String?

            switch payload.scope.tag {
            case "room":
                roomID = payload.scope.roomID
                senderAddress = nil
            case "senderAddress":
                roomID = nil
                senderAddress = payload.scope.senderAddress
            default:
                roomID = nil
                senderAddress = nil
            }

            try db.execute(
                sql: """
                UPDATE \(AdaptiveProfileRecord.databaseTableName)
                SET room_id = ?, sender_address = ?
                WHERE id = ?
                """,
                arguments: [roomID, senderAddress, row.id]
            )
        }
    }

    private static func backfillLearningEvents(_ db: Database) throws {
        struct Row: FetchableRecord, Decodable {
            let id: String
            let payload: Data
        }

        let rows = try Row.fetchAll(
            db,
            sql: "SELECT id, payload FROM \(LearningEventRecord.databaseTableName)"
        )

        for row in rows {
            let payload = try JSONDecoder().decode(LearningEventMigrationPayload.self, from: row.payload)
            let senderAddress = payload.scope.tag == "senderAddress" ? payload.scope.senderAddress : nil

            try db.execute(
                sql: """
                UPDATE \(LearningEventRecord.databaseTableName)
                SET sender_address = ?
                WHERE id = ?
                """,
                arguments: [senderAddress, row.id]
            )
        }
    }

    private static func backfillEntityInterpretations(_ db: Database) throws {
        struct Row: FetchableRecord, Decodable {
            let entityID: String
            let sourceDescriptor: Data
        }

        let rows = try Row.fetchAll(
            db,
            sql: "SELECT entity_id, source_descriptor FROM \(EntityInterpretationRecord.databaseTableName)"
        )

        for row in rows {
            let sourceDescriptor = try JSONDecoder().decode(EntityID.SourceDescriptor.self, from: row.sourceDescriptor)
            let messageID = sourceDescriptor.messageID.rawValue.uuidString

            try db.execute(
                sql: """
                UPDATE \(EntityInterpretationRecord.databaseTableName)
                SET message_id = ?
                WHERE entity_id = ?
                """,
                arguments: [messageID, row.entityID]
            )
        }
    }
}

private struct AdaptiveProfileMigrationPayload: Decodable {
    let scope: AdaptiveProfileMigrationScope
}

private struct AdaptiveProfileMigrationScope: Decodable {
    let tag: String
    let senderAddress: String?
    let roomID: String?
}

private struct LearningEventMigrationPayload: Decodable {
    let scope: LearningEventMigrationScope
}

private struct LearningEventMigrationScope: Decodable {
    let tag: String
    let senderAddress: String?
}
