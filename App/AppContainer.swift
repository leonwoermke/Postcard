import Foundation
import OSLog

public final class AppContainer {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.AppContainer"
    )

    private let initialStartupState: StartupState

    private lazy var sharedAppBootstrap: AppBootstrap = {
        logger.debug("Creating shared AppBootstrap")
        return AppBootstrap()
    }()

    private lazy var sharedRootViewModel: RootViewModel = {
        logger.debug(
            "Creating shared RootViewModel. initialStartupState=\(String(describing: self.initialStartupState), privacy: .public)"
        )
        return RootViewModel(
            appBootstrap: sharedAppBootstrap,
            initialState: initialStartupState
        )
    }()

    public init(initialStartupState: StartupState = .idle) {
        self.initialStartupState = initialStartupState

        logger.debug(
            "Initialized AppContainer. initialStartupState=\(String(describing: initialStartupState), privacy: .public)"
        )
    }

    public func makeAppBootstrap() -> AppBootstrap {
        logger.debug("Factory call: makeAppBootstrap")
        return sharedAppBootstrap
    }

    public func makeRootViewModel() -> RootViewModel {
        logger.debug("Factory call: makeRootViewModel")
        return sharedRootViewModel
    }
}
