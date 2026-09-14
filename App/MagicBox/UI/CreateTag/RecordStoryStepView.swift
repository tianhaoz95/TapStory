import SwiftUI

private struct StoryPageDraft: Identifiable {
    let id = UUID()
    var caption: String = ""
    var symbol: String = CuratedSymbols.all[0]
    var audioRef: MediaRef?

    var isComplete: Bool { !caption.isEmpty && audioRef != nil }
}

struct RecordStoryStepView: View {
    @Binding var path: NavigationPath

    @State private var title = ""
    @State private var pages: [StoryPageDraft] = [StoryPageDraft()]

    var body: some View {
        Form {
            Section("Story Title") {
                TextField("e.g. The Magic Monkey", text: $title)
            }

            ForEach($pages) { $page in
                Section("Page \(pageNumber(for: page))") {
                    TextField("What happens on this page?", text: $page.caption, axis: .vertical)
                    SymbolPicker(selection: $page.symbol)
                    AudioSourceInput(mediaRef: $page.audioRef, textPlaceholder: "What should be said on this page?")
                    if pages.count > 1 {
                        Button(role: .destructive) {
                            pages.removeAll { $0.id == page.id }
                        } label: {
                            Label("Remove This Page", systemImage: "trash")
                        }
                    }
                }
            }

            Section {
                Button {
                    pages.append(StoryPageDraft())
                } label: {
                    Label("Add Another Page", systemImage: "plus")
                }
            }

            Section {
                Button("Continue") {
                    finish()
                }
                .disabled(!canContinue)
            }
        }
        .navigationTitle("New Story")
    }

    private var canContinue: Bool {
        !title.isEmpty && !pages.isEmpty && pages.allSatisfy { $0.isComplete }
    }

    private func pageNumber(for page: StoryPageDraft) -> Int {
        (pages.firstIndex(where: { $0.id == page.id }) ?? 0) + 1
    }

    private func finish() {
        let storyPages = pages.compactMap { draft -> StoryPage? in
            guard let audioRef = draft.audioRef else { return nil }
            return StoryPage(caption: draft.caption, symbol: draft.symbol, audio: audioRef)
        }
        guard storyPages.count == pages.count else { return }
        let payload = StoryPayload(title: title, pages: storyPages)
        guard let jsonPayload = try? JSONValue.from(payload) else { return }
        let record = ContentRecord(type: StoryActor.typeIdentifier, payload: jsonPayload)
        path.append(CreateTagRoute.writeTag(record: record, title: title))
    }
}
