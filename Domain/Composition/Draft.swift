import Foundation

public struct Draft: Sendable {
    public enum Mode: String, Sendable {
        case roomReply
        case newMessage
    }

    public let accountID: AccountID

    public var subject: String
    public var bodyText: String

    public var toAddresses: [String]
    public var ccAddresses: [String]
    public var bccAddresses: [String]

    public var mode: Mode
    public var roomID: RoomID?
    public var compositionContext: CompositionContext?
    public var replyCapability: ReplyCapability?

    public init(
        accountID: AccountID,
        subject: String = "",
        bodyText: String = "",
        toAddresses: [String] = [],
        ccAddresses: [String] = [],
        bccAddresses: [String] = [],
        mode: Draft.Mode,
        roomID: RoomID? = nil,
        compositionContext: CompositionContext? = nil,
        replyCapability: ReplyCapability? = nil
    ) {
        self.accountID = accountID
        self.subject = subject
        self.bodyText = bodyText
        self.toAddresses = toAddresses
        self.ccAddresses = ccAddresses
        self.bccAddresses = bccAddresses
        self.mode = mode
        self.replyCapability = replyCapability

        switch mode {
        case .roomReply:
            self.roomID = roomID
            self.compositionContext = compositionContext

        case .newMessage:
            self.roomID = nil
            self.compositionContext = nil
        }
    }
}
