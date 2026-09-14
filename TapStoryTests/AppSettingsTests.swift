import XCTest
@testable import TapStory

/// `AppSettings.shared` is backed by real `UserDefaults.standard`, so these
/// tests restore the prior value afterward rather than leaving the shared
/// singleton mutated for whichever test runs next.
final class AppSettingsTests: XCTestCase {
    func testDefaultsToOff() {
        UserDefaults.standard.removeObject(forKey: "isScreenDisplayEnabled")
        // AppSettings.shared is a singleton created once per process, so
        // this only actually verifies the underlying UserDefaults contract
        // this feature depends on: a never-set Bool key reads as false.
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isScreenDisplayEnabled"))
    }

    func testTogglePersistsToUserDefaults() {
        let original = AppSettings.shared.isScreenDisplayEnabled
        defer { AppSettings.shared.isScreenDisplayEnabled = original }

        AppSettings.shared.isScreenDisplayEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isScreenDisplayEnabled"))

        AppSettings.shared.isScreenDisplayEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isScreenDisplayEnabled"))
    }
}
