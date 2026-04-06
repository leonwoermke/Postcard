import Foundation
import GRDB

public struct OrganizationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "organizations"

    public enum Columns {
        public static let id = Column("id")
        public static let displayName = Column("display_name")
        public static let domainsJSON = Column("domains_json")
        public static let senderAddressesJSON = Column("sender_addresses_json")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case domainsJSON = "domains_json"
        case senderAddressesJSON = "sender_addresses_json"
    }

    public let id: String
    public let displayName: String
    public let domainsJSON: Data
    public let senderAddressesJSON: Data

    public init(id: OrganizationID, organization: Organization) throws {
        self.id = id.rawValue.uuidString
        self.displayName = organization.displayName
        self.domainsJSON = try JSONEncoder().encode(organization.domains)
        self.senderAddressesJSON = try JSONEncoder().encode(organization.senderAddresses)
    }

    public init(domain organization: Organization) throws {
        try self.init(id: organization.id, organization: organization)
    }

    public func toDomain() throws -> Organization {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        return Organization(
            id: OrganizationID(rawValue: decodedID),
            displayName: displayName,
            domains: try JSONDecoder().decode([String].self, from: domainsJSON),
            senderAddresses: try JSONDecoder().decode([String].self, from: senderAddressesJSON)
        )
    }

    public func asDomain() throws -> Organization {
        try toDomain()
    }
}
