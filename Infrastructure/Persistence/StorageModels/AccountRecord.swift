import Foundation
import GRDB

public struct AccountRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "accounts"

    public enum Columns {
        public static let id = Column("id")
        public static let payload = Column("payload")
    }

    public let id: String
    public let payload: Data

    public init(id: AccountID, account: Account) throws {
        self.id = id.rawValue.uuidString
        self.payload = try StorageCoding.encodePayload(AccountPayload(account))
    }

    public init(domain account: Account) throws {
        try self.init(id: account.id, account: account)
    }

    public func toDomain() throws -> Account {
        guard let decodedID = UUID(uuidString: id) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UUID for \(Columns.id.name): \(id)")
            )
        }

        return try StorageCoding
            .decodePayload(AccountPayload.self, from: payload)
            .toDomain(id: AccountID(rawValue: decodedID))
    }

    public func asDomain() throws -> Account {
        try toDomain()
    }
}

private struct AccountPayload: Codable, Sendable {
    let primaryAddress: String
    let displayName: String?

    init(_ account: Account) {
        self.primaryAddress = account.primaryAddress
        self.displayName = account.displayName
    }

    func toDomain(id: AccountID) -> Account {
        Account(
            id: id,
            primaryAddress: primaryAddress,
            displayName: displayName
        )
    }
}
