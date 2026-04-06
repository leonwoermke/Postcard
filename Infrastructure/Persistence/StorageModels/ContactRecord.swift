import Foundation
import GRDB

public struct ContactRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "contacts"

    public enum Columns {
        public static let id = Column("id")
        public static let displayName = Column("display_name")
        public static let preferredName = Column("preferred_name")
        public static let emailAddressesJSON = Column("email_addresses_json")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case preferredName = "preferred_name"
        case emailAddressesJSON = "email_addresses_json"
    }

    public let id: String
    public let displayName: String?
    public let preferredName: String?
    public let emailAddressesJSON: Data

    public init(id: ContactID, contact: Contact) throws {
        self.id = id.rawValue.uuidString
        self.displayName = contact.displayName
        self.preferredName = contact.preferredName
        self.emailAddressesJSON = try JSONEncoder().encode(contact.emailAddresses)
    }

    public init(domain contact: Contact) throws {
        try self.init(id: contact.id, contact: contact)
    }

    public func toDomain() throws -> Contact {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        return Contact(
            id: ContactID(rawValue: decodedID),
            displayName: displayName,
            preferredName: preferredName,
            emailAddresses: try JSONDecoder().decode([String].self, from: emailAddressesJSON)
        )
    }

    public func asDomain() throws -> Contact {
        try toDomain()
    }
}
