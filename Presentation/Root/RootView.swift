import SwiftUI
import OSLog

public struct RootView: View {
    @StateObject private var viewModel: RootViewModel

    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Presentation.RootView"
    )

    public init(viewModel: RootViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        logger.debug("Initialized RootView")
    }

    public var body: some View {
        Group {
            switch viewModel.startupState {
            case .idle:
                Color.clear

            case .loading:
                ProgressView()

            case .ready:
                Text("Postcard")

            case .failed(let reason):
                Text("Startup failed: \(reason)")
            }
        }
        .task {
            logger.debug(
                "RootView task entered. state=\(String(describing: viewModel.startupState), privacy: .public)"
            )
            await viewModel.start()
        }
    }
}
