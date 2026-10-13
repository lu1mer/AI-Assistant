import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    @State private var copied = false

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            if message.role == .assistant {
                HStack(spacing: 7) {
                    Image(systemName: "sparkle").foregroundStyle(Brand.accent)
                    Text("Aster").fontWeight(.semibold)
                    if message.status == .generating {
                        Text("пишет…").foregroundStyle(.secondary)
                        ProgressView().controlSize(.mini)
                    }
                }
                .font(.caption)
                .accessibilityElement(children: .combine)
            }
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .lineSpacing(4)
                    .padding(message.role == .user ? 14 : 0)
                    .foregroundStyle(.primary)
                    .background {
                        if message.role == .user {
                            RoundedRectangle(cornerRadius: 20).fill(Brand.accent.opacity(0.10))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(message.role == .user ? "userMessage" : "assistantMessage")
                    .contextMenu {
                        Button("Копировать", systemImage: "doc.on.doc") { copy() }
                        ShareLink(item: message.content) { Label("Поделиться", systemImage: "square.and.arrow.up") }
                    }
            }
            if message.status == .stopped {
                Text(message.content.isEmpty ? "Ответ остановлен" : "Генерация остановлена")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if message.role == .assistant && message.status != .generating && !message.content.isEmpty {
                HStack(spacing: 16) {
                    Button(action: copy) {
                        Label(copied ? "Скопировано" : "Копировать", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("copyResponseButton")
                    ShareLink(item: message.content) {
                        Image(systemName: "square.and.arrow.up").frame(minWidth: 44, minHeight: 44)
                    }
                        .accessibilityLabel("Поделиться ответом")
                }
                .font(.caption).foregroundStyle(.secondary)
                .buttonStyle(.borderless)
                .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .padding(.leading, message.role == .user ? 36 : 0)
        .padding(.trailing, message.role == .assistant ? 12 : 0)
        .accessibilityElement(children: .contain)
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copied = false }
        }
    }

    private func copy() {
        UIPasteboard.general.string = message.content
        copied = true
    }
}
