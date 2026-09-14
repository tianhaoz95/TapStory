import XCTest
@testable import MagicBox

final class ActorRegistryTests: XCTestCase {
    func testBuiltInActorsAreRegistered() {
        let registry = ActorRegistry.shared
        XCTAssertNotNil(registry.actor(for: "story"))
        XCTAssertNotNil(registry.actor(for: "vocab_card"))
        XCTAssertNotNil(registry.actor(for: "music"))
        XCTAssertNil(registry.actor(for: "not_a_real_type"))
    }

    func testCanHandleRejectsMismatchedType() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "A is for Apple",
            word: "Apple",
            letter: "A",
            symbol: "applelogo",
            audio: MediaRef(source: .bundled, ref: "letter_a_word")
        ))
        let record = ContentRecord(type: "music", payload: payload) // wrong type on purpose
        let actor = ActorRegistry.shared.actor(for: "music")
        XCTAssertFalse(actor?.canHandle(record) ?? true)
    }

    func testCanHandleAcceptsWellFormedStory() throws {
        let payload = try JSONValue.from(StoryPayload(
            title: "Test Story",
            pages: [StoryPage(caption: "Once upon a time", symbol: "star.fill", audio: MediaRef(source: .bundled, ref: "clip1"))]
        ))
        let record = ContentRecord(type: StoryActor.typeIdentifier, payload: payload)
        let actor = ActorRegistry.shared.actor(for: StoryActor.typeIdentifier)
        XCTAssertTrue(actor?.canHandle(record) ?? false)
    }

    func testCanHandleRejectsStoryWithNoPages() throws {
        let payload = try JSONValue.from(StoryPayload(title: "Empty", pages: []))
        let record = ContentRecord(type: StoryActor.typeIdentifier, payload: payload)
        let actor = ActorRegistry.shared.actor(for: StoryActor.typeIdentifier)
        XCTAssertFalse(actor?.canHandle(record) ?? true)
    }

    func testUnrecognizedTypeGracefullyReturnsNilActor() {
        XCTAssertNil(ActorRegistry.shared.actor(for: "counting_game"))
    }
}
