// MARK: - ContactRepository.swift
// Domain/Repositories/ContactRepository.swift
//
// Contract for contact identity persistence access.
// Contacts represent individual participants resolved from
// provider-side participant data.

import Foundation

/// Storage-agnostic access contract for `Contact`.
public protocol ContactRepository: AnyObject, Sendable {

    // MARK: — Write

    /// Persists a new contact or replaces an existing one with the same ID.
    func save(_ contact: Contact) async throws

    /// Persists multiple contacts in a single operation.
    func save(_ contacts: [Contact]) async throws

    // MARK: — Read

    /// Returns the contact for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetch(id: ContactID) async throws -> Contact

    /// Returns contacts for the given IDs.
    /// Order of results is not guaranteed to match input order.
    /// Missing IDs are silently omitted from the result.
    func fetch(ids: [ContactID]) async throws -> [Contact]

    /// Returns all stored contacts.
    /// Intended for administrative or diagnostic use only.
    /// Callers in normal application flow must prefer scoped access.
    func fetchAll() async throws -> [Contact]

    // MARK: — Deletion

    /// Removes a contact by ID.
    /// No-ops silently if the ID does not exist.
    func delete(id: ContactID) async throws
}
