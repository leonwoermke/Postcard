// MARK: - AttachmentRepository.swift
// Domain/Repositories/AttachmentRepository.swift
//
// Contract for attachment persistence access.
// Required by Phase 4 intake pipeline before CanonicalMessageBuilder
// can resolve attachment references into canonical messages.

import Foundation

/// Storage-agnostic access contract for `Attachment`.
///
/// Attachments are always returned fully hydrated. There is no preview
/// variant because attachment records are structurally small and do not
/// contain embedded binary data (binary storage is out of scope here).
public protocol AttachmentRepository: AnyObject, Sendable {

    // MARK: — Write

    /// Persists a new attachment or replaces an existing one with the same ID.
    func save(_ attachment: Attachment) async throws

    /// Persists multiple attachments in a single operation.
    func save(_ attachments: [Attachment]) async throws

    // MARK: — Read by Identity

    /// Returns the attachment for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetch(id: AttachmentID) async throws -> Attachment

    /// Returns attachments for the given IDs.
    /// Order of results is not guaranteed to match input order.
    /// Missing IDs are silently omitted from the result.
    func fetch(ids: [AttachmentID]) async throws -> [Attachment]

    // MARK: — Read by Message

    /// Returns all attachments associated with a specific message.
    /// Returns an empty array if the message has no attachments.
    func fetch(byMessageID messageID: MessageID) async throws -> [Attachment]

    // MARK: — Deletion

    /// Removes an attachment by ID.
    /// No-ops silently if the ID does not exist.
    func delete(id: AttachmentID) async throws
}
