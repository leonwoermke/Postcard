import Foundation

public protocol ProviderMessageTranslator: Sendable {
    associatedtype ProviderMessage: Sendable

    var connectorID: ConnectorID { get }

    func translate(
        _ message: ProviderMessage,
        accountID: AccountID
    ) throws -> TranslatedMessage
}
