import Foundation

/// The actual content behind one tag: a `type` string an `ActorRegistry`
/// dispatches on, and an open `payload` that only the matching actor needs
/// to understand. Adding a brand new kind of activity later (a puzzle, a
/// counting game, a "call grandma" voice memo...) never requires changing
/// this struct -- it only requires a new `ContentActor` conformance that
/// registers its own `typeIdentifier` and knows how to decode its own
/// `payload` shape.
///
/// This struct never touches a physical NFC tag directly -- it lives in
/// `TagLibraryEntry` in local storage (`TagLibraryStore`), addressed by a
/// stable id. The tag itself stores only that id, as a `TagReference`. See
/// `TagReference` for why: it keeps physical tag capacity a total
/// non-issue, at the cost of a tag only meaning something on the phone
/// that wrote it.
struct ContentRecord: Codable, Equatable, Hashable {
    /// Schema version for the outer envelope, in case the envelope itself
    /// ever needs to change shape. Actor payload versioning is each actor's
    /// own concern.
    var schemaVersion: Int
    /// Dispatch key. Must match a registered `ContentActor.typeIdentifier`.
    var type: String
    /// Opaque, actor-defined content. See `StoryPayload`, `VocabPayload`,
    /// `MusicPayload` for the built-in shapes.
    var payload: JSONValue

    static let currentSchemaVersion = 1

    init(type: String, payload: JSONValue, schemaVersion: Int = ContentRecord.currentSchemaVersion) {
        self.type = type
        self.payload = payload
        self.schemaVersion = schemaVersion
    }
}

extension ContentRecord {
    /// Compact (non-pretty-printed) UTF-8 JSON. Used for local storage
    /// (`TagLibraryStore`, bundled content files) and identity hashing --
    /// no longer for physical tag capacity, since only a `TagReference` id
    /// is ever written to a tag.
    var compactData: Data {
        get throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [] // no pretty-printing: keep it small
            return try encoder.encode(self)
        }
    }

    static func decode(from data: Data) throws -> ContentRecord {
        try JSONDecoder().decode(ContentRecord.self, from: data)
    }
}
