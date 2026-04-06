// MARK: - AssignmentRepository.swift
// Domain/Repositories/AssignmentRepository.swift
//
// Contract for assignment and cluster persistence access.
//
// Invariant enforced here: exactly one primary Assignment per Message.
// This repository does not enforce it mechanically — that is
// Application responsibility — but the fetch surface is designed to
// make the invariant observable and testable.
//
// Assignment logic must use RoomLookup (via RoomRepository), never
// full Room. This repository does not expose Room directly.

import Foundation

/// Storage-agnostic access contract for `Assignment` and `Cluster`.
///
/// Assignment and Cluster are stored and retrieved independently.
/// No merged or polymorphic access methods are permitted.
public protocol AssignmentRepository: AnyObject, Sendable {

    // MARK: — Write: Assignment

    /// Persists a new assignment or replaces an existing one with the same ID.
    func save(_ assignment: Assignment) async throws

    /// Persists multiple assignments in a single operation.
    func save(_ assignments: [Assignment]) async throws

    // MARK: — Write: Cluster

    /// Persists a new cluster or replaces an existing one with the same ID.
    func save(_ cluster: Cluster) async throws

    /// Persists multiple clusters in a single operation.
    func save(_ clusters: [Cluster]) async throws

    // MARK: — Read: Assignment

    /// Returns the primary assignment for a given message.
    ///
    /// Each message must have exactly one primary assignment.
    /// - Throws: a domain `NotFound` error if none exists.
    func fetchPrimaryAssignment(for messageID: MessageID) async throws -> Assignment

    /// Returns all assignments scoped to a given room.
    /// Returns an empty array if the room has no assignments.
    func fetchAssignments(in roomID: RoomID) async throws -> [Assignment]

    /// Returns assignments for a batch of message IDs.
    /// Results are keyed by `MessageID` for efficient lookup.
    /// Missing message IDs are omitted from the result dictionary.
    func fetchAssignments(
        for messageIDs: [MessageID]
    ) async throws -> [MessageID: Assignment]

    // MARK: — Read: Cluster

    /// Returns the cluster for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetchCluster(id: ClusterID) async throws -> Cluster

    // MARK: — Deletion

    /// Removes an assignment by ID.
    /// No-ops silently if the ID does not exist.
    func deleteAssignment(id: AssignmentID) async throws

    /// Removes a cluster by ID.
    /// No-ops silently if the ID does not exist.
    func deleteCluster(id: ClusterID) async throws
}
