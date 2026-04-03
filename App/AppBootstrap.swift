import Foundation
import OSLog

public final class AppBootstrap {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.AppBootstrap"
    )

    public init() {
        logger.debug("Initialized AppBootstrap")
    }

    public func bootstrap() -> StartupState {
        logger.debug("bootstrap() started")

        let result: StartupState = .ready

        logger.debug("bootstrap() completed. result=\(String(describing: result), privacy: .public)")
        return result
    }
}
