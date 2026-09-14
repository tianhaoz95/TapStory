import XCTest
@testable import TapStory

final class ContentRecordTests: XCTestCase {
    func testCompactRoundTrip() throws {
        let payload = try JSONValue.from(VocabPayload(
            title: "M is for Monkey",
            word: "Monkey",
            letter: "M",
            symbol: "pawprint.fill",
            audio: MediaRef(source: .speech, ref: "M! M is for Monkey.")
        ))
        let record = ContentRecord(type: VocabActor.typeIdentifier, payload: payload)
        let data = try record.compactData
        let decoded = try ContentRecord.decode(from: data)
        XCTAssertEqual(decoded, record)
    }
}
