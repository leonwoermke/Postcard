import Foundation

public struct MessageBody: Equatable, Hashable, Sendable {
    public let plainText: String?
    public let html: String?
    public let normalizedText: String?

    public init(
        plainText: String? = nil,
        html: String? = nil,
        normalizedText: String? = nil
    ) {
        self.plainText = plainText
        self.html = html
        self.normalizedText = normalizedText
    }
}
