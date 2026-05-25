//
//  iTeaUITests.swift
//  iTeaUITests
//
//  Created by Philipp C. Gérard on 24.05.26.
//

import XCTest

final class iTeaUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_appScreenshots() throws {
        let app = XCUIApplication()

        // Forward demo Gitea credentials from the environment into the app
        // as launch arguments. AuthenticationManager picks these up and skips
        // the login screen. fastlane mirrors UITESTING_* env vars into
        // TEST_RUNNER_UITESTING_* so they're visible inside the test runner.
        var args = [String]()
        if let url = ProcessInfo.processInfo.environment["UITESTING_SERVER_URL"], !url.isEmpty {
            args += ["-UITestingServerURL", url]
        }
        if let token = ProcessInfo.processInfo.environment["UITESTING_TOKEN"], !token.isEmpty {
            args += ["-UITestingToken", token]
        }
        app.launchArguments += args

        setupSnapshot(app)
        app.launch()

        // Wait for the repository list to populate. Works on both the iPhone
        // tab-bar layout and the iPad sidebar layout (iOS 18+ TabView).
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30),
                      "Repository list did not appear — auto-login likely failed. Check UITESTING_SERVER_URL / UITESTING_TOKEN.")
        snapshot("01_repositories")

        tapTab("Notifications", in: app)
        _ = app.cells.firstMatch.waitForExistence(timeout: 15)
        snapshot("02_notifications")

        tapTab("Search", in: app)
        snapshot("03_search")

        // Drill into the first repository for a detail-view screenshot.
        tapTab("Repositories", in: app)
        let firstCell = app.cells.firstMatch
        if firstCell.waitForExistence(timeout: 10) {
            firstCell.tap()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 10)
            snapshot("04_repository_detail")
        }
    }

    @MainActor
    private func tapTab(_ label: String, in app: XCUIApplication) {
        // iPhone (any iOS): classic bottom tab bar — one match.
        // iPad on iOS 18+ floating tab bar: each item is wrapped as a nested
        // Button-in-Button, so app.buttons[label] matches twice. .firstMatch
        // resolves to the outer element either way.
        let candidates = [app.tabBars.buttons[label].firstMatch, app.buttons[label].firstMatch]
        for candidate in candidates where candidate.exists {
            candidate.tap()
            return
        }
    }
}
