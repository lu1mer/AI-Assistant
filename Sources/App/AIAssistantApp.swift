import SwiftUI

@main
struct AIAssistantApp: App {
    var body: some Scene {
        WindowGroup { AppRootView().tint(Brand.accent) }
    }
}

private struct AppRootView: View {
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system.rawValue
    @State private var store: ChatStore?
    @State private var failed = false
    @State private var service: any AIService = OpenRouterAIService(apiKey: EmbeddedCredential.value)

    var body: some View {
        Group {
            if let store {
                ChatListView(store: store, service: service)
            } else if failed {
                ContentUnavailableView {
                    Label("История недоступна", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Не удалось открыть хранилище. Ваши данные не удалены. Проверьте свободное место и повторите попытку.")
                } actions: {
                    Button("Повторить") { load() }.buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView("Открываем разговоры…")
            }
        }
        .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
        .task { if store == nil { load() } }
    }

    private func load() {
        do {
            let repository: SwiftDataConversationRepository
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                let url = URL.applicationSupportDirectory.appending(path: "ui-testing.store")
                repository = try SwiftDataConversationRepository(url: url)
                if ProcessInfo.processInfo.arguments.contains("--reset-history") {
                    for conversation in try repository.load() { try repository.delete(id: conversation.id) }
                }
                if ProcessInfo.processInfo.arguments.contains("--seed-long-history") {
                    var conversation = Conversation()
                    conversation.title = "Длинная история"
                    for index in 1...30 {
                        conversation.messages.append(ChatMessage(role: .user, content: "Вопрос \(index): как лучше организовать день?"))
                        conversation.messages.append(ChatMessage(role: .assistant, content: String(repeating: "Начните с одной важной задачи. Разбейте её на небольшие шаги и оставьте время на отдых.\n\n", count: 8)))
                    }
                    try repository.save(conversation)
                }
                service = UITestAIService()
            } else {
                repository = try SwiftDataConversationRepository()
            }
            #else
            repository = try SwiftDataConversationRepository()
            #endif
            store = try ChatStore(repository: repository)
            failed = false
        } catch { failed = true }
    }
}
