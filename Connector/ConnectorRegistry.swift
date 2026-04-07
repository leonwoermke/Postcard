import Foundation
import OSLog

public enum ConnectorRegistryError: Error, Sendable {
    case duplicateConnectorID(String)
}

public final class ConnectorRegistry {
    private static let logger: Logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Connector.ConnectorRegistry"
    )

    private let orderedConnectors: [any EmailConnector]
    private let connectorsByID: [ConnectorID: any EmailConnector]

    public init(connectors: [any EmailConnector]) throws {
        Self.logger.info("init entered. connectorCount=\(connectors.count, privacy: .public)")

        var seenIDs: Set<ConnectorID> = Set<ConnectorID>()
        var byID: [ConnectorID: any EmailConnector] = [:]

        for connector in connectors {
            let connectorID: ConnectorID = connector.id

            if seenIDs.contains(connectorID) {
                Self.logger.error(
                    "duplicate connector identifier detected. connectorID=\(connectorID.rawValue, privacy: .public)"
                )
                throw ConnectorRegistryError.duplicateConnectorID(connectorID.rawValue)
            }

            Self.logger.debug(
                "registering connector candidate. connectorID=\(connectorID.rawValue, privacy: .public)"
            )

            seenIDs.insert(connectorID)
            byID[connectorID] = connector
        }

        let sortedConnectors: [any EmailConnector] = connectors.sorted { left, right in
            left.id.rawValue < right.id.rawValue
        }

        Self.logger.info(
            "registry ordering resolved. connectorCount=\(sortedConnectors.count, privacy: .public) reason=connector_id_ascending"
        )

        self.orderedConnectors = sortedConnectors
        self.connectorsByID = byID

        Self.logger.info(
            "init completed. registeredConnectorCount=\(self.orderedConnectors.count, privacy: .public)"
        )
    }

    public func allConnectors() -> [any EmailConnector] {
        Self.logger.debug(
            "allConnectors entered. connectorCount=\(self.orderedConnectors.count, privacy: .public)"
        )
        return self.orderedConnectors
    }

    public func connector(for id: ConnectorID) -> (any EmailConnector)? {
        Self.logger.debug(
            "connector lookup entered. connectorID=\(id.rawValue, privacy: .public)"
        )

        let connector: (any EmailConnector)? = self.connectorsByID[id]

        if connector == nil {
            Self.logger.debug(
                "connector lookup resolved to nil. connectorID=\(id.rawValue, privacy: .public) reason=not_registered"
            )
        } else {
            Self.logger.debug(
                "connector lookup resolved. connectorID=\(id.rawValue, privacy: .public) reason=registered"
            )
        }

        return connector
    }
}
