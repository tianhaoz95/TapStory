import SwiftUI

struct TagLibraryListView: View {
    @ObservedObject private var library = TagLibraryStore.shared
    @State private var entryPendingWrite: TagLibraryEntry?
    @State private var entryPendingDelete: TagLibraryEntry?

    var body: some View {
        Group {
            if library.entries.isEmpty {
                ContentUnavailableCompat(
                    title: "No tags yet",
                    message: "Create a story, vocab card, or song and write it to a tag to see it here."
                )
            } else {
                List {
                    ForEach(library.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: ActorRegistry.shared.actor(for: entry.type)?.self.iconName ?? "questionmark")
                                Text(entry.title).font(.headline)
                            }
                            Text(subtitle(for: entry))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                entryPendingDelete = entry
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { entryPendingWrite = entry }
                    }
                }
            }
        }
        .navigationTitle("My Tags")
        .sheet(item: $entryPendingWrite) { entry in
            WriteTagStepView(record: entry.record, title: entry.title, libraryEntryID: entry.id)
        }
        .alert(item: $entryPendingDelete) { entry in
            Alert(
                title: Text("Delete \"\(entry.title)\"?"),
                message: Text("This removes it from your library. It won't erase any physical tags already written."),
                primaryButton: .destructive(Text("Delete")) {
                    library.delete(id: entry.id)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func subtitle(for entry: TagLibraryEntry) -> String {
        let typeLabel = ActorRegistry.shared.actor(for: entry.type).map { type(of: $0).displayName } ?? entry.type
        if let lastWritten = entry.lastWrittenAt {
            return "\(typeLabel) - last written \(lastWritten.formatted(date: .abbreviated, time: .shortened))"
        }
        return "\(typeLabel) - not written to a tag yet"
    }
}

private extension ContentActor {
    var iconName: String { Self.iconSystemName }
}

/// Minimal `ContentUnavailableView` stand-in so the app can target iOS 16
/// (the real thing is iOS 17+).
private struct ContentUnavailableCompat: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
