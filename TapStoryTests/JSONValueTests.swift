import XCTest
@testable import TapStory

final class JSONValueTests: XCTestCase {
    func testRoundTripThroughObject() throws {
        struct Sample: Codable, Equatable {
            var name: String
            var count: Int
            var active: Bool
        }
        let sample = Sample(name: "Momo", count: 3, active: true)
        let value = try JSONValue.from(sample)
        XCTAssertEqual(value["name"]?.stringValue, "Momo")
        XCTAssertEqual(value["count"]?.doubleValue, 3)
        XCTAssertEqual(value["active"]?.boolValue, true)

        let decoded = try value.decode(as: Sample.self)
        XCTAssertEqual(decoded, sample)
    }

    func testDecodeThroughJSONCoders() throws {
        let json = #"{"title":"Test","pages":[{"caption":"Hi","symbol":"star.fill","audio":{"source":"bundled","ref":"clip"}}]}"#
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        let payload = try value.decode(as: StoryPayload.self)
        XCTAssertEqual(payload.title, "Test")
        XCTAssertEqual(payload.pages.count, 1)
        XCTAssertEqual(payload.pages[0].audio.ref, "clip")
    }

    func testNullAndArray() throws {
        let json = #"{"a":null,"b":[1,2,3]}"#
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        XCTAssertEqual(value["a"], .null)
        XCTAssertEqual(value["b"]?.arrayValue?.count, 3)
    }
}
