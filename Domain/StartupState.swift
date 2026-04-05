import Foundation

public enum StartupState: Equatable, Hashable, Sendable, Codable {
    case idle
    case loading
    case ready
}
