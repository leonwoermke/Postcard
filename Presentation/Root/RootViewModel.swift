import Foundation
import Combine
import OSLog

@MainActor
public final class RootViewModel: ObservableObject {

    @Published public private(set) var startupState: StartupState = .idle

    private let startupUseCase: StartupUseCase
    private var hasStarted: Bool = false

    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Presentation.RootViewModel"
    )

    public init(startupUseCase: StartupUseCase) {
        self.startupUseCase = startupUseCase
        logger.debug("Initialized RootViewModel")
    }

    public func start() async {
        logger.debug(
            "start() entered. hasStarted=\(self.hasStarted, privacy: .public)"
        )

        guard !hasStarted else {
            logger.debug("start() skipped. reason=already_started")
            return
        }

        hasStarted = true
        transition(to: .loading, reason: "startup_begin")

        let result = await startupUseCase.execute()
        transition(to: result, reason: "startup_complete")
    }

    private func transition(to newState: StartupState, reason: String) {
        let previous = startupState

        logger.debug(
            "State transition. from=\(String(describing: previous), privacy: .public) to=\(String(describing: newState), privacy: .public) reason=\(reason, privacy: .public)"
        )

        startupState = newState
    }
}
