import SwiftUI
import OSLog

@main
struct AppEntry: App {
    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "App.AppEntry"
    )

    private let container: AppContainer
    @StateObject private var rootViewModel: RootViewModel

    init() {
        let container = AppContainer()
        self.container = container
        _rootViewModel = StateObject(wrappedValue: container.makeRootViewModel())

        logger.debug("Initialized AppEntry")
    }

    var body: some Scene {
        logger.debug("body entered")

        return WindowGroup {
            RootView(viewModel: rootViewModel)
        }
    }
}
