import Foundation
import OSLog

public struct MessageImportResult: Sendable {
    public let importedCount: Int
    public let skippedCount: Int
    public let failedCount: Int

    public init(
        importedCount: Int,
        skippedCount: Int,
        failedCount: Int
    ) {
        self.importedCount = importedCount
        self.skippedCount = skippedCount
        self.failedCount = failedCount
    }
}

public final class MessageImportUseCase {
    private static let logger = Logger(
        subsystem: "com.postcard.app",
        category: "MessageImportUseCase"
    )

    private let connectorRegistry: ConnectorRegistry
    private let contentPreserver: OriginalContentPreserving
    private let canonicalBuilder: CanonicalMessageBuilder

    private let messageRepository: any MessageRepository
    private let attachmentRepository: any AttachmentRepository

    private let maxConcurrency: Int
    private let batchSize: Int

    public init(
        connectorRegistry: ConnectorRegistry,
        contentPreserver: OriginalContentPreserving,
        canonicalBuilder: CanonicalMessageBuilder,
        messageRepository: any MessageRepository,
        attachmentRepository: any AttachmentRepository,
        maxConcurrency: Int = 4,
        batchSize: Int = 50
    ) {
        self.connectorRegistry = connectorRegistry
        self.contentPreserver = contentPreserver
        self.canonicalBuilder = canonicalBuilder
        self.messageRepository = messageRepository
        self.attachmentRepository = attachmentRepository
        self.maxConcurrency = max(1, maxConcurrency)
        self.batchSize = max(1, batchSize)
    }

    public func execute() async -> MessageImportResult {
        Self.logger.info("execute entered")

        var imported = 0
        var skipped = 0
        var failed = 0

        let connectors = self.connectorRegistry.allConnectors()

        for connector in connectors {
            let connectorID = connector.id

            Self.logger.info(
                "processing connector. connectorID=\(connectorID.rawValue, privacy: .public)"
            )

            var cursor: ConnectorSyncCursor? = nil
            var hasMore = true

            while hasMore {
                do {
                    let batch = try await connector.fetchInboundBatch(
                        after: cursor,
                        limit: self.batchSize
                    )

                    Self.logger.info(
                        "batch fetched. connectorID=\(connectorID.rawValue, privacy: .public) batchSize=\(batch.messages.count, privacy: .public)"
                    )

                    let result = await self.processBatch(
                        batch: batch.messages,
                        connectorID: connectorID
                    )

                    imported += result.imported
                    skipped += result.skipped
                    failed += result.failed

                    cursor = batch.nextCursor
                    hasMore = batch.hasMoreAvailable
                } catch {
                    Self.logger.error(
                        "batch fetch failed. connectorID=\(connectorID.rawValue, privacy: .public) error=\(String(describing: error), privacy: .public)"
                    )
                    break
                }
            }
        }

        Self.logger.info(
            "execute completed. imported=\(imported, privacy: .public) skipped=\(skipped, privacy: .public) failed=\(failed, privacy: .public)"
        )

        return MessageImportResult(
            importedCount: imported,
            skippedCount: skipped,
            failedCount: failed
        )
    }

    private func processBatch(
        batch: [ConnectorInboundMessage],
        connectorID: ConnectorID
    ) async -> (imported: Int, skipped: Int, failed: Int) {

        var imported = 0
        var skipped = 0
        var failed = 0

        await withTaskGroup(of: ResultType.self) { group in
            var iterator = batch.makeIterator()
            var active = 0

            func scheduleNext() {
                guard active < self.maxConcurrency,
                      let message = iterator.next() else {
                    return
                }

                active += 1

                group.addTask {
                    await self.processSingleMessage(
                        message: message,
                        connectorID: connectorID
                    )
                }
            }

            for _ in 0..<self.maxConcurrency {
                scheduleNext()
            }

            while let result = await group.next() {
                active -= 1

                switch result {
                case .imported: imported += 1
                case .skipped: skipped += 1
                case .failed: failed += 1
                }

                scheduleNext()
            }
        }

        return (imported, skipped, failed)
    }

    private enum ResultType {
        case imported
        case skipped
        case failed
    }

    private func processSingleMessage(
        message: ConnectorInboundMessage,
        connectorID: ConnectorID
    ) async -> ResultType {

        Self.logger.debug(
            "process message entered. connectorID=\(connectorID.rawValue, privacy: .public)"
        )

        // NOTE:
        // Translation is intentionally NOT handled here due to associatedtype constraints.
        // This use case assumes messages are already translated before reaching this point.
        // This keeps the file compile-safe without unsafe type erasure.

        let translated: TranslatedMessage

        guard let messageAsTranslated = message as? TranslatedMessage else {
            Self.logger.error(
                "message not translated. connectorID=\(connectorID.rawValue, privacy: .public)"
            )
            return .failed
        }

        translated = messageAsTranslated

        // PRESERVATION
        let preserved: PreservedOriginalContent
        do {
            Self.logger.debug(
                "preservation start. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )

            preserved = try self.contentPreserver.preserve(from: translated)

            Self.logger.debug(
                "preservation end. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )
        } catch {
            Self.logger.error(
                "preservation failed. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )
            return .failed
        }

        // BUILD
        let buildResult: CanonicalBuildResult
        do {
            Self.logger.debug(
                "build start. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )

            buildResult = try self.canonicalBuilder.build(
                from: translated,
                preservedContent: preserved
            )

            Self.logger.debug(
                "build end. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )
        } catch {
            Self.logger.error(
                "build failed. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )
            return .failed
        }

        // PERSISTENCE
        do {
            Self.logger.debug(
                "persistence start. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )

            try await self.attachmentRepository.save(buildResult.attachments)

            try await self.messageRepository.save(buildResult.message)

            Self.logger.debug(
                "persistence end. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )

            return .imported
        } catch {
            Self.logger.error(
                "persistence failed. externalMessageID=\(translated.externalMessageID, privacy: .public)"
            )
            return .failed
        }
    }
}
