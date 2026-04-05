import Foundation

public struct Account: Equatable, Hashable, Sendable {
    public let id: AccountID
    public let primaryAddress: String
    public let displayName: String?

    public init(
        id: AccountID = AccountID(),
        primaryAddress: String,
        displayName: String? = nil
    ) {
        self.id = id
        self.primaryAddress = primaryAddress
        self.displayName = displayName
    }
}
