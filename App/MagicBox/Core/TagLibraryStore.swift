import Foundation

/// One entry in the parent's local "My Tags" library. This is the actual
/// content behind a tag -- physical tags store only this entry's `id` (as
/// a `TagReference`), never the `record` itself. That means:
/// - A lost or destroyed physical sticker is never a real content loss:
///   just write the same `id` to a new one from "My Tags".
/// - Deleting this entry (or the app, or the phone) orphans every physical
///   tag that pointed at it -- there's nothing left for that id to
///   resolve to. `TagLibraryStore.delete(id:)` callers must make that
///   consequence clear before deleting.
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

    /// Resolves a `TagReference.id` read off a physical tag back to real
    /// content. Returns nil for an orphaned tag -- one whose library entry
    /// was deleted, or one written by a different phone/install.
    func entry(withID id: String) -> TagLibraryEntry? {
        entries.first { $0.id == id }
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
