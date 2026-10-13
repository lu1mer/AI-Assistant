import XCTest

@MainActor
final class ChatFlowTests: XCTestCase {
    private func launch(reset: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + (reset ? ["--reset-history"] : [])
        app.launch()
        continueAfterFailure = false
        return app
    }

    private func start(_ app: XCUIApplication) {
        let button = app.buttons["newChatButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: button)
        XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 5), .completed)
        button.tap()
    }

    private func send(_ text: String, app: XCUIApplication) {
        let input = app.textFields["messageInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 15))
        input.tap(); input.typeText(text)
        app.buttons["sendButton"].tap()
    }

    func testSendRestartAndSecondConversation() {
        let app = launch()
        start(app)
        send("Первый разговор", app: app)
        XCTAssertTrue(app.staticTexts["assistantMessage"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Первый разговор"].waitForExistence(timeout: 10))
        app.staticTexts["Первый разговор"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["assistantMessage"].waitForExistence(timeout: 15))
        app.navigationBars.buttons.firstMatch.tap()
        start(app)
        XCTAssertFalse(app.staticTexts["assistantMessage"].exists)
        send("Второй разговор", app: app)
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Первый разговор"].exists)
        XCTAssertTrue(app.staticTexts["Второй разговор"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Conversation list (fixture)"; screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testStopAndRetryOfflineWithoutDuplicatePrompt() {
        let app = launch()
        start(app)
        send("Ошибка", app: app)
        XCTAssertTrue(app.buttons["retryButton"].waitForExistence(timeout: 15))
        app.buttons["retryButton"].tap()
        XCTAssertTrue(app.staticTexts["assistantMessage"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts.matching(identifier: "userMessage").count, 1)
        send("Длинный ответ", app: app)
        XCTAssertTrue(app.buttons["stopButton"].waitForExistence(timeout: 15))
        app.buttons["stopButton"].tap()
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["retryButton"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Stop and keyboard (fixture)"; screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testDeleteConversation() {
        let app = launch()
        start(app)
        send("Удаляемый чат", app: app)
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        app.navigationBars.buttons.firstMatch.tap()
        let row = app.staticTexts["Удаляемый чат"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        row.swipeLeft()
        app.buttons["Удалить"].firstMatch.tap()
        app.buttons["Удалить"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Пока чистый лист"].waitForExistence(timeout: 15))
    }

    func testEmptyAndLongHistory() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-history", "--seed-long-history"]
        app.launch()
        continueAfterFailure = false
        let row = app.staticTexts["Длинная история"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.firstMatch.tap()
        XCTAssertTrue(app.textFields["messageInput"].waitForExistence(timeout: 15))
        app.swipeUp()
        let history = XCTAttachment(screenshot: app.screenshot())
        history.name = "Long history (fixture)"; history.lifetime = .keepAlways
        add(history)
        app.navigationBars.buttons.firstMatch.tap()
        start(app)
        XCTAssertTrue(app.staticTexts["С чего начнём?"].waitForExistence(timeout: 15))
        let empty = XCTAttachment(screenshot: app.screenshot())
        empty.name = "Empty chat"; empty.lifetime = .keepAlways
        add(empty)
    }

    func testLandscapeComposerAndLargeText() {
        let app = launch()
        start(app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        send("Проверка горизонтального экрана", app: app)
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.textFields["messageInput"].isHittable)
        XCTAssertTrue(app.buttons["sendButton"].isHittable)
        Thread.sleep(forTimeInterval: 2) // Allow rotation animation to finish before screenshot.
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Landscape composer"; landscape.lifetime = .keepAlways
        add(landscape)
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 2)
        let portrait = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        portrait.name = "Portrait large text composer"; portrait.lifetime = .keepAlways
        add(portrait)
    }

    func testSearchCopyAndNewChatFromConversation() {
        let app = launch()
        start(app)
        send("План поездки", app: app)
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        let copy = app.buttons["copyResponseButton"].firstMatch
        XCTAssertTrue(copy.waitForExistence(timeout: 15))
        copy.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Скопировано")).firstMatch.waitForExistence(timeout: 5))
        send("Уникальныймаркер", app: app)
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        app.buttons["newChatFromConversation"].tap()
        XCTAssertTrue(app.staticTexts["С чего начнём?"].waitForExistence(timeout: 15))
        send("Другой разговор", app: app)
        XCTAssertTrue(app.buttons["sendButton"].waitForExistence(timeout: 15))
        app.navigationBars.buttons.firstMatch.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        search.tap()
        search.typeText("Уникальныймаркер")
        XCTAssertTrue(app.staticTexts["План поездки"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Другой разговор"].exists)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Search by message content"; screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testAppearanceSelectionAndNewConversationButton() {
        let app = launch()
        XCTAssertTrue(app.buttons["newChatButton"].waitForExistence(timeout: 15))
        let button = app.buttons["newChatButton"]
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        XCTAssertLessThanOrEqual(button.frame.maxX, app.frame.maxX)
        app.buttons["appearanceMenu"].tap()
        app.buttons["Тёмная"].tap()
        Thread.sleep(forTimeInterval: 1)
        let dark = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        dark.name = "Explicit dark appearance"; dark.lifetime = .keepAlways
        add(dark)
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["appearanceMenu"].waitForExistence(timeout: 15))
        let persisted = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        persisted.name = "Dark appearance after restart"; persisted.lifetime = .keepAlways
        add(persisted)
        app.buttons["appearanceMenu"].tap()
        app.buttons["Светлая"].tap()
        Thread.sleep(forTimeInterval: 1)
        let light = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        light.name = "Explicit light appearance"; light.lifetime = .keepAlways
        add(light)
        start(app)
        XCTAssertTrue(app.textFields["messageInput"].waitForExistence(timeout: 15))
    }

}
