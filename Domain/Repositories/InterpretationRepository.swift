// MARK: - InterpretationRepository.swift
// Domain/Repositories/InterpretationRepository.swift
//
// Contract for interpretation persistence access.
//
// Interpretation storage is strictly separated from canonical message
// storage. No method in this repository touches Message, Attachment,
// or any canonical type directly.
//
// Four interpretation layers are kept independent:
//   - MessageInterpretation   (top-level classification / routing signal)
//   - BlockInterpretation     (per-block semantic annotation)
//   - EntityInterpretation    (extracted named entities)
//   - AttachmentInterpretation (attachment-level semantic annotation)
//
// These must not be merged into generic or polymorphic access paths.

import Foundation

/// Storage-agnostic access contract for interpretation types.
///
/// All four interpretation layers are treated as independent stores
/// within this single protocol. Implementations must not co-mingle
/// rows or tables across interpretation layers.
public protocol InterpretationRepository: AnyObject, Sendable {

    // MARK: — MessageInterpretation

    /// Persists a message interpretation or replaces an existing one.
    func save(_ interpretation: MessageInterpretation) async throws

    /// Returns the message interpretation for a given message ID.
    /// - Throws: a domain `NotFound` error if none exists.
    func fetchMessageInterpretation(
        for messageID: MessageID
    ) async throws -> MessageInterpretation

    // MARK: — BlockInterpretation

    /// Persists a block interpretation or replaces an existing one.
    func save(_ interpretation: BlockInterpretation) async throws

    /// Returns all block interpretations associated with a message.
    /// Returns an empty array if no interpretations have been stored.
    func fetchBlockInterpretations(
        for messageID: MessageID
    ) async throws -> [BlockInterpretation]

    // MARK: — EntityInterpretation

    /// Persists an entity interpretation or replaces an existing one.
    func save(_ interpretation: EntityInterpretation) async throws

    /// Returns all entity interpretations associated with a message.
    /// Returns an empty array if no interpretations have been stored.
    func fetchEntityInterpretations(
        for messageID: MessageID
    ) async throws -> [EntityInterpretation]

    // MARK: — AttachmentInterpretation

    /// Persists an attachment interpretation or replaces an existing one.
    func save(_ interpretation: AttachmentInterpretation) async throws

    /// Returns the attachment interpretation for a given attachment ID.
    /// - Throws: a domain `NotFound` error if none exists.
    func fetchAttachmentInterpretation(
        for attachmentID: AttachmentID
    ) async throws -> AttachmentInterpretation

    /// Returns all attachment interpretations associated with a message.
    /// Returns an empty array if no interpretations have been stored.
    func fetchAttachmentInterpretations(
        for messageID: MessageID
    ) async throws -> [AttachmentInterpretation]

    // MARK: — Deletion

    /// Removes the message interpretation for a given message ID.
    /// No-ops silently if none exists.
    func deleteMessageInterpretation(for messageID: MessageID) async throws

    /// Removes all block interpretations for a given message ID.
    func deleteBlockInterpretations(for messageID: MessageID) async throws

    /// Removes all entity interpretations for a given message ID.
    func deleteEntityInterpretations(for messageID: MessageID) async throws

    /// Removes the attachment interpretation for a given attachment ID.
    func deleteAttachmentInterpretation(for attachmentID: AttachmentID) async throws
}
