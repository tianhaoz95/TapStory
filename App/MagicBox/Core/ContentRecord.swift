import Foundation

/// The record written to (and read from) every NFC tag, and the record
/// stored in the parent's tag library.
///
/// This is intentionally the entire schema: a `type` string an `ActorRegistry`
/// dispatches on, and an open `payload` that only the matching actor needs to
/// understand. Adding a brand new kind of activity later (a puzzle, a
/// counting game, a "call grandma" voice memo...) never requires changing
/// this struct -- it only requires a new `ContentActor` conformance that
/// registers its own `typeIdentifier` and knows how to decode its own
/// `payload` shape.
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
    /// Compact UTF-8 JSON, sized to comfortably fit an NTAG213 (~144 usable
    /// bytes) for simple records and NTAG215/216 for richer ones (e.g.
    /// multi-page stories). Callers that need to check tag capacity before
    /// writing should measure `compactData.count`.
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
