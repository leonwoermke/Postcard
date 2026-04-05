import Foundation
import OSLog

public protocol StartupBootstrapping: Sendable {
    func bootstrap() async throws -> StartupState
}

public final class AppBootstrap: StartupBootstrapping, @unchecked Sendable {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.AppBootstrap"
    )

    public init() {
        logger.debug("Initialized AppBootstrap")
    }

    public func bootstrap() async throws -> StartupState {
        logger.debug("bootstrap() started")

        let result: StartupState = .ready

        logger.debug(
            "bootstrap() completed. result=\(String(describing: result), privacy: .public)"
        )

        return result
    }
}
