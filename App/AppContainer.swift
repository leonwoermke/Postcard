import Foundation
import OSLog

public final class AppContainer {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "App.AppContainer"
    )

    // MARK: — Phase 1: Startup

    public let startupBootstrapper: any StartupBootstrapping
    public let startupUseCase: StartupUseCase

    // MARK: — Phase 4: Connector Boundary

    /// The fixture connector serving deterministic in-memory messages for
    /// pipeline validation. Replaced by a real connector implementation in a
    /// future phase.
    public let fixtureConnector: FixtureEmailConnector

    /// Registry holding all active connectors. Currently contains only the
    /// fixture connector.
    public let connectorRegistry: ConnectorRegistry

    /// Authentication state manager for the connector boundary.
    public let authManager: AuthManager

    // MARK: — Phase 4: Intake Pipeline (partial — see known issues)

    /// Original content preserver. Fully wired.
    public let contentPreserver: OriginalContentPreserver

    // TODO: [KNOWN ISSUE] CanonicalMessageBuilder cannot be instantiated until
    // concrete implementations of CanonicalIdentifierGenerating and
    // CanonicalDomainBuilding are provided. These are Phase 4 work items not
    // yet implemented. See known_issues.md.

    // TODO: [KNOWN ISSUE] MessageImportUseCase cannot be fully wired until:
    //   1. CanonicalMessageBuilder is instantiable (see above).
    //   2. The ConnectorInboundMessage → TranslatedMessage translation gap is
    //      resolved. The current processSingleMessage uses a runtime cast that
    //      will fail for all fixture messages, returning .failed for every
    //      import attempt. See known_issues.md.

    // TODO: [KNOWN ISSUE] GRDB-backed repositories (MessageRepositoryGRDB,
    // AttachmentRepositoryGRDB, etc.) require a DatabaseContainer that has
    // completed async setUp(). AppContainer.init is synchronous and has no
    // mechanism to own or initialise DatabaseContainer at this time. A design
    // decision is required: either AppContainer gains an async setUp() method,
    // or DatabaseContainer is injected already-initialised from outside.
    // See known_issues.md.

    // TODO: [KNOWN ISSUE] SearchRepositoryGRDB requires MessageRepository
    // injection at construction time. This is a Phase 4 composition task
    // noted in current_state.md. Cannot be wired until the database
    // initialisation path above is resolved.

    // MARK: — Lifecycle

    public init(
        startupBootstrapperFactory: () -> any StartupBootstrapping = {
            AppBootstrap()
        },
        startupUseCaseFactory: ((any StartupBootstrapping) -> StartupUseCase)? = nil
    ) {
        logger.debug("AppContainer init entered")

        // MARK: Phase 1 — Startup

        let startupBootstrapper = startupBootstrapperFactory()
        self.startupBootstrapper = startupBootstrapper

        if let startupUseCaseFactory {
            self.startupUseCase = startupUseCaseFactory(startupBootstrapper)
            logger.debug("Created shared StartupUseCase. mode=custom_factory")
        } else {
            self.startupUseCase = StartupUseCase(bootstrapper: startupBootstrapper)
            logger.debug("Created shared StartupUseCase. mode=default_factory")
        }

        // MARK: Phase 4 — Connector Boundary

        logger.debug("Phase 4 wiring entered. scope=connector_boundary")

        let fixtureMessages = AppContainer.makeFixtureMessages()

        let fixture = FixtureEmailConnector(
            messages: fixtureMessages,
            pageSize: 20,
            id: FixtureEmailConnector.defaultConnectorID,
            displayName: "Fixture Connector"
        )
        self.fixtureConnector = fixture

        logger.debug(
            "FixtureEmailConnector created. messageCount=\(fixtureMessages.count, privacy: .public)"
        )

        // ConnectorRegistry throws only on duplicate IDs. The fixture set
        // contains exactly one connector, so this force-try is safe and
        // deterministic. A duplicate-ID condition here is a programmer error,
        // not a runtime condition.
        let registry = try! ConnectorRegistry(connectors: [fixture])
        self.connectorRegistry = registry

        logger.debug(
            "ConnectorRegistry created. connectorCount=1 reason=fixture_only"
        )

        self.authManager = AuthManager(
            initialStates: [
                FixtureEmailConnector.defaultConnectorID: .authorized
            ]
        )

        logger.debug(
            "AuthManager created. preAuthorizedConnectorID=\(FixtureEmailConnector.defaultConnectorID.rawValue, privacy: .public) reason=fixture_requires_no_real_auth"
        )

        // MARK: Phase 4 — Intake Pipeline (partial)

        logger.debug("Phase 4 wiring entered. scope=intake_pipeline")

        self.contentPreserver = OriginalContentPreserver(
            clock: SystemOriginalContentPreserverClock()
        )

        logger.debug("OriginalContentPreserver created. reason=default_system_clock")

        logger.debug(
            "AppContainer init completed. status=partial blockers=CanonicalMessageBuilder,MessageImportUseCase,DatabaseContainer,SearchRepositoryGRDB"
        )
    }

    // MARK: — Phase 1: Factories

    @MainActor
    public func makeRootViewModel() -> RootViewModel {
        logger.debug("Factory call: makeRootViewModel")
        return RootViewModel(startupUseCase: startupUseCase)
    }

    // MARK: — Phase 4: Import Entry Point

    /// Executes the message import pipeline against all registered connectors.
    ///
    /// This method is a stub entry point. It will have no effect until the
    /// known blockers (CanonicalMessageBuilder, translation gap, and
    /// DatabaseContainer initialisation) are resolved. It is provided so
    /// call sites can be wired now and will activate automatically once
    /// the blockers are cleared.
    ///
    /// - Note: See known_issues.md for the full list of open blockers.
    public func runImport() async {
        logger.info(
            "runImport entered. reason=phase4_import_entry_point status=blocked_pending_canonical_builder_and_db"
        )

        // TODO: [KNOWN ISSUE] Replace this stub with MessageImportUseCase.execute()
        // once CanonicalMessageBuilder, repository wiring, and DatabaseContainer
        // initialisation are resolved. See known_issues.md.

        logger.info(
            "runImport exited. result=no_op reason=import_use_case_not_yet_wired"
        )
    }

    // MARK: — Private: Fixture Dataset

    /// Returns a deterministic, hardcoded set of fixture messages for pipeline
    /// validation. No randomness. Fixed ordering by construction.
    private static func makeFixtureMessages() -> [ConnectorInboundMessage] {
        // Message 1: plain conversational message
        let message1 = ConnectorInboundMessage(
            externalMessageID: "fixture-msg-001",
            threadReference: "fixture-thread-A",
            subject: "Catch up next week?",
            sentAt: Date(timeIntervalSince1970: 1_700_000_000),
            receivedAt: Date(timeIntervalSince1970: 1_700_000_060),
            recipients: [
                ConnectorRecipient(
                    address: "anna@example.com",
                    displayName: "Anna",
                    kind: .from
                ),
                ConnectorRecipient(
                    address: "leon@example.com",
                    displayName: "Leon",
                    kind: .to
                )
            ],
            plainTextBody: "Hi Leon, are you free for a call next week? Let me know what works.",
            htmlBody: nil,
            attachments: [],
            headers: [
                ConnectorHeader(name: "Message-ID", value: "<fixture-msg-001@example.com>")
            ],
            rawSource: nil
        )

        // Message 2: transactional message with attachment metadata
        let message2 = ConnectorInboundMessage(
            externalMessageID: "fixture-msg-002",
            threadReference: "fixture-thread-B",
            subject: "Your invoice #INV-2024-0042",
            sentAt: Date(timeIntervalSince1970: 1_700_100_000),
            receivedAt: Date(timeIntervalSince1970: 1_700_100_120),
            recipients: [
                ConnectorRecipient(
                    address: "billing@acme.com",
                    displayName: "Acme Billing",
                    kind: .from
                ),
                ConnectorRecipient(
                    address: "leon@example.com",
                    displayName: "Leon",
                    kind: .to
                )
            ],
            plainTextBody: "Please find your invoice attached. Payment is due within 30 days.",
            htmlBody: "<p>Please find your invoice attached. Payment is due within 30 days.</p>",
            attachments: [
                ConnectorAttachment(
                    externalID: "fixture-attachment-001",
                    fileName: "INV-2024-0042.pdf",
                    mimeType: "application/pdf",
                    byteCount: 48_320,
                    inline: false
                )
            ],
            headers: [
                ConnectorHeader(name: "Message-ID", value: "<fixture-msg-002@acme.com>")
            ],
            rawSource: nil
        )

        // Message 3: reply message — tests threading path via replyToExternalMessageID
        let message3 = ConnectorInboundMessage(
            externalMessageID: "fixture-msg-003",
            threadReference: "fixture-thread-A",
            subject: "Re: Catch up next week?",
            sentAt: Date(timeIntervalSince1970: 1_700_200_000),
            receivedAt: Date(timeIntervalSince1970: 1_700_200_090),
            recipients: [
                ConnectorRecipient(
                    address: "leon@example.com",
                    displayName: "Leon",
                    kind: .from
                ),
                ConnectorRecipient(
                    address: "anna@example.com",
                    displayName: "Anna",
                    kind: .to
                )
            ],
            plainTextBody: "Thursday afternoon works for me. Does 3pm suit you?",
            htmlBody: nil,
            attachments: [],
            headers: [
                ConnectorHeader(name: "Message-ID", value: "<fixture-msg-003@example.com>"),
                ConnectorHeader(name: "In-Reply-To", value: "<fixture-msg-001@example.com>")
            ],
            rawSource: nil
        )

        return [message1, message2, message3]
    }
}
