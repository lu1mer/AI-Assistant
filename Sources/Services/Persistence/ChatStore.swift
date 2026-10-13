import Foundation
import Observation

@MainActor @Observable
final class ChatStore {
    private(set) var conversations: [Conversation] = []
    var storageError: String?
    private let repository: any ConversationRepository

    init(repository: any ConversationRepository) throws {
        self.repository = repository
        conversations = try repository.load()
        // A process kill can leave a checkpoint marked as generating.
        for index in conversations.indices {
            let original = conversations[index]
            conversations[index].recoverInterruptedResponse()
            if conversations[index] != original { try repository.save(conversations[index]) }
        }
    }

    func create() -> Conversation? {
        let conversation = Conversation()
        return save(conversation) ? conversation : nil
    }

    @discardableResult
    func save(_ conversation: Conversation) -> Bool {
        do {
            try repository.save(conversation)
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index] = conversation
            } else {
                conversations.append(conversation)
            }
            conversations.sort { $0.updatedAt > $1.updatedAt }
            storageError = nil
            return true
        } catch {
            storageError = "Не удалось сохранить историю. Проверьте свободное место и повторите сохранение."
            return false
        }
    }

    func delete(_ id: UUID) {
        do {
            try repository.delete(id: id)
            conversations.removeAll { $0.id == id }
            storageError = nil
        } catch {
            storageError = "Не удалось удалить чат. Попробуйте ещё раз."
        }
    }
}
