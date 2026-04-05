import Foundation

public struct ExpiryContext: Equatable, Hashable, Sendable, Codable {
    public let expiresAt: Date
    public let urgencyWindow: TimeInterval?

    public init(
        expiresAt: Date,
        urgencyWindow: TimeInterval? = nil
    ) {
        self.expiresAt = expiresAt
        self.urgencyWindow = urgencyWindow
    }

    public var hasUrgencyWindow: Bool {
        urgencyWindow != nil
    }
}
