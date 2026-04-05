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

    public var displayTitle: String? {
        if let title, title.isEmpty == false {
            return title
        }

        switch anchor {
        case .person:
            return nil
        case .organization:
            return nil
        case .group(let title):
            return title
        case .recurringSource(let title, _):
            return title
        case .systemSource(let title, _):
            return title
        case .unknown:
            return nil
        }
    }
}
