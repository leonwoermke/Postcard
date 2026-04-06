// MARK: - DatabaseContainer.swift
// Infrastructure/Persistence/DatabaseContainer.swift
//
// Owns the GRDB database queue and drives migration on setup.
// This is the single point of SQLite ownership in the application.
//
// AppContainer constructs and holds exactly one instance.
// No global state. No shared singletons.
//
// GRDB must not escape this layer. Repository implementations
// receive a DatabaseContainer and call writer/reader on it.
// Nothing outside Infrastructure touches DatabaseQueue directly.

import Foundation
import GRDB
import OSLog

/// Owns the SQLite database and provides scoped read/write access
/// to Infrastructure repository implementations.
///
/// Construction is two-phase:
///   1. `init(configuration:)` — resolves path and configuration.
///   2. `setUp()` — opens the database and runs all migrations.
///
/// Callers must call `setUp()` before using `writer` or `reader`.
/// AppContainer is responsible for sequencing this correctly.
public final class DatabaseContainer: Sendable {

    // MARK: — Configuration

    public enum StorageLocation: Sendable {
        /// Persistent file-backed SQLite database.
        case file(URL)
        /// In-memory SQLite database. Isolated per instance.
        /// Use in test targets only.
        case memory
    }

    // MARK: — Private State

    private let location: StorageLocation
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.postcard",
        category: "Infrastructure.DatabaseContainer"
    )

    /// The live database queue. Set once during `setUp()`.
    /// Nonisolated storage via a lock to satisfy Sendable without an actor,
    /// keeping the synchronous `writer`/`reader` API clean.
    private let _queue: LockedBox<DatabaseQueue> = .init()

    // MARK: — Lifecycle

    /// Creates a container for the given storage location.
    /// Does not open or migrate the database.
    ///
    /// - Parameter location: Where the database should be stored.
    public init(location: StorageLocation) {
        self.location = location
        logger.debug("DatabaseContainer created — location: \(String(describing: location), privacy: .public)")
    }

    /// Opens the database at the configured location and runs all
    /// registered migrations in order.
    ///
    /// Must be called exactly once before any repository uses
    /// `writer` or `reader`. Calling it more than once is a
    /// programmer error and will throw.
    ///
    /// - Throws: Any GRDB or migration error encountered during setup.
    public func setUp() async throws {
        logger.info("DatabaseContainer.setUp — begin")

        let queue = try makeQueue()
        logger.debug("DatabaseContainer.setUp — queue opened")

        var migrator = DatabaseMigrator()
        InitialMigration.register(on: &migrator)
        BlockInterpretationMessageIDMigration.register(on: &migrator)
        PreferencesAccountIDMigration.register(on: &migrator)
        AdaptiveProfilesAccountIDMigration.register(on: &migrator)
        AdaptiveProfilesScopeColumnsMigration.register(on: &migrator)
        AdaptiveAndInterpretationIndexMigration.register(on: &migrator)
        logger.debug("DatabaseContainer.setUp — migrations registered")

        try await migrator.migrate(queue)
        logger.info("DatabaseContainer.setUp — migrations complete")

        _queue.set(queue)
        logger.info("DatabaseContainer.setUp — ready")
    }

    // MARK: — Access Surface

    /// The database queue. Available after `setUp()` completes.
    ///
    /// Repository implementations use this for all reads and writes.
    /// This property must not be exposed beyond Infrastructure.
    internal var dbQueue: DatabaseQueue {
        guard let queue = _queue.get() else {
            // Programming error: setUp() was not awaited before use.
            preconditionFailure("DatabaseContainer accessed before setUp() completed.")
        }
        return queue
    }

    /// Executes a write transaction.
    ///
    /// Convenience wrapper used by repository implementations.
    internal func writer<T: Sendable>(
        _ updates: @Sendable (Database) throws -> T
    ) throws -> T {
        try dbQueue.write(updates)
    }

    /// Executes a read transaction.
    ///
    /// Convenience wrapper used by repository implementations.
    internal func reader<T: Sendable>(
        _ fetch: @Sendable (Database) throws -> T
    ) throws -> T {
        try dbQueue.read(fetch)
    }

    // MARK: — Private Helpers

    private func makeQueue() throws -> DatabaseQueue {
        switch location {
        case .file(let url):
            logger.debug("DatabaseContainer — opening file database at \(url.path, privacy: .sensitive)")
            var config = Configuration()
            config.label = "com.postcard.infrastructure.db"
            // WAL mode for concurrent read performance.
            config.prepareDatabase { db in
                try db.execute(sql: "PRAGMA journal_mode = WAL")
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }
            return try DatabaseQueue(path: url.path, configuration: config)

        case .memory:
            logger.debug("DatabaseContainer — opening in-memory database")
            var config = Configuration()
            config.label = "com.postcard.infrastructure.db.memory"
            config.prepareDatabase { db in
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }
            return try DatabaseQueue(configuration: config)
        }
    }
}

private struct BlockInterpretationMessageIDMigration {
    static func register(on migrator: inout DatabaseMigrator) {
        migrator.registerMigration("002_add_message_id_to_block_interpretations") { db in
            try db.alter(table: "block_interpretations") { t in
                t.add(column: "message_id", .text).notNull()
                    .references("messages", onDelete: .cascade)
                t.add(column: "source_boundary", .text).notNull()
            }
            try db.create(index: "block_interpretations_on_message_id", on: "block_interpretations", columns: ["message_id"]) 
        }
    }
}

private struct PreferencesAccountIDMigration {
    static func register(on migrator: inout DatabaseMigrator) {
        migrator.registerMigration("003_add_accountID_to_preferences") { db in
            try db.alter(table: "preferences") { t in
                t.add(column: "accountID", .text).notNull()
                    .references("accounts", onDelete: .cascade)
            }
            try db.create(index: "preferences_on_accountID", on: "preferences", columns: ["accountID"]) 
        }
    }
}

private struct AdaptiveProfilesAccountIDMigration {
    static func register(on migrator: inout DatabaseMigrator) {
        migrator.registerMigration("004_add_accountID_to_adaptive_profiles") { db in
            try db.alter(table: "adaptive_profiles") { t in
                t.add(column: "accountID", .text).notNull()
                    .references("accounts", onDelete: .cascade)
            }
            try db.create(index: "adaptive_profiles_on_accountID", on: "adaptive_profiles", columns: ["accountID"]) 
        }
    }
}

private struct AdaptiveProfilesScopeColumnsMigration {
    static func register(on migrator: inout DatabaseMigrator) {
        migrator.registerMigration("005_add_scope_columns_to_adaptive_profiles") { db in
            try db.alter(table: "adaptive_profiles") { t in
                t.add(column: "roomID", .text)
                    .references("rooms", onDelete: .cascade)
                t.add(column: "senderAddress", .text)
            }
            try db.create(index: "adaptive_profiles_on_roomID", on: "adaptive_profiles", columns: ["roomID"]) 
            try db.create(index: "adaptive_profiles_on_senderAddress", on: "adaptive_profiles", columns: ["senderAddress"]) 
        }
    }
}

// MARK: — LockedBox

/// A thread-safe box for a single optional value.
/// Used to store the database queue after async setup without
/// requiring an actor on the Sendable container.
private final class LockedBox<T: Sendable>: @unchecked Sendable {
    private var value: T?
    private let lock = NSLock()

    func set(_ newValue: T) {
        lock.withLock { value = newValue }
    }

    func get() -> T? {
        lock.withLock { value }
    }
}
