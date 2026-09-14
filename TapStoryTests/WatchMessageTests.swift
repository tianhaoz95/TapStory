import XCTest
@testable import TapStory

/// `WatchMessage.swift` is compiled directly into the `TapStory` target
/// (see project.yml), so these are reachable via the normal `@testable
/// import` -- no separate watchOS test target needed to cover the shared
/// wire protocol's own Codable correctness.
final class WatchMessageTests: XCTestCase {
    func testWatchCommandRoundTrip() throws {
        let commands: [WatchCommand] = [
            .setScreenDisplayEnabled(true),
            .setScreenDisplayEnabled(false),
            .stopPlayback,
            .playLibraryEntry(id: "abc-123")
        ]
        for command in commands {
            let data = try JSONEncoder().encode(command)
            let decoded = try JSONDecoder().decode(WatchCommand.self, from: data)
            XCTAssertEqual(decoded, command)
        }
    }

    func testPhoneStatusRoundTrip() throws {
        let status = PhoneStatus(
            isScreenDisplayEnabled: true,
            nowPlayingTitle: "The Magic Monkey",
            library: [
                PhoneStatus.LibrarySummary(id: "1", title: "The Magic Monkey", iconSystemName: "book.fill"),
                PhoneStatus.LibrarySummary(id: "2", title: "M is for Monkey", iconSystemName: "textformat.abc")
            ]
        )
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(PhoneStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testEmptyStatusHasNoNowPlayingOrLibrary() {
        XCTAssertNil(PhoneStatus.empty.nowPlayingTitle)
        XCTAssertTrue(PhoneStatus.empty.library.isEmpty)
        XCTAssertFalse(PhoneStatus.empty.isScreenDisplayEnabled)
    }
}
