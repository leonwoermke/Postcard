import Foundation

public struct Organization: Equatable, Hashable, Sendable {
    public let id: OrganizationID
    public let displayName: String
    public let domains: [String]
    public let senderAddresses: [String]

    public init(
        id: OrganizationID = OrganizationID(),
        displayName: String,
        domains: [String] = [],
        senderAddresses: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.domains = domains
        self.senderAddresses = senderAddresses
    }
}
