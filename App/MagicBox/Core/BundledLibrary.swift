import Foundation

/// Loads the sample content that ships with the app (a handful of stories,
/// vocab cards, and a lullaby) so the "create a tag" flow can offer
/// "pick from library" as an alternative to recording something brand new.
///
/// Every bundled item is a complete `ContentRecord` JSON file under
/// `Resources/BundledContent/<Stories|Vocab|Music>/`. By convention every
/// payload also carries a `"title"` field so listing UI stays generic across
/// actor types -- it never needs to know Story payloads differ from Vocab
/// payloads to show a picker row.
enum BundledLibrary {
    struct Item: Identifiable {
        var id: String { fileName }
        var fileName: String
        var title: String
        var record: ContentRecord
    }

    static func items(forType type: String) -> [Item] {
        let subdirectory: String
        switch type {
        case StoryActor.typeIdentifier: subdirectory = "BundledContent/Stories"
        case VocabActor.typeIdentifier: subdirectory = "BundledContent/Vocab"
        case MusicActor.typeIdentifier: subdirectory = "BundledContent/Music"
        default: subdirectory = "BundledContent/\(type)"
        }

        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: subdirectory) else {
            return []
        }

        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let record = try? ContentRecord.decode(from: data),
                  record.type == type else { return nil }
            let title = record.payload["title"]?.stringValue ?? url.deletingPathExtension().lastPathComponent
            return Item(fileName: url.lastPathComponent, title: title, record: record)
        }
        .sorted { $0.title < $1.title }
    }
}
