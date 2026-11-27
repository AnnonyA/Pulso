import XCTest

final class PulsoUITests: XCTestCase {
    @MainActor
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-pulso-ui-testing", "-pulso-skip-onboarding"]
        app.launch()
        XCTAssertTrue(app.staticTexts["reader.mode.title"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor
    private func assertSelected(_ mode: String, title: String, in app: XCUIApplication) {
        let selected = app.buttons["mode.\(mode)"]
        let predicate = NSPredicate(format: "value == %@", "Seleccionado")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: selected)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
        XCTAssertEqual(app.staticTexts["reader.mode.title"].label, title)
        for otherMode in ["balance", "trips", "topUp"] where otherMode != mode {
            XCTAssertEqual(app.buttons["mode.\(otherMode)"].value as? String, "No seleccionado")
        }
        XCTAssertTrue(app.buttons["reader.scan"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "reader.unavailable.note").firstMatch.exists)
    }

    @MainActor
    private func assertPrimaryContentVisible(in app: XCUIApplication) {
        let screen = app.windows.firstMatch.frame
        let viewport = app.scrollViews.firstMatch.frame.intersection(screen)
        let scan = app.buttons["reader.scan"]
        let note = app.descendants(matching: .any).matching(identifier: "reader.unavailable.note").firstMatch
        XCTAssertFalse(viewport.isEmpty)
        XCTAssertTrue(scan.isHittable, "The scan button must be reachable without scrolling at normal text size.")
        for (name, element) in [("Scan button", scan), ("Protected-data explanation", note)] {
            XCTAssertGreaterThan(element.frame.width, 0)
            XCTAssertGreaterThan(element.frame.height, 0)
            XCTAssertTrue(viewport.contains(element.frame), "\(name) should fit entirely in the initial iPhone 11 viewport. Element: \(element.frame); viewport: \(viewport)")
        }
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func test01ModesAndLaunchDefault() {
        let app = launchApp()
        assertSelected("balance", title: "Consultar saldo", in: app)
        let balance = app.buttons["mode.balance"]
        let trips = app.buttons["mode.trips"]
        let topUp = app.buttons["mode.topUp"]
        XCTAssertTrue(balance.isHittable)
        XCTAssertTrue(trips.isHittable)
        XCTAssertTrue(topUp.isHittable)
        XCTAssertLessThan(balance.frame.midX, trips.frame.midX)
        XCTAssertLessThan(trips.frame.midX, topUp.frame.midX)
        assertPrimaryContentVisible(in: app)
        capture("01-consultar-saldo-light")

        trips.tap()
        assertSelected("trips", title: "Historial", in: app)
        assertPrimaryContentVisible(in: app)
        capture("02-historial-light")

        topUp.tap()
        assertSelected("topUp", title: "Acreditar carga", in: app)
        assertPrimaryContentVisible(in: app)
        capture("03-acreditar-carga-light")

        // Exercise the real readingAvailable guard; no fake NFC environment.
        let scan = app.buttons["reader.scan"]
        XCTAssertTrue(scan.isEnabled)
        scan.tap()
        let unavailable = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "El simulador permite recorrer la app, pero no escanear.")
        ).firstMatch
        XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "El chip sí fue detectado")
        ).firstMatch.exists)
        capture("03b-real-nfc-unavailable-simulator")

        // Choosing another operation clears this recoverable error.
        balance.tap()
        assertSelected("balance", title: "Consultar saldo", in: app)
        let cleared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: unavailable)
        XCTAssertEqual(XCTWaiter.wait(for: [cleared], timeout: 5), .completed)
        XCTAssertTrue(app.buttons["reader.scan"].isEnabled)
        topUp.tap()
        assertSelected("topUp", title: "Acreditar carga", in: app)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["reader.mode.title"].waitForExistence(timeout: 15))
        assertSelected("balance", title: "Consultar saldo", in: app)
        capture("04-consultar-saldo-after-relaunch")

        app.buttons["menu.open"].tap()
        XCTAssertTrue(app.buttons["menu.readings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["menu.settings"].exists)
        XCTAssertTrue(app.buttons["menu.help"].exists)
    }

    @MainActor
    func test02DarkAppearance() {
        let app = launchApp()
        assertSelected("balance", title: "Consultar saldo", in: app)
        assertPrimaryContentVisible(in: app)
        capture("05-consultar-saldo-dark")
    }

    @MainActor
    func test03AccessibilityLargeText() {
        let app = launchApp()
        assertSelected("balance", title: "Consultar saldo", in: app)
        XCTAssertTrue(app.buttons["mode.balance"].isHittable)
        capture("06-consultar-saldo-accessibility-large")
        let trips = app.buttons["mode.trips"]
        if !trips.isHittable { app.swipeUp() }
        XCTAssertTrue(trips.isHittable)
        trips.tap()
        assertSelected("trips", title: "Historial", in: app)
        capture("07-historial-accessibility-large")
    }
}
