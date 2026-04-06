// MARK: - RoomRepository.swift
// Domain/Repositories/RoomRepository.swift
//
// Contract for room persistence access.
//
// Two distinct access paths are mandatory:
//   1. Full `Room` — for room detail, participant resolution, and display.
//   2. Lightweight `RoomLookup` — the only path Assignment logic is permitted
//      to use (Decision 49). Assignment must never receive a full Room.
//
// RoomReference is derived and has no storage model.
// It must not appear in this repository's surface.

import Foundation

/// Storage-agnostic access contract for `Room` and `RoomLookup`.
///
/// Callers that only need to resolve a room reference for assignment
/// or routing purposes must use the `fetchLookup` path.
/// Full hydration is reserved for display and participant contexts.
public protocol RoomRepository: AnyObject, Sendable {

    // MARK: — Write

    /// Persists a new room or replaces an existing one with the same ID.
    func save(_ room: Room) async throws

    /// Persists multiple rooms in a single operation.
    func save(_ rooms: [Room]) async throws

    // MARK: — Full Hydration (display / participant context)

    /// Returns the fully hydrated room for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetch(id: RoomID) async throws -> Room

    /// Returns fully hydrated rooms for the given IDs.
    /// Order of results is not guaranteed to match input order.
    /// Missing IDs are silently omitted from the result.
    func fetch(ids: [RoomID]) async throws -> [Room]

    // MARK: — Lightweight Lookup (assignment / routing context only)

    /// Returns the lightweight lookup projection for a given room ID.
    ///
    /// This is the **only** room access path that `AssignmentRepository`
    /// consumers are permitted to use (Decision 49).
    /// Implementations must not hydrate participant or metadata fields.
    ///
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetchLookup(by id: RoomID) async throws -> RoomLookup

    /// Returns lightweight lookup projections for the given room IDs.
    /// Missing IDs are silently omitted from the result.
    func fetchLookups(by ids: [RoomID]) async throws -> [RoomLookup]

    // MARK: — Deletion

    /// Removes a room by ID.
    /// No-ops silently if the ID does not exist.
    func delete(id: RoomID) async throws
}
