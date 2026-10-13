import SwiftUI

struct ChatListView: View {
    let store: ChatStore
    let service: any AIService
    @State private var path: [UUID] = []
    @State private var deletionCandidate: Conversation?
    @State private var search = ""
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var filteredConversations: [Conversation] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.conversations }
        return store.conversations.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.messages.contains { $0.content.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        if store.conversations.isEmpty && !dynamicTypeSize.isAccessibilitySize {
                            HStack(spacing: 12) {
                                AsterMark(size: 44)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Место для ваших идей").font(.headline)
                                    Text("Задайте вопрос или начните с подсказки.")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                        Button(action: createChat) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus").font(.system(size: 18, weight: .semibold))
                                Text("Новый разговор").font(.headline)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 16)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Brand.buttonFill.gradient, in: RoundedRectangle(cornerRadius: 16))
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("newChatButton")
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                Section("Разговоры") {
                    if store.conversations.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Пока чистый лист").font(.headline)
                            Text("Начните разговор — история появится здесь.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.vertical, 16)
                    }
                    if !store.conversations.isEmpty && filteredConversations.isEmpty {
                        ContentUnavailableView.search(text: search)
                            .listRowBackground(Color.clear)
                    }
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(value: conversation.id) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(conversation.title).font(.headline).lineLimit(1)
                                    Spacer(minLength: 8)
                                    Text(conversation.updatedAt, format: .dateTime.day().month(.abbreviated))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                Text(conversation.preview).font(.subheadline)
                                    .foregroundStyle(.secondary).lineLimit(2)
                            }.padding(.vertical, 6)
                        }
                        .accessibilityIdentifier("chat_\(conversation.id)")
                        .swipeActions {
                            Button("Удалить", role: .destructive) { deletionCandidate = conversation }
                        }
                        .contextMenu {
                            Button("Удалить чат", systemImage: "trash", role: .destructive) {
                                deletionCandidate = conversation
                            }
                        }
                    }
                }
                if let error = store.storageError {
                    Section { Text(error).font(.subheadline).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Aster")
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск по разговорам")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Тема", selection: $appearance) {
                            ForEach(Appearance.allCases, id: \.rawValue) { option in
                                Text(option.title).tag(option.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "circle.lefthalf.filled")
                    }
                    .accessibilityLabel("Тема оформления")
                    .accessibilityIdentifier("appearanceMenu")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let conversation = store.conversations.first(where: { $0.id == id }) {
                    ChatView(model: ChatViewModel(conversation: conversation, service: service, store: store), store: store, onNewChat: createChat)
                        .id(id)
                }
            }
            .confirmationDialog("Удалить разговор?", isPresented: Binding(
                get: { deletionCandidate != nil },
                set: { if !$0 { deletionCandidate = nil } }
            ), titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    if let conversation = deletionCandidate { store.delete(conversation.id) }
                    deletionCandidate = nil
                }
                Button("Отмена", role: .cancel) { deletionCandidate = nil }
            } message: {
                Text("История этого разговора будет удалена с устройства.")
            }
        }
    }

    private func createChat() {
        if let conversation = store.create() {
            search = ""
            path = [conversation.id]
        }
    }
}
