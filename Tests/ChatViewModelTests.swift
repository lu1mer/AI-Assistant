import XCTest
@testable import AIAssistant

final class ControlledAIService: AIService, @unchecked Sendable {
    private let lock = NSLock()
    private var streams: [AsyncThrowingStream<String, Error>.Continuation] = []
    private var requests: [[AIMessage]] = []
    private var terminations = 0

    func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            lock.withLock { streams.append(continuation); requests.append(messages) }
            continuation.onTermination = { @Sendable [weak self] _ in
                guard let self else { return }
                self.lock.withLock { self.terminations += 1 }
            }
        }
    }
    var count: Int { lock.withLock { streams.count } }
    var terminated: Int { lock.withLock { terminations } }
    func request(_ index: Int) -> [AIMessage] { lock.withLock { requests[index] } }
    func yield(_ text: String, at index: Int = 0) { lock.withLock { streams[index] }.yield(text) }
    func finish(at index: Int = 0, error: Error? = nil) { lock.withLock { streams[index] }.finish(throwing: error) }
}

@MainActor
final class MemoryRepository: ConversationRepository {
    var values: [UUID: Conversation] = [:]
    var shouldFail = false
    func load() throws -> [Conversation] { Array(values.values) }
    func save(_ conversation: Conversation) throws {
        if shouldFail { throw CocoaError(.fileWriteOutOfSpace) }
        values[conversation.id] = conversation
    }
    func delete(id: UUID) throws { values[id] = nil }
}

@MainActor
final class ChatViewModelTests: XCTestCase {
    private func setup() throws -> (ChatViewModel, ControlledAIService, ChatStore, MemoryRepository) {
        let repo = MemoryRepository()
        let store = try ChatStore(repository: repo)
        let service = ControlledAIService()
        return (ChatViewModel(conversation: Conversation(), service: service, store: store), service, store, repo)
    }

    private func eventually(_ condition: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<500 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(4))
        }
        XCTFail("Condition was not reached", file: file, line: line)
    }

    func testStreamingSavedAndFollowupSendsHistory() async throws {
        let (model, service, store, _) = try setup()
        model.draft = "  Привет  "
        model.send()
        try await eventually { service.count == 1 }
        XCTAssertEqual(model.conversation.title, "Привет")
        service.yield("Добрый ")
        try await eventually { model.conversation.messages.last?.content == "Добрый " }
        service.yield("день")
        service.finish()
        try await eventually { !model.isGenerating }
        XCTAssertEqual(store.conversations.first?.messages.last?.content, "Добрый день")
        model.draft = "Продолжи"
        model.send()
        try await eventually { service.count == 2 }
        XCTAssertEqual(service.request(1).map(\.content), ["Привет", "Добрый день", "Продолжи"])
        model.stop()
    }

    func testStopPreservesPartialAndRejectsOldChunks() async throws {
        let (model, service, store, _) = try setup()
        model.draft = "Start"; model.send()
        try await eventually { service.count == 1 }
        service.yield("partial")
        try await eventually { model.conversation.messages.last?.content == "partial" }
        model.stop()
        try await eventually { service.terminated == 1 }
        XCTAssertEqual(store.conversations.first?.messages.last?.status, .stopped)
        model.draft = "next"; model.send()
        try await eventually { service.count == 2 }
        service.yield("stale")
        service.yield("fresh", at: 1); service.finish(at: 1)
        try await eventually { !model.isGenerating }
        XCTAssertEqual(model.conversation.messages.map(\.content), ["Start", "partial", "next", "fresh"])
    }

    func testRetryReplacesPartialWithoutDuplicateUser() async throws {
        let (model, service, _, _) = try setup()
        model.draft = "question"; model.send()
        try await eventually { service.count == 1 }
        service.yield("failed partial"); service.finish(error: AIServiceError.offline)
        try await eventually { model.lastFailure == .offline }
        XCTAssertTrue(model.canRetry)
        model.retry()
        try await eventually { service.count == 2 }
        XCTAssertEqual(service.request(1), [AIMessage(role: .user, content: "question")])
        service.yield("successful", at: 1); service.finish(at: 1)
        try await eventually { !model.isGenerating }
        XCTAssertEqual(model.conversation.messages.map(\.content), ["question", "successful"])
        XCTAssertNil(model.lastFailure)
    }

    func testWhitespaceAndDuplicateSendsPrevented() async throws {
        let (model, service, _, _) = try setup()
        model.draft = " \n "; model.send()
        XCTAssertTrue(model.conversation.messages.isEmpty)
        model.draft = "one"; model.send()
        model.draft = "two"; model.send()
        try await eventually { service.count == 1 }
        XCTAssertEqual(model.conversation.messages.filter { $0.role == .user }.count, 1)
        model.stop()
    }

    func testStorageFailurePreventsNetworkAndCanSaveAgain() async throws {
        let (model, service, store, repo) = try setup()
        repo.shouldFail = true
        model.draft = "unsaved"; model.send()
        XCTAssertEqual(service.count, 0)
        XCTAssertFalse(model.isGenerating)
        XCTAssertNotNil(store.storageError)
        XCTAssertEqual(model.conversation.messages.last?.status, .stopped)
        repo.shouldFail = false
        model.saveAgain()
        XCTAssertNil(store.storageError)
        model.retry()
        try await eventually { service.count == 1 }
        model.stop()
    }

    func testDifferentConversationsStayIndependent() async throws {
        let (first, service, store, _) = try setup()
        let second = ChatViewModel(conversation: Conversation(), service: service, store: store)
        first.draft = "first"; first.send()
        try await eventually { service.count == 1 }
        first.stop()
        second.draft = "second"; second.send()
        try await eventually { service.count == 2 }
        service.yield("second response", at: 1); service.finish(at: 1)
        try await eventually { !second.isGenerating }
        XCTAssertEqual(store.conversations.count, 2)
        XCTAssertEqual(first.conversation.messages.first?.content, "first")
        XCTAssertEqual(second.conversation.messages.last?.content, "second response")
        store.delete(first.conversation.id)
        XCTAssertEqual(store.conversations.map(\.id), [second.conversation.id])
    }
}
