import XCTest
@testable import AIAssistant

@MainActor
final class PersistenceTests: XCTestCase {
    func testDiskReopenRecoveryOrderingAndDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "test.store")
        var first = Conversation()
        first.messages = [ChatMessage(role: .user, content: "hello"), ChatMessage(role: .assistant, content: "partial", status: .generating)]
        var second = Conversation()
        second.title = "Newer"
        second.updatedAt = first.updatedAt.addingTimeInterval(10)
        try autoreleasepool {
            let writer = try SwiftDataConversationRepository(url: url)
            try writer.save(first)
            try writer.save(second)
        }
        let reader = try SwiftDataConversationRepository(url: url)
        let store = try ChatStore(repository: reader)
        XCTAssertEqual(store.conversations.map(\.id), [second.id, first.id])
        XCTAssertEqual(store.conversations.last?.messages.last?.content, "partial")
        XCTAssertEqual(store.conversations.last?.messages.last?.status, .stopped)
        store.delete(second.id)
        XCTAssertEqual(try reader.load().map(\.id), [first.id])
    }
}
