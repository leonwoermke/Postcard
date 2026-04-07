import Foundation

public struct ReplyCapability: Sendable {
    public enum Status: Sendable {
        case available(targetAddress: String, targetDisplayName: String?)
        case unavailable(reason: UnavailableReason)
    }

    public enum UnavailableReason: Sendable {
        case missingReplyTarget
        case nonReplyAddress
        case threadNotWritable
        case unsupportedByConnector
        case unknown
        case other(String)
    }

    public let status: Status

    public init(status: ReplyCapability.Status) {
        self.status = status
    }

    public var isReplyAllowed: Bool {
        switch self.status {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    public var targetAddress: String? {
        switch self.status {
        case .available(let targetAddress, _):
            return targetAddress
        case .unavailable:
            return nil
        }
    }

    public var targetDisplayName: String? {
        switch self.status {
        case .available(_, let targetDisplayName):
            return targetDisplayName
        case .unavailable:
            return nil
        }
    }
}
