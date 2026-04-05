import Foundation
import OSLog

/// Composition root. Owns system assembly only.
/// Does not execute startup behavior.
/// Does not store transient UI state.
///
/// Lifetime conventions:
/// - `appBootstrap`, `startupUseCase` → application-lifetime shared instances
/// - `make*` methods → create a new instance per call (screen-lifetime or operation-lifetime)
public final class AppContainer {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.AppContainer"
    )

    // MARK: - Application-lifetime shared dependencies

    public private(set) lazy var appBootstrap: AppBootstrap = {
        logger.debug("Creating shared AppBootstrap")
        return AppBootstrap()
    }()

    public private(set) lazy var startupUseCase: StartupUseCase = {
        logger.debug("Creating shared StartupUseCase")
        return StartupUseCase(appBootstrap: appBootstrap)
    }()

    // MARK: - Init

    public init() {
        logger.debug("Initialized AppContainer")
    }

    // MARK: - Screen-lifetime factories

    /// Creates a new RootViewModel per call.
    /// Caller is responsible for lifetime management.
    @MainActor
    public func makeRootViewModel() -> RootViewModel {
        logger.debug("Factory call: makeRootViewModel")
        return RootViewModel(startupUseCase: startupUseCase)
    }
}
