// MARK: - SearchRepository.swift
// Domain/Repositories/SearchRepository.swift
//
// Minimal retrieval contract for search results.
//
// This repository does NOT define:
//   - Indexing logic (Infrastructure concern)
//   - Ranking or scoring (Application concern)
//   - Interpretation or semantic enrichment (InterpretationRepository)
//   - FTS table management (Infrastructure concern)
//
// It exposes only the retrieval surface: given a query and a scope,
// return matching message IDs or previews.
// The caller decides what to do with the results.

import Foundation

/// Scope constrains search to a subset of the message store.
public enum SearchScope: Sendable {
    /// Search across all rooms and contacts.
    case global
    /// Search within a single room.
    case room(RoomID)
    /// Search within messages from a single contact.
    case contact(ContactID)
}

/// Storage-agnostic retrieval contract for full-text search.
///
/// Implementations back this with FTS or equivalent infrastructure.
/// The protocol surface is intentionally minimal: retrieve matching
/// previews, nothing more.
public protocol SearchRepository: AnyObject, Sendable {

    /// Returns message previews whose content matches the query string,
    /// constrained to the given scope.
    ///
    /// Results are returned in implementation-defined order (typically
    /// ranked by relevance or recency). The caller must not assume order.
    ///
    /// - Parameters:
    ///   - query: A non-empty search string. Behavior on empty input
    ///            is implementation-defined; callers should guard upstream.
    ///   - scope: Constrains the search space.
    ///   - limit: Maximum number of results to return.
    func search(
        query: String,
        scope: SearchScope,
        limit: Int
    ) async throws -> [MessagePreview]

    /// Returns the message IDs of all messages matching the query,
    /// without hydrating preview content.
    ///
    /// Use when only IDs are needed and preview data would be wasted.
    ///
    /// - Parameters:
    ///   - query: A non-empty search string.
    ///   - scope: Constrains the search space.
    ///   - limit: Maximum number of results to return.
    func searchIDs(
        query: String,
        scope: SearchScope,
        limit: Int
    ) async throws -> [MessageID]
}
