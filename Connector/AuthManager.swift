import Foundation
import OSLog

public enum ConnectorAuthenticationState: Sendable {
    case signedOut
    case authorizing
    case authorized
    case unavailable(reason: String)
    case failed(reason: String)
}

public actor AuthManager {
    private static let logger: Logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Connector.AuthManager"
    )

    private var statesByConnectorID: [ConnectorID: ConnectorAuthenticationState]

    public init(
        initialStates: [ConnectorID: ConnectorAuthenticationState] = [:]
    ) {
        Self.logger.info(
            "init entered. initialStateCount=\(initialStates.count, privacy: .public)"
        )

        self.statesByConnectorID = initialStates

        Self.logger.info(
            "init completed. storedStateCount=\(self.statesByConnectorID.count, privacy: .public)"
        )
    }

    public func state(for connectorID: ConnectorID) -> ConnectorAuthenticationState {
        Self.logger.debug(
            "state lookup entered. connectorID=\(connectorID.rawValue, privacy: .public)"
        )

        guard let state: ConnectorAuthenticationState = self.statesByConnectorID[connectorID] else {
            Self.logger.debug(
                "state lookup defaulted. connectorID=\(connectorID.rawValue, privacy: .public) reason=missing_state"
            )
            return .signedOut
        }

        Self.logger.debug(
            "state lookup resolved. connectorID=\(connectorID.rawValue, privacy: .public) reason=stored_state_found"
        )

        return state
    }

    public func setState(
        _ state: ConnectorAuthenticationState,
        for connectorID: ConnectorID
    ) {
        Self.logger.info(
            "setState entered. connectorID=\(connectorID.rawValue, privacy: .public)"
        )

        let hadExistingState: Bool = self.statesByConnectorID[connectorID] != nil

        Self.logger.debug(
            "setState decision. connectorID=\(connectorID.rawValue, privacy: .public) hadExistingState=\(hadExistingState, privacy: .public) reason=update_auth_state"
        )

        Self.logger.debug(
            "setState before side effect. connectorID=\(connectorID.rawValue, privacy: .public)"
        )
        self.statesByConnectorID[connectorID] = state
        Self.logger.debug(
            "setState after side effect. connectorID=\(connectorID.rawValue, privacy: .public) storedStateCount=\(self.statesByConnectorID.count, privacy: .public)"
        )
    }

    public func clearState(for connectorID: ConnectorID) {
        Self.logger.info(
            "clearState entered. connectorID=\(connectorID.rawValue, privacy: .public)"
        )

        let hadExistingState: Bool = self.statesByConnectorID[connectorID] != nil

        Self.logger.debug(
            "clearState decision. connectorID=\(connectorID.rawValue, privacy: .public) hadExistingState=\(hadExistingState, privacy: .public) reason=clear_requested"
        )

        Self.logger.debug(
            "clearState before side effect. connectorID=\(connectorID.rawValue, privacy: .public)"
        )
        self.statesByConnectorID.removeValue(forKey: connectorID)
        Self.logger.debug(
            "clearState after side effect. connectorID=\(connectorID.rawValue, privacy: .public) storedStateCount=\(self.statesByConnectorID.count, privacy: .public)"
        )
    }

    public func authorizedConnectorIDs() -> [ConnectorID] {
        Self.logger.debug(
            "authorizedConnectorIDs entered. storedStateCount=\(self.statesByConnectorID.count, privacy: .public)"
        )

        let authorizedIDs: [ConnectorID] = self.statesByConnectorID
            .compactMap { entry in
                switch entry.value {
                case .authorized:
                    return entry.key
                case .signedOut, .authorizing, .unavailable, .failed:
                    return nil
                }
            }
            .sorted { left, right in
                left.rawValue < right.rawValue
            }

        Self.logger.debug(
            "authorizedConnectorIDs resolved. authorizedCount=\(authorizedIDs.count, privacy: .public) reason=connector_id_ascending"
        )

        return authorizedIDs
    }
}
