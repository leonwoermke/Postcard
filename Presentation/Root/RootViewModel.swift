import Foundation
import Combine
import OSLog

@MainActor
public final class RootViewModel: ObservableObject {
    @Published public private(set) var startupState: StartupState

    private let appBootstrap: AppBootstrap
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Presentation.RootViewModel"
    )

    private var hasStarted: Bool

    public init(
        appBootstrap: AppBootstrap,
        initialState: StartupState = .idle
    ) {
        self.appBootstrap = appBootstrap
        self.startupState = initialState
        self.hasStarted = false

        logger.debug(
            "Initialized RootViewModel. initialState=\(String(describing: initialState), privacy: .public)"
        )
    }

    public func start() {
        logger.debug(
            "start() entered. hasStarted=\(self.hasStarted, privacy: .public) currentState=\(String(describing: self.startupState), privacy: .public)"
        )

        guard hasStarted == false else {
            logger.debug("start() skipped. reason=already_started")
            return
        }

        hasStarted = true

        transition(to: .loading, reason: "bootstrap_begin")

        let result = appBootstrap.bootstrap()

        transition(to: result, reason: "bootstrap_complete")
    }

    private func transition(to newState: StartupState, reason: String) {
        let previousState = startupState

        logger.debug(
            "State transition requested. from=\(String(describing: previousState), privacy: .public) to=\(String(describing: newState), privacy: .public) reason=\(reason, privacy: .public)"
        )

        startupState = newState

        logger.debug(
            "State transition applied. from=\(String(describing: previousState), privacy: .public) to=\(String(describing: self.startupState), privacy: .public) reason=\(reason, privacy: .public)"
        )
    }
}
