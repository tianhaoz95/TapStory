import Foundation

/// One entry in the parent's local "My Tags" library: the full record that
/// was (or can be) written to a physical tag, plus metadata for the
/// management UI. Keeping the whole `ContentRecord` here -- not just a
/// reference -- means a lost or destroyed physical tag is never a real loss:
/// the parent just re-writes the same record to a new sticker.
struct TagLibraryEntry: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var type: String
    var record: ContentRecord
    var createdAt: Date
    var lastWrittenAt: Date?

    init(title: String, record: ContentRecord) {
        self.id = UUID().uuidString
        self.title = title
        self.type = record.type
        self.record = record
        self.createdAt = Date()
        self.lastWrittenAt = nil
    }
}

/// Simple on-device JSON store for the parent's authored content library.
/// No accounts, no network, no analytics -- everything a family creates
/// stays on that phone.
final class TagLibraryStore: ObservableObject {
    static let shared = TagLibraryStore()

    @Published private(set) var entries: [TagLibraryEntry] = []

    private let fileURL: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("tag_library.json")
        load()
    }

    func add(_ entry: TagLibraryEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func markWritten(id: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].lastWrittenAt = Date()
        save()
    }

    func delete(id: String) {
        entries.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        entries = (try? JSONDecoder().decode([TagLibraryEntry].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
