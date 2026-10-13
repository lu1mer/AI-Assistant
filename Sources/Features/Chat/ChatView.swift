import SwiftUI

struct ChatView: View {
    @State var model: ChatViewModel
    let store: ChatStore
    let onNewChat: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var composerFocused: Bool
    @State private var followsLatest = true
    @State private var nearBottom = true
    @State private var userScrolling = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 26) {
                    if model.conversation.messages.isEmpty {
                        welcome
                    } else {
                        ForEach(model.conversation.messages) { message in
                            MessageRow(message: message)
                        }
                        responseFooter
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(20)
            }
            .defaultScrollAnchor(model.conversation.messages.isEmpty ? .top : .bottom, for: .initialOffset)
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height + geometry.contentInsets.bottom - 80
            } action: { _, value in
                nearBottom = value
                if userScrolling { followsLatest = value }
            }
            .onScrollPhaseChange { _, phase in
                userScrolling = phase == .interacting || phase == .decelerating
                if phase == .idle { followsLatest = nearBottom }
            }
            .onChange(of: model.conversation.messages.last?.content) {
                if followsLatest { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: model.conversation.messages.count) {
                followsLatest = true
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: model.isGenerating) {
                if followsLatest { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: composerFocused) {
                if composerFocused { withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            }
            .overlay(alignment: .bottomTrailing) {
                if !followsLatest && !model.conversation.messages.isEmpty {
                    Button {
                        followsLatest = true
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    } label: {
                        Image(systemName: "arrow.down").padding(12).background(.regularMaterial, in: Circle())
                    }
                    .accessibilityLabel("К последнему сообщению")
                    .accessibilityIdentifier("latestMessageButton")
                    .padding()
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(model.conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onNewChat) { Image(systemName: "square.and.pencil") }
                    .accessibilityLabel("Новый разговор")
                    .accessibilityIdentifier("newChatFromConversation")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово", systemImage: "keyboard.chevron.compact.down") { composerFocused = false }
                    .accessibilityIdentifier("dismissKeyboardButton")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) {
            if scenePhase != .active { model.stop() }
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            AsterMark(size: 60)
            VStack(alignment: .leading, spacing: 8) {
                Text("С чего начнём?").font(.largeTitle.bold())
                Text("Разберём сложное, найдём идею\nили просто поговорим.")
                    .foregroundStyle(.secondary).font(.body)
            }
            VStack(spacing: 10) {
                suggestion("Объясни просто", detail: "Как работают нейросети?", icon: "lightbulb")
                suggestion("Помоги с текстом", detail: "Как написать хорошее резюме?", icon: "pencil.line")
                suggestion("Придумай идею", detail: "Предложи необычные идеи для выходных", icon: "sparkles")
            }
            .padding(.top, 8)
            Text("Ответы создаёт AI. Важные факты лучше проверить.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func suggestion(_ title: String, detail: String, icon: String) -> some View {
        Button {
            model.draft = detail
            composerFocused = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(Brand.accent).frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).foregroundStyle(.primary).font(.subheadline.weight(.medium))
                    Text(detail).foregroundStyle(.secondary).font(.caption)
                }
                Spacer()
                Image(systemName: "arrow.up.left").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Brand.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var responseFooter: some View {
        if let failure = model.lastFailure {
            VStack(alignment: .leading, spacing: 12) {
                Label(failure.localizedDescription, systemImage: "exclamationmark.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
                if model.canRetry { retryButton }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.background, in: RoundedRectangle(cornerRadius: 16))
        } else if model.canRetry {
            retryButton
        }
    }

    private var retryButton: some View {
        Button { model.retry() } label: {
            Label("Повторить", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("retryButton")
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let error = store.storageError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error).font(.caption)
                    Button("Повторить сохранение") { model.saveAgain() }
                }.padding(.horizontal)
            }
            if model.draft.count > 12_000 {
                Text("Сообщение слишком длинное — максимум 12 000 символов.")
                    .font(.caption).foregroundStyle(.red)
            }
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Сообщение…", text: $model.draft, axis: .vertical)
                    .lineLimit(1...(verticalSizeClass == .compact ? 1 : (dynamicTypeSize.isAccessibilitySize ? 2 : 6)))
                    .padding(.vertical, 12)
                    .focused($composerFocused)
                    .accessibilityIdentifier("messageInput")
                if model.isGenerating {
                    Button { model.stop() } label: {
                        Image(systemName: "stop.fill").font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white).frame(width: 44, height: 44)
                            .background(Brand.buttonFill, in: Circle())
                    }
                    .accessibilityLabel("Остановить генерацию")
                    .accessibilityIdentifier("stopButton")
                } else {
                    Button {
                        composerFocused = false
                        model.send()
                    } label: {
                        Image(systemName: "arrow.up").font(.system(size: 20, weight: .bold))
                            .foregroundStyle(model.canSend ? .white : .secondary)
                            .frame(width: 44, height: 44)
                            .background(model.canSend ? Brand.buttonFill : Color(uiColor: .tertiarySystemFill), in: Circle())
                    }
                    .disabled(!model.canSend)
                    .accessibilityLabel("Отправить")
                    .accessibilityIdentifier("sendButton")
                }
            }
            .padding(.leading, 16).padding(.trailing, 6).padding(.vertical, 6)
            .background(Brand.background, in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 16)
            if model.isGenerating && verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize {
                Text("Генерируется ответ · можно остановить")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 10).padding(.bottom, 6)
        .background(.bar)
    }
}
