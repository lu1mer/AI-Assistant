import XCTest
@testable import AIAssistant

private final class ProtocolState: @unchecked Sendable {
    struct Response {
        var status = 200
        var contentType = "text/event-stream"
        var body = "data: {\"choices\":[{\"delta\":{\"content\":\"hello\"}}]}\n\ndata: [DONE]\n\n"
        var finish = true
        var error: URLError?
    }
    private let lock = NSLock()
    private var stored = Response()
    private var stops = 0
    func set(_ response: Response) { lock.withLock { stored = response; stops = 0 } }
    func response() -> Response { lock.withLock { stored } }
    func stop() { lock.withLock { stops += 1 } }
    var stopCount: Int { lock.withLock { stops } }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let state = ProtocolState()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let fixture = Self.state.response()
        if let error = fixture.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: fixture.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": fixture.contentType]) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(fixture.body.utf8))
        if fixture.finish { client?.urlProtocolDidFinishLoading(self) }
    }
    override func stopLoading() { Self.state.stop() }
}

final class OpenRouterAIServiceTests: XCTestCase {
    private func service() -> OpenRouterAIService {
        OpenRouterAIService(apiKey: "test-only-non-secret") {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [StubURLProtocol.self]
            return URLSession(configuration: config)
        }
    }

    func testActualClientDecodesStreamingBytes() async throws {
        StubURLProtocol.state.set(.init())
        var answer = ""
        for try await chunk in service().stream(messages: [.init(role: .user, content: "hi")]) { answer += chunk }
        XCTAssertEqual(answer, "hello")
    }

    func testHTTPMalformedTruncatedAndOfflineFailures() async throws {
        let cases: [(ProtocolState.Response, AIServiceError)] = [
            (.init(status: 429), .rateLimited),
            (.init(status: 401), .unauthorized),
            (.init(status: 503), .unavailable),
            (.init(contentType: "application/json"), .invalidResponse),
            (.init(body: "data: nonsense\n\n"), .invalidResponse),
            (.init(body: "data: {\"choices\":[{\"delta\":{\"content\":\"partial\"}}]}\n\n"), .interrupted),
            (.init(error: URLError(.notConnectedToInternet)), .offline),
            (.init(error: URLError(.timedOut)), .timeout)
        ]
        for (fixture, expected) in cases {
            StubURLProtocol.state.set(fixture)
            do {
                for try await _ in service().stream(messages: []) {}
                XCTFail("Expected \(expected)")
            } catch { XCTAssertEqual(error as? AIServiceError, expected) }
        }
    }

    func testConsumerCancellationStopsNetworkTransport() async throws {
        StubURLProtocol.state.set(.init(body: "data: {\"choices\":[{\"delta\":{\"content\":\"partial\"}}]}\n\n", finish: false))
        let received = expectation(description: "received first network chunk")
        let client = service()
        let task = Task {
            do {
                for try await _ in client.stream(messages: []) { received.fulfill() }
            } catch {}
        }
        await fulfillment(of: [received], timeout: 5)
        task.cancel()
        await task.value
        for _ in 0..<100 where StubURLProtocol.state.stopCount == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertGreaterThan(StubURLProtocol.state.stopCount, 0)
    }

    func testMissingCredentialFailsExplicitly() async {
        do {
            for try await _ in OpenRouterAIService(apiKey: "").stream(messages: []) {}
            XCTFail("Missing key must fail")
        } catch { XCTAssertEqual(error as? AIServiceError, .missingKey) }
    }
}
