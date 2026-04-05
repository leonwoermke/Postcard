import Foundation
import OSLog

public final class AppContainer {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "App.AppContainer"
    )

    public let startupBootstrapper: any StartupBootstrapping
    public let startupUseCase: StartupUseCase

    public init(
        startupBootstrapperFactory: () -> any StartupBootstrapping = {
            AppBootstrap()
        },
        startupUseCaseFactory: ((any StartupBootstrapping) -> StartupUseCase)? = nil
    ) {
        logger.debug("AppContainer init entered")

        let startupBootstrapper = startupBootstrapperFactory()
        self.startupBootstrapper = startupBootstrapper

        if let startupUseCaseFactory {
            self.startupUseCase = startupUseCaseFactory(startupBootstrapper)
            logger.debug("Created shared StartupUseCase. mode=custom_factory")
        } else {
            self.startupUseCase = StartupUseCase(bootstrapper: startupBootstrapper)
            logger.debug("Created shared StartupUseCase. mode=default_factory")
        }

        logger.debug("Initialized AppContainer")
    }

    public func makeAppBootstrap() -> any StartupBootstrapping {
        logger.debug("Factory call: makeAppBootstrap")
        return startupBootstrapper
    }

    @MainActor
    public func makeRootViewModel() -> RootViewModel {
        logger.debug("Factory call: makeRootViewModel")
        return RootViewModel(startupUseCase: startupUseCase)
    }
}
