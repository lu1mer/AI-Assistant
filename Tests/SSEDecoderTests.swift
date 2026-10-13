import XCTest
@testable import AIAssistant

final class SSEDecoderTests: XCTestCase {
    private func events(_ input: String) throws -> [String] {
        var decoder = SSEDecoder()
        return try input.utf8.compactMap { try decoder.feed($0) }
    }

    func testUTF8SplitBytesCRLFAndComments() throws {
        XCTAssertEqual(try events(": keepalive\r\ndata: Привет 🌍\r\n\r\ndata: [DONE]\r\n\r\n"), ["Привет 🌍", "[DONE]"])
    }

    func testMultilineDataAndUnknownFields() throws {
        XCTAssertEqual(try events("event: message\ndata: one\ndata:two\nid: 3\n\ndata\n\n"), ["one\ntwo", ""])
    }

    func testCRDelimitersAndIncompleteEventNotEmitted() throws {
        XCTAssertEqual(try events("data: first\r\rdata: incomplete"), ["first"])
    }

    func testInvalidUTF8Rejected() {
        var decoder = SSEDecoder()
        XCTAssertNoThrow(try decoder.feed(0xFF))
        XCTAssertThrowsError(try decoder.feed(10))
    }

    func testOversizedLineRejected() throws {
        var decoder = SSEDecoder()
        for _ in 0..<1_048_576 { _ = try decoder.feed(65) }
        XCTAssertThrowsError(try decoder.feed(65))
    }

    func testChunkContentAndMetadata() throws {
        XCTAssertEqual(try CompletionEvent.decode(#"{"choices":[{"delta":{"content":"hello"}}]}"#), .text("hello"))
        XCTAssertEqual(try CompletionEvent.decode(#"{"choices":[{"delta":{"role":"assistant"}}]}"#), .metadata)
        XCTAssertEqual(try CompletionEvent.decode(#"{"choices":[],"usage":{}}"#), .metadata)
        XCTAssertEqual(try CompletionEvent.decode("[DONE]"), .done)
    }

    func testMalformedAndInBandErrors() {
        for value in ["not json", "{}", #"{"choices":[{}]}"#] {
            XCTAssertThrowsError(try CompletionEvent.decode(value)) { XCTAssertEqual($0 as? AIServiceError, .invalidResponse) }
        }
        XCTAssertThrowsError(try CompletionEvent.decode(#"{"error":{"code":"rate_limit_exceeded"}}"#)) {
            XCTAssertEqual($0 as? AIServiceError, .rateLimited)
        }
    }

    func testErrorMapping() {
        XCTAssertEqual(AIServiceError.http(429), .rateLimited)
        XCTAssertEqual(AIServiceError.http(402), .rateLimited)
        XCTAssertEqual(AIServiceError.http(401), .unauthorized)
        XCTAssertEqual(AIServiceError.http(503), .unavailable)
        XCTAssertEqual(AIServiceError.http(413), .contextTooLong)
        XCTAssertEqual(AIServiceError.map(URLError(.notConnectedToInternet)), .offline)
        XCTAssertEqual(AIServiceError.map(URLError(.timedOut)), .timeout)
        XCTAssertEqual(AIServiceError.map(URLError(.networkConnectionLost)), .interrupted)
        XCTAssertFalse(AIServiceError.missingKey.canRetry)
        XCTAssertTrue(AIServiceError.offline.canRetry)
    }
    func testOpenRouterNumericStreamErrorsAndUsageFrame() throws {
        XCTAssertThrowsError(try CompletionEvent.decode(#"{"error":{"code":429,"message":"limit"},"choices":[]}"#)) {
            XCTAssertEqual($0 as? AIServiceError, .rateLimited)
        }
        XCTAssertThrowsError(try CompletionEvent.decode(#"{"error":{"code":401}}"#)) {
            XCTAssertEqual($0 as? AIServiceError, .unauthorized)
        }
        XCTAssertEqual(try CompletionEvent.decode(#"{"choices":[{"delta":{"content":"","role":"assistant"},"finish_reason":"stop"}],"usage":{}}"#), .metadata)
    }

}
