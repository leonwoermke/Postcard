import Foundation
import OSLog

public final class StartupUseCase {
    private let appBootstrap: AppBootstrap
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.StartupUseCase"
    )

    public init(appBootstrap: AppBootstrap) {
        self.appBootstrap = appBootstrap
        logger.debug("Initialized StartupUseCase")
    }

    public func execute() async -> StartupState {
        logger.debug("execute() started")

        do {
            let result = try await appBootstrap.bootstrap()
            logger.debug(
                "execute() completed. result=\(String(describing: result), privacy: .public)"
            )
            return result
        } catch {
            logger.error(
                "execute() failed. error=\(error.localizedDescription, privacy: .public)"
            )
            return .failed(error.localizedDescription)
        }
    }
}
