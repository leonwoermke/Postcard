import Foundation

/// The revisable interpretation of an Attachment.
///
/// SafetyClassification is contextual and risk-evaluative — it can change
/// as threat intelligence improves, as user signals accumulate, or as the
/// system's understanding of the sender evolves. It must not be encoded as
/// a canonical fact on Attachment itself.
///
/// AttachmentInterpretation follows the same pattern as MessageInterpretation,
/// BlockInterpretation, and EntityInterpretation: one active interpretation
/// per entity at a time, revisable without touching canonical data.
public struct AttachmentInterpretation: Equatable, Hashable, Sendable {
    public let attachmentID: AttachmentID
    public let safetyClassification: SafetyClassification
    public let confidence: Confidence
    public let explanation: String?

    public init(
        attachmentID: AttachmentID,
        safetyClassification: SafetyClassification,
        confidence: Confidence,
        explanation: String? = nil
    ) {
        self.attachmentID = attachmentID
        self.safetyClassification = safetyClassification
        self.confidence = confidence
        self.explanation = explanation
    }
}
