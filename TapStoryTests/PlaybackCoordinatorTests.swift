import XCTest
@testable import TapStory

/// `PlaybackCoordinator.shared` is a real singleton with side effects
/// (NFC listening) elsewhere, but `remotePlay(entryID:)` and
/// `finishCurrent()` -- the two entry points the Watch app's commands
/// drive -- are safe to exercise directly. Tests clean up their own
/// library entries afterward.
final class PlaybackCoordinatorTests: XCTestCase {
    func testRemotePlayResolvesAndPresentsALibraryEntry() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "Remote Play Test",
            word: "Test",
            letter: nil,
            symbol: "star.fill",
            audio: MediaRef(source: .speech, ref: "Test.")
        ))
        let record = ContentRecord(type: VocabActor.typeIdentifier, payload: payload)
        let entry = TagLibraryEntry(title: "Remote Play Test", record: record)
        TagLibraryStore.shared.add(entry)
        defer {
            TagLibraryStore.shared.delete(id: entry.id)
            PlaybackCoordinator.shared.finishCurrent()
        }

        let exp = expectation(description: "currentRecord updates")
        PlaybackCoordinator.shared.remotePlay(entryID: entry.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(PlaybackCoordinator.shared.currentRecord, record)
            XCTAssertEqual(PlaybackCoordinator.shared.nowPlayingTitle, "Remote Play Test")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testRemotePlayWithUnknownIDDoesNothing() {
        PlaybackCoordinator.shared.finishCurrent()
        PlaybackCoordinator.shared.remotePlay(entryID: UUID().uuidString)
        XCTAssertNil(PlaybackCoordinator.shared.currentRecord)
    }

    func testFinishCurrentClearsNowPlaying() throws {
        let payload = try JSONValue.from(MusicPayload(
            title: "Test Song",
            symbol: "music.note",
            audio: MediaRef(source: .bundled, ref: "lullaby_01"),
            loop: false
        ))
        let record = ContentRecord(type: MusicActor.typeIdentifier, payload: payload)
        let entry = TagLibraryEntry(title: "Test Song", record: record)
        TagLibraryStore.shared.add(entry)
        defer { TagLibraryStore.shared.delete(id: entry.id) }

        let exp = expectation(description: "currentRecord updates then clears")
        PlaybackCoordinator.shared.remotePlay(entryID: entry.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNotNil(PlaybackCoordinator.shared.currentRecord)
            PlaybackCoordinator.shared.finishCurrent()
            XCTAssertNil(PlaybackCoordinator.shared.currentRecord)
            XCTAssertNil(PlaybackCoordinator.shared.nowPlayingTitle)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testPlaybackPausesAndResumesNFCListening() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "Pause Resume Test",
            word: "Pause",
            letter: nil,
            symbol: "pause.fill",
            audio: MediaRef(source: .speech, ref: "Pause.")
        ))
        let record = ContentRecord(type: VocabActor.typeIdentifier, payload: payload)
        let entry = TagLibraryEntry(title: "Pause Resume Test", record: record)
        TagLibraryStore.shared.add(entry)
        defer {
            TagLibraryStore.shared.delete(id: entry.id)
            PlaybackCoordinator.shared.stopListening()
        }

        // Start listening while idle
        PlaybackCoordinator.shared.startListening()
        XCTAssertTrue(PlaybackCoordinator.shared.isListeningRequested)
        XCTAssertTrue(NFCReaderService.shared.isListening)

        // Present content -> NFC listening should pause immediately
        let expPlay = expectation(description: "Playback starts and pauses NFC")
        PlaybackCoordinator.shared.remotePlay(entryID: entry.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNotNil(PlaybackCoordinator.shared.currentRecord)
            XCTAssertFalse(NFCReaderService.shared.isListening)
            expPlay.fulfill()
        }
        wait(for: [expPlay], timeout: 1)

        // Finish content -> NFC listening should resume
        PlaybackCoordinator.shared.finishCurrent()
        XCTAssertNil(PlaybackCoordinator.shared.currentRecord)
        XCTAssertTrue(PlaybackCoordinator.shared.isListeningRequested)
        XCTAssertTrue(NFCReaderService.shared.isListening)

        // Stop listening -> NFC listening should stop completely
        PlaybackCoordinator.shared.stopListening()
        XCTAssertFalse(PlaybackCoordinator.shared.isListeningRequested)
        XCTAssertFalse(NFCReaderService.shared.isListening)
    }
}
