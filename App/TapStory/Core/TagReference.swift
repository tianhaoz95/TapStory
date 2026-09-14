import Foundation

/// What actually gets written to a physical NFC tag: nothing but a stable
/// id pointing at a `TagLibraryEntry` stored locally on this phone. The
/// real content -- a story's pages, a vocab word's audio, all of it --
/// stays in `TagLibraryStore`; the tag itself is just a pointer.
///
/// This is a deliberate trade: it makes tag capacity a complete non-issue
/// (even the cheapest NTAG213 sticker swallows a UUID without a second
/// thought, no matter how long a story is or how many pages it has), but
/// it means a tag only means something on the phone whose library still
/// has that id. Losing the library entry (or the app, or the phone)
/// orphans every physical tag that pointed at it -- see the README and
/// the warnings in Settings / "My Tags" before deleting anything.
struct TagReference: Codable, Equatable, Hashable {
    var schemaVersion: Int
    var id: String

    static let currentSchemaVersion = 1

    init(id: String, schemaVersion: Int = TagReference.currentSchemaVersion) {
        self.id = id
        self.schemaVersion = schemaVersion
    }
}

extension TagReference {
    var compactData: Data {
        get throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            return try encoder.encode(self)
        }
    }

    static func decode(from data: Data) throws -> TagReference {
        try JSONDecoder().decode(TagReference.self, from: data)
    }
}
