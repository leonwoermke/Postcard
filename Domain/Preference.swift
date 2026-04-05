import Foundation

public struct Preference: Equatable, Hashable, Sendable {
    public enum Scope: Equatable, Hashable, Sendable {
        case account(AccountID)
        case global
        case unknown
        case other(String)
    }

    public enum Kind: Equatable, Hashable, Sendable {
        case messageListDensity
        case roomDensity
        case originalContentVisibility
        case ambiguityHandling
        case compositionGreetingStyle
        case compositionClosingStyle
        case compositionSignatureTemplate
        case compositionFooterEnabled
        case quotedThreadInclusion
        case unknown
        case other(String)
    }

    public enum Value: Equatable, Hashable, Sendable {
        case boolean(Bool)
        case string(String)
        case selection(String)
        case unknown
        case other(String)
    }

    public let id: PreferenceID
    public let scope: Scope
    public let kind: Kind
    public let value: Value

    public init(
        id: PreferenceID = PreferenceID(),
        scope: Scope,
        kind: Kind,
        value: Value
    ) {
        self.id = id
        self.scope = scope
        self.kind = kind
        self.value = value
    }
}
