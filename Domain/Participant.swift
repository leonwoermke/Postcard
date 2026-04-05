import Foundation

public struct Participant: Equatable, Hashable, Sendable {
    public enum Role: Equatable, Hashable, Sendable {
        case from
        case to
        case cc
        case bcc
        case replyTo
    }

    public let role: Role
    public let address: String
    public let displayName: String?

    public init(
        role: Role,
        address: String,
        displayName: String? = nil
    ) {
        self.role = role
        self.address = address
        self.displayName = displayName
    }
}
