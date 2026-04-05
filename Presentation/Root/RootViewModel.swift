import Foundation
import Combine
import OSLog

@MainActor
public final class RootViewModel: ObservableObject {
    @Published public private(set) var startupState: StartupState

    private let startupUseCase: StartupUseCase
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Presentation.RootViewModel"
    )

    private var hasStarted: Bool

    public init(
        startupUseCase: StartupUseCase,
        initialState: StartupState = .idle
    ) {
        self.startupUseCase = startupUseCase
        self.startupState = initialState
        self.hasStarted = false

        logger.debug(
            "Initialized RootViewModel. initialState=\(String(describing: initialState), privacy: .public)"
        )
    }

    public func start() async {
        logger.debug(
            "start() entered. hasStarted=\(self.hasStarted, privacy: .public) currentState=\(String(describing: self.startupState), privacy: .public)"
        )

        guard hasStarted == false else {
            logger.debug("start() skipped. reason=already_started")
            return
        }

        hasStarted = true

        transition(to: .loading, reason: "startup_begin")

        do {
            let result = try await startupUseCase.start()
            transition(to: result, reason: "startup_complete")
        } catch {
            logger.error("start() failed. reason=startup_error")
            transition(to: .idle, reason: "startup_failed")
        }
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
