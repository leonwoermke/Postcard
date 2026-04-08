import Foundation
import OSLog

/// A deterministic, in-memory fixture connector for pipeline validation.
///
/// Stores a fixed set of `ConnectorInboundMessage` values provided at
/// construction time. Supports cursor-based incremental fetch, simulating
/// real-world batching without any network access, persistence, or
/// provider-specific behavior.
///
/// Send capability is implemented as a no-op stub. The connector accepts
/// outbound requests, logs them, and returns a deterministic success result.
/// No state is mutated.
///
/// Ordering is stable and fixed: messages are delivered in the order they
/// were injected. Cursors are index-based integer offsets encoded as strings.
/// Given identical input, the connector always produces identical batches,
/// cursors, and outputs.
public final class FixtureEmailConnector: EmailConnector, @unchecked Sendable {

    // MARK: — Constants

    private static let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Infrastructure.FixtureEmailConnector"
    )

    public static let defaultConnectorID = ConnectorID(rawValue: "fixture")

    // MARK: — Storage

    private let messages: [ConnectorInboundMessage]
    private let pageSize: Int
    private let _id: ConnectorID
    private let _displayName: String

    // MARK: — EmailConnector Identity

    public var id: ConnectorID { _id }
    public var displayName: String { _displayName }

    // MARK: — Lifecycle

    /// Creates a fixture connector with a fixed message set.
    ///
    /// - Parameters:
    ///   - messages: The complete ordered set of messages to serve.
    ///               Ordering is preserved exactly as provided.
    ///   - pageSize: Maximum messages returned per batch. Must be >= 1.
    ///               Defaults to 20.
    ///   - id: The connector's stable identifier. Defaults to `"fixture"`.
    ///   - displayName: Human-readable name used for display and logging.
    public init(
        messages: [ConnectorInboundMessage],
        pageSize: Int = 20,
        id: ConnectorID = FixtureEmailConnector.defaultConnectorID,
        displayName: String = "Fixture Connector"
    ) {
        self.messages = messages
        self.pageSize = max(1, pageSize)
        self._id = id
        self._displayName = displayName

        Self.logger.info(
            "init completed. connectorID=\(id.rawValue, privacy: .public) messageCount=\(messages.count, privacy: .public) pageSize=\(max(1, pageSize), privacy: .public) displayName=\(displayName, privacy: .public)"
        )
    }

    // MARK: — EmailConnector: Availability

    public func availability() async -> ConnectorAvailability {
        Self.logger.debug(
            "availability entered. connectorID=\(self._id.rawValue, privacy: .public) reason=fixture_always_available"
        )
        return .available
    }

    // MARK: — EmailConnector: Sync State

    public func currentSyncState() async throws -> ConnectorSyncState {
        Self.logger.debug(
            "currentSyncState entered. connectorID=\(self._id.rawValue, privacy: .public) messageCount=\(self.messages.count, privacy: .public)"
        )

        let hasMore = messages.count > pageSize
        let cursor: ConnectorSyncCursor? = messages.isEmpty
            ? nil
            : ConnectorSyncCursor(rawValue: "0")

        let state = ConnectorSyncState(
            mode: messages.isEmpty ? .idle : .incremental,
            cursor: cursor,
            lastCompletedSyncAt: nil,
            hasMoreAvailable: hasMore
        )

        Self.logger.debug(
            "currentSyncState resolved. connectorID=\(self._id.rawValue, privacy: .public) mode=\(state.mode.rawValue, privacy: .public) hasMoreAvailable=\(hasMore, privacy: .public) reason=fixture_state_derived_from_message_count"
        )

        return state
    }

    // MARK: — EmailConnector: Inbound Fetch

    /// Returns a batch of messages starting at the offset encoded in `cursor`.
    ///
    /// Cursor format: a string-encoded integer offset into the message array.
    /// A nil cursor starts from index 0. An out-of-range cursor returns an
    /// empty batch with no next cursor.
    ///
    /// - Parameters:
    ///   - cursor: Opaque pagination cursor from a previous batch response,
    ///             or nil to begin from the start.
    ///   - limit: Caller-requested page size. The connector uses the lesser
    ///            of this value and its own configured `pageSize`.
    public func fetchInboundBatch(
        after cursor: ConnectorSyncCursor?,
        limit: Int
    ) async throws -> ConnectorInboundBatch {
        let offset = Self.decodeOffset(from: cursor)
        let effectivePageSize = min(max(1, limit), pageSize)

        Self.logger.info(
            "fetchInboundBatch entered. connectorID=\(self._id.rawValue, privacy: .public) cursor=\(cursor?.rawValue ?? "nil", privacy: .public) limit=\(limit, privacy: .public) effectivePageSize=\(effectivePageSize, privacy: .public) totalMessages=\(self.messages.count, privacy: .public)"
        )

        guard offset >= 0, offset < messages.count else {
            Self.logger.info(
                "fetchInboundBatch resolved empty. connectorID=\(self._id.rawValue, privacy: .public) offset=\(offset, privacy: .public) reason=offset_out_of_range"
            )

            return ConnectorInboundBatch(
                messages: [],
                nextCursor: nil,
                hasMoreAvailable: false,
                syncState: ConnectorSyncState(
                    mode: .idle,
                    cursor: nil,
                    lastCompletedSyncAt: nil,
                    hasMoreAvailable: false
                )
            )
        }

        let sliceStart = offset
        let sliceEnd = min(offset + effectivePageSize, messages.count)
        let slice = Array(messages[sliceStart..<sliceEnd])

        let nextOffset = sliceEnd
        let hasMore = nextOffset < messages.count
        let nextCursor: ConnectorSyncCursor? = hasMore
            ? ConnectorSyncCursor(rawValue: String(nextOffset))
            : nil

        let syncState = ConnectorSyncState(
            mode: hasMore ? .incremental : .idle,
            cursor: nextCursor,
            lastCompletedSyncAt: nil,
            hasMoreAvailable: hasMore
        )

        Self.logger.info(
            "fetchInboundBatch resolved. connectorID=\(self._id.rawValue, privacy: .public) sliceStart=\(sliceStart, privacy: .public) sliceEnd=\(sliceEnd, privacy: .public) batchCount=\(slice.count, privacy: .public) hasMore=\(hasMore, privacy: .public) nextCursor=\(nextCursor?.rawValue ?? "nil", privacy: .public) reason=index_slice"
        )

        return ConnectorInboundBatch(
            messages: slice,
            nextCursor: nextCursor,
            hasMoreAvailable: hasMore,
            syncState: syncState
        )
    }

    // MARK: — EmailConnector: Outbound Send

    /// Accepts an outbound send request and returns a deterministic success result.
    ///
    /// This is a no-op stub. No state is mutated. The returned external message
    /// ID is derived exclusively from `replyToExternalMessageID` when present,
    /// prefixed with `"fixture-sent-"`. When absent, a fixed constant is
    /// returned. Both derivations are stable across process runs.
    public func send(_ request: ConnectorSendRequest) async throws -> ConnectorSendResult {
        Self.logger.info(
            "send entered. connectorID=\(self._id.rawValue, privacy: .public) accountID=\(request.accountID.rawValue.uuidString, privacy: .public) toCount=\(request.toAddresses.count, privacy: .public) subject=\(request.subject, privacy: .public) hasReplyToExternalMessageID=\(request.replyToExternalMessageID != nil, privacy: .public)"
        )

        Self.logger.debug(
            "send decision. connectorID=\(self._id.rawValue, privacy: .public) reason=fixture_stub_no_state_mutation"
        )

        let externalMessageID: String

        if let replyToID = request.replyToExternalMessageID {
            externalMessageID = "fixture-sent-\(replyToID)"
            Self.logger.debug(
                "send resolved external ID from replyToExternalMessageID. connectorID=\(self._id.rawValue, privacy: .public) externalMessageID=\(externalMessageID, privacy: .public) reason=reply_context_present"
            )
        } else {
            externalMessageID = "fixture-sent-stub"
            Self.logger.debug(
                "send resolved external ID to constant. connectorID=\(self._id.rawValue, privacy: .public) externalMessageID=\(externalMessageID, privacy: .public) reason=no_reply_context"
            )
        }

        Self.logger.info(
            "send completed. connectorID=\(self._id.rawValue, privacy: .public) externalMessageID=\(externalMessageID, privacy: .public)"
        )

        return ConnectorSendResult(
            externalMessageID: externalMessageID,
            acceptedAt: nil
        )
    }

    // MARK: — Private Helpers

    /// Decodes an integer offset from a cursor string.
    /// Returns 0 for a nil cursor. Returns -1 for an invalid cursor string.
    private static func decodeOffset(from cursor: ConnectorSyncCursor?) -> Int {
        guard let cursor else { return 0 }
        return Int(cursor.rawValue) ?? -1
    }
}
