// Postcard/Infrastructure/Persistence/StorageModels/PersistenceValueBridging.swift

import Foundation
import GRDB

extension MessageID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> MessageID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return MessageID(rawValue: uuid)
    }
}

extension AttachmentID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> AttachmentID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return AttachmentID(rawValue: uuid)
    }
}

extension ContactID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ContactID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return ContactID(rawValue: uuid)
    }
}

extension OrganizationID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> OrganizationID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return OrganizationID(rawValue: uuid)
    }
}

extension AccountID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> AccountID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return AccountID(rawValue: uuid)
    }
}

extension RoomID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> RoomID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return RoomID(rawValue: uuid)
    }
}

extension ClusterID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> ClusterID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return ClusterID(rawValue: uuid)
    }
}

extension AssignmentID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> AssignmentID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return AssignmentID(rawValue: uuid)
    }
}

extension OverrideID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> OverrideID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return OverrideID(rawValue: uuid)
    }
}

extension LearningEventID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> LearningEventID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return LearningEventID(rawValue: uuid)
    }
}

extension AdaptiveProfileID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> AdaptiveProfileID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return AdaptiveProfileID(rawValue: uuid)
    }
}

extension PreferenceID: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue { rawValue.databaseValue }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> PreferenceID? {
        guard let uuid = UUID.fromDatabaseValue(dbValue) else { return nil }
        return PreferenceID(rawValue: uuid)
    }
}
