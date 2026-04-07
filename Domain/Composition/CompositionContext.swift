import Foundation

public struct CompositionContext: Sendable {
    public enum QuotedThreadMode: String, Sendable {
        case include
        case exclude
        case ask
    }

    public let greeting: String?
    public let closing: String?
    public let signature: String?
    public let quotedThreadMode: QuotedThreadMode
    public let systemFooterEnabled: Bool
    public let replyTargetDisplayName: String?

    public init(
        greeting: String? = nil,
        closing: String? = nil,
        signature: String? = nil,
        quotedThreadMode: CompositionContext.QuotedThreadMode = .ask,
        systemFooterEnabled: Bool = true,
        replyTargetDisplayName: String? = nil
    ) {
        self.greeting = greeting
        self.closing = closing
        self.signature = signature
        self.quotedThreadMode = quotedThreadMode
        self.systemFooterEnabled = systemFooterEnabled
        self.replyTargetDisplayName = replyTargetDisplayName
    }
}
