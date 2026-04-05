import Foundation
import OSLog

public actor StartupUseCase {
    private let bootstrapper: any StartupBootstrapping
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Application.StartupUseCase"
    )

    private var cachedResult: StartupState?

    public init(bootstrapper: any StartupBootstrapping) {
        self.bootstrapper = bootstrapper

        logger.debug("Initialized StartupUseCase")
    }

    public func start() async throws -> StartupState {
        logger.debug("start() entered")

        if let cachedResult {
            logger.debug(
                "start() returning cached result. result=\(String(describing: cachedResult), privacy: .public)"
            )
            return cachedResult
        }

        logger.debug("start() executing bootstrap. reason=no_cached_result")

        let result = try await bootstrapper.bootstrap()
        cachedResult = result

        logger.debug(
            "start() completed. cachedResult=\(String(describing: result), privacy: .public)"
        )

        return result
    }
}
