import Foundation

/// Byte framing preserves blank event delimiters and split UTF-8 code points.
/// URLSession.AsyncBytes.lines is intentionally avoided: SSE needs empty lines.
struct SSEDecoder {
    private var line = Data()
    private var dataLines: [String] = []
    private var eventSize = 0
    private var previousWasCR = false
    private let sizeLimit = 1_048_576

    mutating func feed(_ byte: UInt8) throws -> String? {
        if byte == 10 && previousWasCR {
            previousWasCR = false
            return nil
        }
        previousWasCR = byte == 13
        if byte == 10 || byte == 13 { return try finishLine() }
        line.append(byte)
        guard line.count <= sizeLimit else { throw AIServiceError.invalidResponse }
        return nil
    }

    private mutating func finishLine() throws -> String? {
        guard let text = String(data: line, encoding: .utf8) else { throw AIServiceError.invalidResponse }
        line.removeAll(keepingCapacity: true)
        if text.isEmpty {
            defer { dataLines.removeAll(keepingCapacity: true); eventSize = 0 }
            return dataLines.isEmpty ? nil : dataLines.joined(separator: "\n")
        }
        if text == "data" || text.hasPrefix("data:") {
            var value = text == "data" ? "" : String(text.dropFirst(5))
            if value.first == " " { value.removeFirst() }
            eventSize += value.utf8.count
            guard eventSize <= sizeLimit else { throw AIServiceError.invalidResponse }
            dataLines.append(value)
        }
        // Ignore SSE comments, id, event, retry, and unknown fields.
        return nil
    }
}

enum CompletionEvent: Equatable {
    case text(String), metadata, done

    static func decode(_ payload: String) throws -> Self {
        if payload == "[DONE]" { return .done }
        let chunk: Chunk
        do { chunk = try JSONDecoder().decode(Chunk.self, from: Data(payload.utf8)) }
        catch { throw AIServiceError.invalidResponse }
        if let apiError = chunk.error {
            if apiError.code == "rate_limit_exceeded" { throw AIServiceError.rateLimited }
            if let code = apiError.code.flatMap(Int.init) { throw AIServiceError.http(code) }
            throw AIServiceError.unavailable
        }
        guard let choices = chunk.choices else { throw AIServiceError.invalidResponse }
        if choices.isEmpty { return .metadata } // optional usage-only event
        guard let choice = choices.first, let delta = choice.delta else { throw AIServiceError.invalidResponse }
        if let content = delta.content, !content.isEmpty { return .text(content) }
        return .metadata
    }

    private struct Chunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta?
        }
        struct APIError: Decodable {
            let code: String?
            private enum CodingKeys: String, CodingKey { case code }
            init(from decoder: any Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                if let number = try? values.decode(Int.self, forKey: .code) {
                    code = String(number)
                } else {
                    code = try values.decodeIfPresent(String.self, forKey: .code)
                }
            }
        }
        let choices: [Choice]?
        let error: APIError?
    }
}
