import Foundation
import Observation

@MainActor @Observable
final class ChatViewModel {
    private(set) var conversation: Conversation
    var draft = ""
    private(set) var isGenerating = false
    private let service: any AIService
    private let store: ChatStore
    @ObservationIgnored private var generation: Task<Void, Never>?
    @ObservationIgnored private var requestID: UUID?
    @ObservationIgnored private var lastCheckpoint = Date.distantPast

    init(conversation: Conversation, service: any AIService, store: ChatStore) {
        self.conversation = conversation
        self.service = service
        self.store = store
    }

    var canSend: Bool {
        !isGenerating && store.storageError == nil && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.count <= 12_000
    }

    var lastFailure: AIServiceError? { conversation.messages.last?.failure }
    var canRetry: Bool {
        !isGenerating && (lastFailure?.canRetry == true || conversation.messages.last?.status == .stopped)
    }

    func send() {
        guard canSend else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.messages.append(ChatMessage(role: .user, content: text))
        if conversation.messages.count == 1 {
            conversation.title = String(text.split(whereSeparator: \.isWhitespace).joined(separator: " ").prefix(48))
        }
        draft = ""
        beginResponse()
    }

    func retry() {
        guard canRetry, conversation.messages.last?.role == .assistant else { return }
        conversation.messages.removeLast()
        beginResponse()
    }

    func stop() {
        guard isGenerating else { return }
        requestID = nil // Invalidates buffered callbacks before cancellation can resume them.
        generation?.cancel()
        generation = nil
        isGenerating = false
        if let index = conversation.messages.indices.last {
            conversation.messages[index].status = .stopped
        }
        persist()
    }

    func saveAgain() { persist() }

    private func beginResponse() {
        let history = conversation.messages
            .filter { !$0.content.isEmpty && $0.status != .failed }
            .map { AIMessage(role: $0.role, content: $0.content) }
        conversation.messages.append(ChatMessage(role: .assistant, content: "", status: .generating))
        guard persist() else {
            conversation.messages[conversation.messages.count - 1].status = .stopped
            return
        }
        let id = UUID()
        requestID = id
        isGenerating = true
        let service = self.service
        generation = Task { [weak self] in
            do {
                for try await text in service.stream(messages: history) {
                    try Task.checkCancellation()
                    self?.receive(text, request: id)
                }
                self?.finish(request: id)
            } catch {
                if Task.isCancelled || error is CancellationError { return }
                self?.finish(request: id, error: AIServiceError.map(error))
            }
        }
    }

    private func receive(_ text: String, request: UUID) {
        guard requestID == request, let index = conversation.messages.indices.last else { return }
        conversation.messages[index].content += text
        if Date().timeIntervalSince(lastCheckpoint) >= 0.35 {
            if !persist() { stop() }
        }
    }

    private func finish(request: UUID, error: AIServiceError? = nil) {
        guard requestID == request, let index = conversation.messages.indices.last else { return }
        let failure = error ?? (conversation.messages[index].content.isEmpty ? .invalidResponse : nil)
        conversation.messages[index].status = failure == nil ? .complete : .failed
        conversation.messages[index].failure = failure
        requestID = nil
        generation = nil
        isGenerating = false
        persist()
    }

    @discardableResult
    private func persist() -> Bool {
        conversation.updatedAt = Date()
        lastCheckpoint = Date()
        return store.save(conversation)
    }
}
