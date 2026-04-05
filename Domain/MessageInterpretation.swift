import Foundation

public enum InterpretationResolution<Candidate: Equatable & Hashable & Sendable>: Equatable, Hashable, Sendable {
    case resolved(Candidate)
    case ambiguous([Candidate])
    case unknown
}

public struct MessageInterpretation: Equatable, Hashable, Sendable {
    public let messageID: MessageID
    public let confidence: Confidence
    public let resolution: InterpretationResolution<MessageKind>
    public let relatedActions: [ActionKind]
    public let summary: String?

    public init(
        messageID: MessageID,
        confidence: Confidence,
        resolution: InterpretationResolution<MessageKind>,
        relatedActions: [ActionKind] = [],
        summary: String? = nil
    ) {
        self.messageID = messageID
        self.confidence = confidence
        self.resolution = resolution
        self.relatedActions = relatedActions
        self.summary = summary
    }
}
