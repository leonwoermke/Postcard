import SwiftUI
import OSLog

public struct RootView: View {
    @ObservedObject private var viewModel: RootViewModel

    private let logger = Logger(
        subsystem: "com.leonwoermke.postcard",
        category: "Presentation.RootView"
    )

    public init(viewModel: RootViewModel) {
        self.viewModel = viewModel
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
            }
        }
        .task {
            logger.debug(
                "RootView task entered. currentState=\(String(describing: viewModel.startupState), privacy: .public)"
            )
            await viewModel.start()
        }
    }
}
