import Foundation

public struct BlockInterpretation: Equatable, Hashable, Sendable {
    public enum Kind: Equatable, Hashable, Sendable {
        case primaryContent
        case supportingContent
        case quote
        case signatureLike
        case tabular
        case actionCluster
        case boilerplate
        case unknown
        case other(String)
    }

    public let blockID: BlockID
    public let confidence: Confidence
    public let resolution: InterpretationResolution<Kind>
    public let summary: String?

    public init(
        blockID: BlockID,
        confidence: Confidence,
        resolution: InterpretationResolution<Kind>,
        summary: String? = nil
    ) {
        self.blockID = blockID
        self.confidence = confidence
        self.resolution = resolution
        self.summary = summary
    }
}
