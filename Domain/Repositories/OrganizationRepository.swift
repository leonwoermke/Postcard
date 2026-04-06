// MARK: - OrganizationRepository.swift
// Domain/Repositories/OrganizationRepository.swift
//
// Contract for organization identity persistence access.
// Organizations are the top-level identity containers for
// contacts and rooms within the system.

import Foundation

/// Storage-agnostic access contract for `Organization`.
public protocol OrganizationRepository: AnyObject, Sendable {

    // MARK: — Write

    /// Persists a new organization or replaces an existing one with the same ID.
    func save(_ organization: Organization) async throws

    /// Persists multiple organizations in a single operation.
    func save(_ organizations: [Organization]) async throws

    // MARK: — Read

    /// Returns the organization for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetch(id: OrganizationID) async throws -> Organization

    /// Returns organizations for the given IDs.
    /// Order of results is not guaranteed to match input order.
    /// Missing IDs are silently omitted from the result.
    func fetch(ids: [OrganizationID]) async throws -> [Organization]

    /// Returns all stored organizations.
    /// Intended for administrative or diagnostic use only.
    func fetchAll() async throws -> [Organization]

    // MARK: — Deletion

    /// Removes an organization by ID.
    /// No-ops silently if the ID does not exist.
    func delete(id: OrganizationID) async throws
}
