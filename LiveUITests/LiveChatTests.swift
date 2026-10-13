import XCTest

/// Opt-in LiveAI scheme: uses the real embedded key and consumes free requests.
@MainActor
final class LiveChatTests: XCTestCase {
    func testRealStreamingStopFollowupAndRestart() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["newChatButton"].waitForExistence(timeout: 20))
        app.buttons["newChatButton"].tap()
        let input = app.textFields["messageInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 20))
        let title = "Проверка живого AI"
        input.tap()
        input.typeText(title + ": напиши подробный рассказ о космосе на 1500 слов.")
        app.buttons["sendButton"].tap()
        XCTAssertTrue(app.buttons["stopButton"].waitForExistence(timeout: 10))
        let response = app.staticTexts["assistantMessage"].firstMatch
        XCTAssertTrue(response.waitForExistence(timeout: 90), "Real provider must yield text")
        XCTAssertTrue(app.buttons["stopButton"].exists, "Stop must be exercised during real generation")
        app.buttons["stopButton"].tap()
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Генерация остановлена"].exists)
        let partial = response.label
        XCTAssertFalse(partial.isEmpty)
        // Check that late network chunks cannot mutate the stopped response.
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", partial), object: response)
        changed.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 2), .completed)
        let stopped = XCTAttachment(screenshot: app.screenshot())
        stopped.name = "Real OpenRouter stopped response"; stopped.lifetime = .keepAlways
        add(stopped)
        input.tap()
        input.typeText("Ответь одним словом: привет")
        app.buttons["sendButton"].tap()
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 120))
        XCTAssertFalse(app.buttons["retryButton"].exists, "Follow-up must complete without API error")
        let replies = app.staticTexts.matching(identifier: "assistantMessage")
        XCTAssertEqual(replies.count, 2)
        let completed = replies.element(boundBy: 1).label
        XCTAssertFalse(completed.isEmpty)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Real OpenRouter completed follow-up"; screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
        app.launch()
        let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()
        XCTAssertTrue(input.waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantMessage").count, 2)
        XCTAssertEqual(app.staticTexts.matching(identifier: "assistantMessage").element(boundBy: 1).label, completed)
        XCTAssertTrue(app.buttons["sendButton"].exists)
    }
}
