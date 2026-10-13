import Foundation
import SwiftData

@MainActor
protocol ConversationRepository {
    func load() throws -> [Conversation]
    func save(_ conversation: Conversation) throws
    func delete(id: UUID) throws
}

@Model
final class ConversationRecord {
    @Attribute(.unique) var id: UUID
    var updatedAt: Date
    var payload: Data

    init(id: UUID, updatedAt: Date, payload: Data) {
        self.id = id
        self.updatedAt = updatedAt
        self.payload = payload
    }
}

@MainActor
final class SwiftDataConversationRepository: ConversationRepository {
    private let container: ModelContainer
    private let context: ModelContext

    init(url: URL? = nil, inMemory: Bool = false) throws {
        if !inMemory {
            let directory = url?.deletingLastPathComponent() ?? URL.applicationSupportDirectory
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let schema = Schema([ConversationRecord.self])
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        }
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    func load() throws -> [Conversation] {
        try context.fetch(FetchDescriptor<ConversationRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
            .map { try JSONDecoder().decode(Conversation.self, from: $0.payload) }
    }

    func save(_ conversation: Conversation) throws {
        let data = try JSONEncoder().encode(conversation)
        do {
            if let record = try find(conversation.id) {
                record.payload = data
                record.updatedAt = conversation.updatedAt
            } else {
                context.insert(ConversationRecord(id: conversation.id, updatedAt: conversation.updatedAt, payload: data))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(id: UUID) throws {
        do {
            if let record = try find(id) { context.delete(record) }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func find(_ id: UUID) throws -> ConversationRecord? {
        var descriptor = FetchDescriptor<ConversationRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
