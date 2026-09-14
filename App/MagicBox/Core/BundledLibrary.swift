import Foundation

/// Loads the sample content that ships with the app (a handful of stories,
/// vocab cards, and a lullaby) so the "create a tag" flow can offer
/// "pick from library" as an alternative to recording something brand new.
///
/// Every bundled item is a complete `ContentRecord` JSON file, authored on
/// disk under `Resources/BundledContent/<Stories|Vocab|Music>/` for our own
/// organization. That subfolder structure does **not** survive into the
/// built app, though: Xcode's "Copy Bundle Resources" build phase flattens
/// grouped (yellow-folder) resources to the bundle's top level regardless
/// of their source subdirectory -- only true blue "folder reference"s
/// preserve structure, and this project's resources aren't wired up as
/// one. So this scans the whole bundle for `.json` files and filters by
/// each record's own `type` field rather than assuming a subdirectory that
/// doesn't actually exist at runtime. By convention every payload also
/// carries a `"title"` field so listing UI stays generic across actor
/// types -- it never needs to know Story payloads differ from Vocab
/// payloads to show a picker row.
enum BundledLibrary {
    struct Item: Identifiable {
        var id: String { fileName }
        var fileName: String
        var title: String
        var record: ContentRecord
    }

    static func items(forType type: String) -> [Item] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
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
