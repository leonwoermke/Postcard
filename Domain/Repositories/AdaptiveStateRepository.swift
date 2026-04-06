// MARK: - AdaptiveStateRepository.swift
// Domain/Repositories/AdaptiveStateRepository.swift
//
// Contract for adaptive personalization state persistence.
//
// Four concepts are kept strictly separate:
//   - Override       (explicit user corrections to system decisions)
//   - LearningEvent  (implicit signals used to update the adaptive model)
//   - AdaptiveProfile (the current personalization model per entity scope)
//   - Preference     (explicit user settings and preferences)
//
// No merged, vague, or generic APIs are permitted. Each concept
// has its own write and read surface. Mixing them — even for
// convenience — destroys the personalization model boundary.
//
// AdaptiveProfile is stored as a JSON blob at the Infrastructure layer.
// This protocol does not expose that detail.

import Foundation

/// Storage-agnostic access contract for adaptive personalization state.
///
/// All four adaptive concepts are independently addressable.
/// Scoped retrieval is provided where the concept is naturally scoped
/// to an entity (e.g. contact, room, message).
public protocol AdaptiveStateRepository: AnyObject, Sendable {

    // MARK: — Override

    /// Persists a user override or replaces an existing one with the same ID.
    func save(_ override: Override) async throws

    /// Returns the override for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetchOverride(id: OverrideID) async throws -> Override

    /// Returns all overrides associated with a given message.
    func fetchOverrides(for messageID: MessageID) async throws -> [Override]

    /// Removes an override by ID.
    /// No-ops silently if the ID does not exist.
    func deleteOverride(id: OverrideID) async throws

    // MARK: — LearningEvent

    /// Persists a new learning event.
    /// Learning events are append-only; no upsert is needed.
    func save(_ event: LearningEvent) async throws

    /// Returns all learning events associated with a given message.
    func fetchLearningEvents(for messageID: MessageID) async throws -> [LearningEvent]

    /// Returns all learning events associated with a given contact.
    func fetchLearningEvents(for contactID: ContactID) async throws -> [LearningEvent]

    // MARK: — AdaptiveProfile

    /// Persists an adaptive profile or replaces the existing one for the same scope.
    func save(_ profile: AdaptiveProfile) async throws

    /// Returns the adaptive profile for a given contact.
    /// - Throws: a domain `NotFound` error if none exists.
    func fetchAdaptiveProfile(for contactID: ContactID) async throws -> AdaptiveProfile

    /// Returns the adaptive profile for a given room.
    /// - Throws: a domain `NotFound` error if none exists.
    func fetchAdaptiveProfile(for roomID: RoomID) async throws -> AdaptiveProfile

    /// Removes the adaptive profile for a given contact.
    func deleteAdaptiveProfile(for contactID: ContactID) async throws

    /// Removes the adaptive profile for a given room.
    func deleteAdaptiveProfile(for roomID: RoomID) async throws

    // MARK: — Preference

    /// Persists a user preference or replaces an existing one with the same ID.
    func save(_ preference: Preference) async throws

    /// Returns the preference for a given ID.
    /// - Throws: a domain `NotFound` error if no match exists.
    func fetchPreference(id: PreferenceID) async throws -> Preference

    /// Returns all preferences stored for the current user context.
    /// Intended for settings resolution and preference inspection only.
    func fetchAllPreferences() async throws -> [Preference]

    /// Removes a preference by ID.
    /// No-ops silently if the ID does not exist.
    func deletePreference(id: PreferenceID) async throws
}
