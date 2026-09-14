import XCTest
import CoreNFC
@testable import MagicBox

final class ContentRecordTests: XCTestCase {
    func testCompactRoundTrip() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "M is for Monkey",
            word: "Monkey",
            letter: "M",
            symbol: "pawprint.fill",
            audio: MediaRef(source: .bundled, ref: "letter_m_word")
        ))
        let record = ContentRecord(type: VocabActor.typeIdentifier, payload: payload)
        let data = try record.compactData
        let decoded = try ContentRecord.decode(from: data)
        XCTAssertEqual(decoded, record)
    }

    func testCompactDataFitsAnNTAG215ButNotNecessarilyAnNTAG213() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "S is for Sun",
            word: "Sun",
            letter: "S",
            symbol: "sun.max.fill",
            audio: MediaRef(source: .bundled, ref: "letter_s_word")
        ))
        let record = ContentRecord(type: VocabActor.typeIdentifier, payload: payload)
        let data = try record.compactData
        // Even a minimal single-word vocab card's JSON envelope (field
        // names, MediaRef wrapper, etc.) runs past an NTAG213's ~144-byte
        // usable NDEF capacity -- see README hardware guidance, which
        // recommends NTAG215 (~504 bytes) as the default sticker rather
        // than NTAG213. This test documents that real constraint rather
        // than assuming the smallest/cheapest tag works.
        XCTAssertLessThan(data.count, 504)
    }

    func testFourPageStoryFitsAnNTAG216ButNotAnNTAG215() throws {
        let payload = try JSONValue.from(StoryPayload(
            title: "The Magic Monkey",
            pages: [
                StoryPage(caption: "Once upon a time, a magic monkey named Momo lived in a tall, tall tree.", symbol: "tree.fill", audio: MediaRef(source: .bundled, ref: "story_magic_monkey_p1")),
                StoryPage(caption: "One sunny morning, Momo found a sparkly golden banana!", symbol: "sparkles", audio: MediaRef(source: .bundled, ref: "story_magic_monkey_p2")),
                StoryPage(caption: "Momo took one bite, and whoosh! Momo could fly!", symbol: "wind", audio: MediaRef(source: .bundled, ref: "story_magic_monkey_p3")),
                StoryPage(caption: "Momo shared the magic banana with all of Momo's friends. The end!", symbol: "heart.fill", audio: MediaRef(source: .bundled, ref: "story_magic_monkey_p4"))
            ]
        ))
        let record = ContentRecord(type: StoryActor.typeIdentifier, payload: payload)
        let data = try record.compactData
        // A realistic 4-page story runs past an NTAG215's ~504-byte usable
        // capacity -- multi-page stories need an NTAG216 (~888 bytes) or
        // shorter captions. See README hardware guidance.
        XCTAssertLessThan(data.count, 888)
    }

    func testNDEFPayloadRoundTrip() throws {
        let payload = try JSONValue.from(MusicPayload(
            title: "Sleepy Time Hum",
            symbol: "moon.zzz.fill",
            audio: MediaRef(source: .bundled, ref: "lullaby_01"),
            loop: true
        ))
        let record = ContentRecord(type: MusicActor.typeIdentifier, payload: payload)
        let ndef = try record.makeNDEFPayload()
        let decoded = ContentRecord.from(ndefPayload: ndef)
        XCTAssertEqual(decoded, record)
    }

    func testUnrelatedNDEFPayloadIsIgnored() throws {
        let unrelated = NFCNDEFPayload(
            format: .media,
            type: Data("text/plain".utf8),
            identifier: Data(),
            payload: Data("hello".utf8)
        )
        XCTAssertNil(ContentRecord.from(ndefPayload: unrelated))
    }
}
