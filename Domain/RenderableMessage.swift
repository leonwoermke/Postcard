import Foundation

public protocol DerivedProjectionInput: Equatable, Hashable, Sendable {}

public struct RenderableMessage: DerivedProjectionInput {
    public struct BlockEntry: Equatable, Hashable, Sendable {
        public let block: Block
        public let interpretation: BlockInterpretation?

        public init(
            block: Block,
            interpretation: BlockInterpretation? = nil
        ) {
            self.block = block
            self.interpretation = interpretation
        }
    }

    public struct EntityEntry: Equatable, Hashable, Sendable {
        public let entity: Entity
        public let interpretation: EntityInterpretation?

        public init(
            entity: Entity,
            interpretation: EntityInterpretation? = nil
        ) {
            self.entity = entity
            self.interpretation = interpretation
        }
    }

    public let message: Message
    public let messageInterpretation: MessageInterpretation?
    public let assignment: Assignment?
    public let blocks: [BlockEntry]
    public let entities: [EntityEntry]

    public init(
        message: Message,
        messageInterpretation: MessageInterpretation? = nil,
        assignment: Assignment? = nil,
        blocks: [BlockEntry],
        entities: [EntityEntry]
    ) {
        self.message = message
        self.messageInterpretation = messageInterpretation
        self.assignment = assignment
        self.blocks = blocks
        self.entities = entities
    }
}
