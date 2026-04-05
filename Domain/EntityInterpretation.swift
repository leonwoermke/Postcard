import Foundation

public struct EntityInterpretation: Equatable, Hashable, Sendable {
    public let entityID: EntityID
    public let confidence: Confidence
    public let resolution: InterpretationResolution<EntityKind>
    public let relatedActions: [ActionKind]
    public let expiryContext: ExpiryContext?
    public let summary: String?

    public init(
        entityID: EntityID,
        confidence: Confidence,
        resolution: InterpretationResolution<EntityKind>,
        relatedActions: [ActionKind] = [],
        expiryContext: ExpiryContext? = nil,
        summary: String? = nil
    ) {
        self.entityID = entityID
        self.confidence = confidence
        self.resolution = resolution
        self.relatedActions = relatedActions
        self.expiryContext = expiryContext
        self.summary = summary
    }
}
