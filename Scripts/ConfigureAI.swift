import Cocoa

@MainActor
final class KeySetup: NSObject, NSApplicationDelegate {
    private let field = NSSecureTextField(frame: NSRect(x: 24, y: 78, width: 452, height: 28))
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 190), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Добавить ключ OpenRouter"
        let label = NSTextField(wrappingLabelWithString: "Вставь API-ключ сюда (⌘V) и нажми «Готово».")
        label.frame = NSRect(x: 24, y: 125, width: 452, height: 40)
        field.placeholderString = "sk-or-v1-…"
        let button = NSButton(title: "Готово", target: self, action: #selector(save))
        button.frame = NSRect(x: 370, y: 24, width: 106, height: 32)
        button.keyEquivalent = "\r"
        window.contentView?.addSubview(label)
        window.contentView?.addSubview(field)
        window.contentView?.addSubview(button)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(field)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func save() {
        let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.hasPrefix("sk-or-v1-"), key.count >= 20, !key.contains(where: { $0.isWhitespace }) else {
            show("Проверь ключ", "Вставь полный API-ключ OpenRouter, начинающийся с sk-or-v1-.")
            return
        }
        let mask = (0..<32).map { _ in UInt8.random(in: 0...255) }
        let bytes = Array(key.utf8).enumerated().map { $0.element ^ mask[$0.offset % mask.count] }
        let source = """
        import Foundation

        /// XOR obfuscation only: a client-bundled key can be recovered. Never log it.
        enum EmbeddedCredential {
            private static let mask: [UInt8] = \(mask)
            private static let bytes: [UInt8] = \(bytes)
            static var value: String {
                guard !mask.isEmpty else { return "" }
                return String(decoding: bytes.enumerated().map { $0.element ^ mask[$0.offset % mask.count] }, as: UTF8.self)
            }
        }

        """
        let project = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("AI-Assistant")
        let destination = project.appendingPathComponent("Sources/Services/AI/EmbeddedCredential.swift")
        do {
            try source.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            // A save panel grants access to this exact file if macOS blocks Documents.
            let panel = NSSavePanel()
            panel.title = "Сохрани ключ в проект"
            panel.message = "Нажми «Сохранить» и подтверди замену файла."
            panel.directoryURL = destination.deletingLastPathComponent()
            panel.nameFieldStringValue = destination.lastPathComponent
            guard panel.runModal() == .OK, let url = panel.url else { return }
            do { try source.write(to: url, atomically: true, encoding: .utf8) }
            catch { show("Не удалось сохранить", "Попробуй ещё раз и выбери EmbeddedCredential.swift в папке проекта Sources/Services/AI."); return }
        }
        field.stringValue = ""
        show("Ключ добавлен", "Готово! Теперь можно собирать приложение.")
        NSApp.terminate(nil)
    }

    private func show(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct ConfigureAI {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = KeySetup()
        application.setActivationPolicy(.regular)
        application.delegate = delegate
        application.run()
        withExtendedLifetime(delegate) {}
    }
}
