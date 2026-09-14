import XCTest
import CoreNFC
@testable import TapStory

/// `TagReference` -- not `ContentRecord` -- is what actually gets written
/// to a physical tag: just an id pointing back into `TagLibraryStore`.
/// These tests replace the old capacity tests that checked whether a full
/// story/vocab `ContentRecord` fit an NTAG213/215/216 -- that question no
/// longer applies to tag writes at all, since a `TagReference` is tiny
/// (a UUID string) no matter how large or complex the content behind it is.
final class TagReferenceTests: XCTestCase {
    func testCompactRoundTrip() throws {
        let reference = TagReference(id: UUID().uuidString)
        let data = try reference.compactData
        let decoded = try TagReference.decode(from: data)
        XCTAssertEqual(decoded, reference)
    }

    func testNDEFPayloadRoundTrip() throws {
        let reference = TagReference(id: UUID().uuidString)
        let ndef = try reference.makeNDEFPayload()
        let decoded = TagReference.from(ndefPayload: ndef)
        XCTAssertEqual(decoded, reference)
    }

    func testUnrelatedNDEFPayloadIsIgnored() throws {
        let unrelated = NFCNDEFPayload(
            format: .media,
            type: Data("text/plain".utf8),
            identifier: Data(),
            payload: Data("hello".utf8)
        )
        XCTAssertNil(TagReference.from(ndefPayload: unrelated))
    }

    func testReferenceComfortablyFitsEvenAnNTAG213() throws {
        // A UUID string plus the tiny JSON envelope is nowhere close to an
        // NTAG213's ~144-byte usable capacity -- this is the whole point
        // of writing only a reference to the tag instead of real content.
        let reference = TagReference(id: UUID().uuidString)
        let data = try reference.compactData
        XCTAssertLessThan(data.count, 80)
    }
}
