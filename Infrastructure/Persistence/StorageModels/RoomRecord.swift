import Foundation
import GRDB

public struct RoomRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "rooms"

    public enum Columns {
        public static let id = Column("id")
        public static let anchorKind = Column("anchor_kind")
        public static let contactID = Column("contact_id")
        public static let organizationID = Column("organization_id")
        public static let title = Column("title")
        public static let anchorTitle = Column("anchor_title")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case anchorKind = "anchor_kind"
        case contactID = "contact_id"
        case organizationID = "organization_id"
        case title
        case anchorTitle = "anchor_title"
    }

    public let id: String
    public let anchorKind: String
    public let contactID: String?
    public let organizationID: String?
    public let title: String?
    public let anchorTitle: String?

    public init(id: RoomID, room: Room) {
        self.id = id.rawValue.uuidString
        self.title = room.title

        switch room.anchor {
        case .person(let contactID):
            self.anchorKind = "person"
            self.contactID = contactID.rawValue.uuidString
            self.organizationID = nil
            self.anchorTitle = nil

        case .organization(let organizationID):
            self.anchorKind = "organization"
            self.contactID = nil
            self.organizationID = organizationID.rawValue.uuidString
            self.anchorTitle = nil

        case .group(let title):
            self.anchorKind = "group"
            self.contactID = nil
            self.organizationID = nil
            self.anchorTitle = title

        case .recurringSource(let title, let organizationID):
            self.anchorKind = "recurringSource"
            self.contactID = nil
            self.organizationID = organizationID?.rawValue.uuidString
            self.anchorTitle = title

        case .systemSource(let title, let organizationID):
            self.anchorKind = "systemSource"
            self.contactID = nil
            self.organizationID = organizationID?.rawValue.uuidString
            self.anchorTitle = title

        case .unknown:
            self.anchorKind = "unknown"
            self.contactID = nil
            self.organizationID = nil
            self.anchorTitle = nil
        }
    }

    public init(domain room: Room) {
        self.init(id: room.id, room: room)
    }

    public func toDomain() throws -> Room {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        return Room(
            id: RoomID(rawValue: decodedID),
            anchor: try decodeAnchor(),
            title: title
        )
    }

    public func asDomain() throws -> Room {
        try toDomain()
    }

    public func asLookup() throws -> RoomLookup {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        return RoomLookup(
            id: RoomID(rawValue: decodedID),
            anchor: try decodeAnchor(),
            title: title
        )
    }

    private func decodeAnchor() throws -> Room.Anchor {
        switch anchorKind {
        case "person":
            guard let contactID, let decoded = UUID(uuidString: contactID) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Invalid contact UUID for \(Columns.contactID.name)")
                )
            }
            return .person(contactID: ContactID(rawValue: decoded))

        case "organization":
            guard let organizationID, let decoded = UUID(uuidString: organizationID) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Invalid organization UUID for \(Columns.organizationID.name)")
                )
            }
            return .organization(organizationID: OrganizationID(rawValue: decoded))

        case "group":
            return .group(title: anchorTitle)

        case "recurringSource":
            return .recurringSource(
                title: anchorTitle,
                organizationID: organizationID.flatMap(UUID.init(uuidString:)).map(OrganizationID.init(rawValue:))
            )

        case "systemSource":
            return .systemSource(
                title: anchorTitle,
                organizationID: organizationID.flatMap(UUID.init(uuidString:)).map(OrganizationID.init(rawValue:))
            )

        default:
            return .unknown
        }
    }
}
