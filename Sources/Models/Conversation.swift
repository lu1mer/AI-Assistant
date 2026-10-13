import Foundation

enum MessageRole: String, Codable, Sendable {
    case user, assistant
}

enum MessageStatus: String, Codable, Sendable {
    case complete, generating, stopped, failed
}

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var role: MessageRole
    var content: String
    var createdAt = Date()
    var status: MessageStatus = .complete
    var failure: AIServiceError?
}

struct Conversation: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var title = "Новый чат"
    var createdAt = Date()
    var updatedAt = Date()
    var messages: [ChatMessage] = []

    var preview: String {
        messages.last(where: { !$0.content.isEmpty })?.content ?? "Начните с вопроса или идеи"
    }

    mutating func recoverInterruptedResponse() {
        for index in messages.indices where messages[index].status == .generating {
            messages[index].status = .stopped
        }
    }
}
