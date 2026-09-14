import XCTest
@testable import MagicBox

/// These run hosted inside the MagicBox.app process (see `TEST_HOST` /
/// `bundle_loader` wiring from the app<->test target dependency), so
/// `Bundle.main` here is genuinely the app bundle -- this is what caught
/// bundled content silently resolving to zero items after Xcode flattened
/// the on-disk Stories/Vocab/Music subfolders during the copy-resources
/// build phase. A green build alone would not have caught that; only
/// something that actually reads back from the built bundle does.
final class BundledLibraryTests: XCTestCase {
    func testStoriesAreDiscoverable() {
        let items = BundledLibrary.items(forType: StoryActor.typeIdentifier)
        XCTAssertEqual(items.count, 3, "expected the 3 bundled sample stories")
    }

    func testVocabCardsAreDiscoverable() {
        let items = BundledLibrary.items(forType: VocabActor.typeIdentifier)
        XCTAssertEqual(items.count, 5, "expected the 5 bundled alphabet vocab cards")
    }

    func testMusicIsDiscoverable() {
        let items = BundledLibrary.items(forType: MusicActor.typeIdentifier)
        XCTAssertEqual(items.count, 1, "expected the 1 bundled lullaby")
    }

    func testEveryBundledItemsAudioActuallyResolves() throws {
        for actor in ActorRegistry.shared.allActorTypes {
            let typeID = type(of: actor).typeIdentifier
            for item in BundledLibrary.items(forType: typeID) {
                let mediaRefs = try Self.audioRefs(in: item.record.payload)
                XCTAssertFalse(mediaRefs.isEmpty, "\(item.title) has no audio references to check")
                for ref in mediaRefs {
                    XCTAssertNotNil(
                        MediaResolver.url(for: ref),
                        "\(item.title): bundled audio '\(ref.ref)' did not resolve to a real file in the bundle"
                    )
                }
            }
        }
    }

    /// Walks a payload looking for every embedded `MediaRef` (a story has
    /// one per page; vocab/music have exactly one), without needing to
    /// know which actor's payload shape it is.
    private static func audioRefs(in payload: JSONValue) throws -> [MediaRef] {
        if let audioValue = payload["audio"], let ref = try? audioValue.decode(as: MediaRef.self) {
            return [ref]
        }
        if let pages = payload["pages"]?.arrayValue {
            return try pages.compactMap { page in
                guard let audioValue = page["audio"] else { return nil }
                return try audioValue.decode(as: MediaRef.self)
            }
        }
        return []
    }
}
