import XCTest
@testable import TapStory

/// These run hosted inside the TapStory.app process (see `TEST_HOST` /
/// `bundle_loader` wiring from the app<->test target dependency), so
/// `Bundle.main` here is genuinely the app bundle -- this is what caught
/// bundled content silently resolving to zero items after Xcode flattened
/// the on-disk Stories/Vocab/Music subfolders during the copy-resources
/// build phase. A green build alone would not have caught that; only
/// something that actually reads back from the built bundle does.
final class BundledLibraryTests: XCTestCase {
    func testStoriesAreDiscoverable() {
        let items = BundledLibrary.items(forType: StoryActor.typeIdentifier)
        XCTAssertEqual(items.count, 5, "expected the 5 bundled sample stories")
    }

    func testVocabCardsAreDiscoverable() {
        let items = BundledLibrary.items(forType: VocabActor.typeIdentifier)
        XCTAssertEqual(items.count, 10, "expected the 10 bundled alphabet vocab cards")
    }

    func testMusicIsDiscoverable() {
        let items = BundledLibrary.items(forType: MusicActor.typeIdentifier)
        XCTAssertEqual(items.count, 1, "expected the 1 bundled lullaby")
    }

    /// A blank `.speech` ref is valid by design (`AudioPlaybackController`
    /// falls back to the page's own caption/word/title so a story page
    /// doesn't pay for the same sentence twice in the tag's NDEF payload)
    /// -- `MediaResolver.resolve` itself doesn't know about that fallback,
    /// so this checks each case appropriately: a non-blank ref must resolve
    /// directly, a blank `.speech` ref must have real fallback text.
    func testEveryBundledItemsAudioIsPlayable() throws {
        for actor in ActorRegistry.shared.allActorTypes {
            let typeID = type(of: actor).typeIdentifier
            for item in BundledLibrary.items(forType: typeID) {
                let checks = try Self.audioChecks(in: item.record.payload)
                XCTAssertFalse(checks.isEmpty, "\(item.title) has no audio to check")
                for check in checks {
                    if check.mediaRef.source == .speech && check.mediaRef.ref.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        XCTAssertNotNil(check.fallbackText, "\(item.title): blank speech ref has no fallback display text to associate it with")
                        XCTAssertFalse(check.fallbackText?.isEmpty ?? true, "\(item.title): blank speech ref's fallback text is empty")
                    } else {
                        XCTAssertNotNil(
                            MediaResolver.resolve(check.mediaRef),
                            "\(item.title): bundled audio '\(check.mediaRef.ref)' (source: \(check.mediaRef.source.rawValue)) did not resolve"
                        )
                    }
                }
            }
        }
    }

    private struct AudioCheck {
        var mediaRef: MediaRef
        /// The page's caption / the card's word / the song's title -- what
        /// `AudioPlaybackController` would fall back to for a blank speech ref.
        var fallbackText: String?
    }

    /// Walks a payload looking for every embedded `MediaRef` (a story has
    /// one per page; vocab/music have exactly one), pairing each with its
    /// display text, without needing to know which actor's payload shape it is.
    private static func audioChecks(in payload: JSONValue) throws -> [AudioCheck] {
        if let audioValue = payload["audio"], let ref = try? audioValue.decode(as: MediaRef.self) {
            let fallback = payload["word"]?.stringValue ?? payload["title"]?.stringValue
            return [AudioCheck(mediaRef: ref, fallbackText: fallback)]
        }
        if let pages = payload["pages"]?.arrayValue {
            return try pages.compactMap { page in
                guard let audioValue = page["audio"], let ref = try? audioValue.decode(as: MediaRef.self) else { return nil }
                return AudioCheck(mediaRef: ref, fallbackText: page["caption"]?.stringValue)
            }
        }
        return []
    }
}
