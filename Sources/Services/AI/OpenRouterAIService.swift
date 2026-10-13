import Foundation

struct OpenRouterAIService: AIService {
    static let model = "openrouter/free"
    let apiKey: String

    private let makeSession: @Sendable () -> URLSession

    init(apiKey: String, makeSession: @escaping @Sendable () -> URLSession = OpenRouterAIService.defaultSession) {
        self.apiKey = apiKey
        self.makeSession = makeSession
    }

    static func defaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error> {
        let session = makeSession()
        return AsyncThrowingStream { continuation in
            let producer = Task {
                defer { session.invalidateAndCancel() }
                do {
                    guard !apiKey.isEmpty else { throw AIServiceError.missingKey }
                    guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
                        throw AIServiceError.invalidResponse
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.httpBody = try JSONEncoder().encode(Body(model: Self.model, messages: messages))
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
                    guard (200..<300).contains(http.statusCode) else { throw AIServiceError.http(http.statusCode) }
                    guard http.value(forHTTPHeaderField: "Content-Type")?.lowercased().contains("text/event-stream") == true else {
                        throw AIServiceError.invalidResponse
                    }
                    var decoder = SSEDecoder()
                    var receivedText = false
                    for try await byte in bytes {
                        try Task.checkCancellation()
                        guard let payload = try decoder.feed(byte) else { continue }
                        switch try CompletionEvent.decode(payload) {
                        case .text(let text):
                            receivedText = true
                            continuation.yield(text)
                        case .metadata: break
                        case .done:
                            guard receivedText else { throw AIServiceError.invalidResponse }
                            continuation.finish()
                            return
                        }
                    }
                    throw AIServiceError.interrupted
                } catch {
                    if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                        continuation.finish(throwing: CancellationError())
                    } else {
                        continuation.finish(throwing: AIServiceError.map(error))
                    }
                }
            }
            continuation.onTermination = { @Sendable _ in
                producer.cancel()
                // Also tears down an idle socket when the consumer stops between chunks.
                session.invalidateAndCancel()
            }
        }
    }

    private struct Body: Encodable {
        let model: String
        let messages: [AIMessage]
        let stream = true
        let max_tokens = 2048
        let temperature = 0.7
    }
}
