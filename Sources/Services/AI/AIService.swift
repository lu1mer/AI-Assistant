import Foundation

struct AIMessage: Codable, Equatable, Sendable {
    let role: MessageRole
    let content: String
}

protocol AIService: Sendable {
    func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error>
}
