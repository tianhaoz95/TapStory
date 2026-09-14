import XCTest
@testable import MagicBox

/// `TagLibraryStore.shared` is a real persisted singleton (it's what
/// backs "My Tags" and, now, what every physical tag's `TagReference`
/// resolves against) -- these tests add and then remove their own
/// entries so they don't leave stray data behind in the shared store.
final class TagLibraryStoreTests: XCTestCase {
    func testEntryIsFindableByIDAfterAdding() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "Test Word",
            word: "Test",
            letter: nil,
            symbol: "star.fill",
            audio: MediaRef(source: .speech, ref: "Test.")
        ))
        let record = ContentRecord(type: VocabActor.typeIdentifier, payload: payload)
        let entry = TagLibraryEntry(title: "Test Word", record: record)

        TagLibraryStore.shared.add(entry)
        defer { TagLibraryStore.shared.delete(id: entry.id) }

        let found = TagLibraryStore.shared.entry(withID: entry.id)
        XCTAssertEqual(found?.id, entry.id)
        XCTAssertEqual(found?.record, record)
    }

    func testUnknownIDResolvesToNil() {
        XCTAssertNil(TagLibraryStore.shared.entry(withID: UUID().uuidString))
    }

    func testDeletedEntryNoLongerResolves() throws {
        let payload = try JSONValue.from(MusicPayload(
            title: "Test Song",
            symbol: "music.note",
            audio: MediaRef(source: .bundled, ref: "lullaby_01"),
            loop: false
        ))
        let record = ContentRecord(type: MusicActor.typeIdentifier, payload: payload)
        let entry = TagLibraryEntry(title: "Test Song", record: record)

        TagLibraryStore.shared.add(entry)
        XCTAssertNotNil(TagLibraryStore.shared.entry(withID: entry.id))

        // This is exactly the real-world consequence documented on
        // TagLibraryEntry/TagLibraryStore: deleting an entry orphans any
        // physical tag whose TagReference.id pointed at it.
        TagLibraryStore.shared.delete(id: entry.id)
        XCTAssertNil(TagLibraryStore.shared.entry(withID: entry.id))
    }
}
