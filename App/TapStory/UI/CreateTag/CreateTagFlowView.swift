import SwiftUI

/// Root of the parent-facing "create a new magic tag" flow: choose an
/// activity type -> choose bundled vs. record-your-own -> (record) ->
/// write to a physical tag. Presented full-screen from the dashboard.
struct CreateTagFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ChooseTypeStepView { type in
                path.append(CreateTagRoute.chooseSource(type: type))
            }
            .navigationTitle("New Magic Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(for: CreateTagRoute.self) { route in
                switch route {
                case .chooseSource(let type):
                    ChooseSourceStepView(contentType: type, path: $path)
                case .bundledPicker(let type):
                    BundledLibraryPickerView(type: type, path: $path)
                case .recordVocab:
                    RecordVocabStepView(path: $path)
                case .recordMusic:
                    RecordMusicStepView(path: $path)
                case .recordStory:
                    RecordStoryStepView(path: $path)
                case .writeTag(let record, let title):
                    WriteTagStepView(record: record, title: title, onDone: { dismiss() })
                }
            }
        }
    }
}
