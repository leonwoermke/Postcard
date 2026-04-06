// MARK: - MessageRepository.swift
// Domain/Repositories/MessageRepository.swift
//
// Contract for message persistence access.
// Enforces strict separation between preview (list) context
// and full hydration (detail) context.
// No SQL. No GRDB. No storage types.

import Foundation

/// Storage-agnostic access contract for `Message` and `MessagePreview`.
///
/// All callers must explicitly choose between preview and full hydration.
/// Full hydration (including `MessageBody` and `Block` content) is never
/// the default path. Callers that only need list display must use the
/// preview path.
public protocol MessageRepository: AnyObject, Sendable {

    // MARK: — Write

    /// Persists a new message or replaces an existing one with the same ID.
    func save(_ message: Message) async throws

    /// Persists multiple messages in a single operation.
    /// Implementations must treat this as an atomic batch where possible.
    func save(_ messages: [Message]) async throws

    // MARK: — Full Hydration (detail context only)

    /// Returns the fully hydrated message for a given ID.
    /// Use only when `MessageBody` and block content are required.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetch(id: MessageID) async throws -> Message

    /// Returns fully hydrated messages for the given IDs.
    /// Order of results is not guaranteed to match input order.
    /// Missing IDs are silently omitted from the result.
    func fetch(ids: [MessageID]) async throws -> [Message]

    // MARK: — Preview (list context only)

    /// Returns lightweight previews for a room, ordered by recency.
    ///
    /// Implementations must NOT hydrate `MessageBody` or block content.
    /// This path exists exclusively for list and summary display contexts.
    ///
    /// - Parameters:
    ///   - roomID: Scope the results to a specific room.
    ///   - limit: Maximum number of previews to return.
    ///   - before: If provided, return only previews older than this date.
    ///             Used for cursor-based pagination.
    func listPreviews(
        in roomID: RoomID,
        limit: Int,
        before: Date?
    ) async throws -> [MessagePreview]

    /// Returns a single lightweight preview by message ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetchPreview(id: MessageID) async throws -> MessagePreview

    // MARK: — Deletion

    /// Removes a message by ID.
    /// No-ops silently if the ID does not exist.
    func delete(id: MessageID) async throws
}
