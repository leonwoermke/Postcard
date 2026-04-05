import Foundation

public struct Contact: Equatable, Hashable, Sendable {
    public let id: ContactID
    public let displayName: String?
    public let preferredName: String?
    public let emailAddresses: [String]

    public init(
        id: ContactID = ContactID(),
        displayName: String? = nil,
        preferredName: String? = nil,
        emailAddresses: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.preferredName = preferredName
        self.emailAddresses = emailAddresses
    }
}
