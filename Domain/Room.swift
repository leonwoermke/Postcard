import Foundation

public struct Room: Equatable, Hashable, Sendable {
    public enum Anchor: Equatable, Hashable, Sendable {
        case person(contactID: ContactID)
        case organization(organizationID: OrganizationID)
        case group(title: String?)
        case recurringSource(title: String?, organizationID: OrganizationID?)
        case systemSource(title: String?, organizationID: OrganizationID?)
        case unknown
    }

    public let id: RoomID
    public let anchor: Anchor
    public let title: String?

    public init(
        id: RoomID = RoomID(),
        anchor: Anchor,
        title: String? = nil
    ) {
        self.id = id
        self.anchor = anchor
        self.title = title
    }
}
