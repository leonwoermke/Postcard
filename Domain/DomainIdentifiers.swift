import Foundation

public struct MessageID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct AttachmentID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct ContactID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct OrganizationID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct AccountID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct RoomID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct ClusterID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct AssignmentID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct OverrideID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct LearningEventID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct AdaptiveProfileID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct PreferenceID: Equatable, Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct BlockID: Equatable, Hashable, Sendable, Codable {
    public enum ContentForm: String, Equatable, Hashable, Sendable, Codable {
        case plainText
        case html
        case normalizedText
    }

    public struct SourceBoundary: Equatable, Hashable, Sendable, Codable {
        public let contentForm: ContentForm
        public let lowerBound: Int
        public let upperBound: Int

        public init(
            contentForm: ContentForm,
            lowerBound: Int,
            upperBound: Int
        ) {
            self.contentForm = contentForm
            self.lowerBound = lowerBound
            self.upperBound = upperBound
        }
    }

    public let rawValue: String
    public let messageID: MessageID
    public let sourceBoundary: SourceBoundary

    public init(
        rawValue: String,
        messageID: MessageID,
        sourceBoundary: SourceBoundary
    ) {
        self.rawValue = rawValue
        self.messageID = messageID
        self.sourceBoundary = sourceBoundary
    }
}

public struct EntityID: Equatable, Hashable, Sendable, Codable {
    public struct SourceRegion: Equatable, Hashable, Sendable, Codable {
        public let contentForm: BlockID.ContentForm
        public let lowerBound: Int
        public let upperBound: Int

        public init(
            contentForm: BlockID.ContentForm,
            lowerBound: Int,
            upperBound: Int
        ) {
            self.contentForm = contentForm
            self.lowerBound = lowerBound
            self.upperBound = upperBound
        }
    }

    public struct SourceDescriptor: Equatable, Hashable, Sendable, Codable {
        public let messageID: MessageID
        public let blockID: BlockID?
        public let kind: EntityKind
        public let rawValue: String
        public let sourceRegion: SourceRegion?

        public init(
            messageID: MessageID,
            blockID: BlockID? = nil,
            kind: EntityKind,
            rawValue: String,
            sourceRegion: SourceRegion? = nil
        ) {
            self.messageID = messageID
            self.blockID = blockID
            self.kind = kind
            self.rawValue = rawValue
            self.sourceRegion = sourceRegion
        }
    }

    public let rawValue: String
    public let sourceDescriptor: SourceDescriptor

    public init(
        rawValue: String,
        sourceDescriptor: SourceDescriptor
    ) {
        self.rawValue = rawValue
        self.sourceDescriptor = sourceDescriptor
    }
}
