import Foundation

public enum StartupState: Equatable, Hashable, Sendable {
    case idle
    case loading
    case ready
}
