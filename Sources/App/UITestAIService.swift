#if DEBUG
import Foundation

/// Deterministic UI-test dependency. Never selected in a normal launch or Release.
actor UITestAIService: AIService {
    private var attempts = 0

    nonisolated func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let attempt = await nextAttempt()
                do {
                    if messages.last?.content == "Ошибка" && attempt == 1 {
                        throw AIServiceError.offline
                    }
                    let chunks = ["Это тестовый ответ. ", "Он приходит частями, ", "а история сохраняется на устройстве. ", "Можно остановить генерацию и продолжить разговор."]
                    for chunk in chunks {
                        try await Task.sleep(for: .milliseconds(messages.last?.content == "Длинный ответ" ? 900 : 180))
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch { continuation.finish(throwing: error) }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    private func nextAttempt() -> Int { attempts += 1; return attempts }
}
#endif
