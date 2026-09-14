import SwiftUI

/// Second step: bundled sample content, or something the parent records
/// themselves. This is the fork between "quick start" and "turn a specific
/// toy into a magic toy with your own voice."
struct ChooseSourceStepView: View {
    let contentType: String
    @Binding var path: NavigationPath

    var body: some View {
        List {
            Button {
                path.append(CreateTagRoute.bundledPicker(type: contentType))
            } label: {
                Label {
                    VStack(alignment: .leading) {
                        Text("Pick from Library").font(.headline)
                        Text("Ready-made \(actorDisplayName.lowercased()) content").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.grid.2x2.fill")
                }
            }

            Button {
                path.append(recordRoute)
            } label: {
                Label {
                    VStack(alignment: .leading) {
                        Text("Record Your Own").font(.headline)
                        Text("Use your voice for a specific toy or card").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "mic.fill")
                }
            }
        }
        .navigationTitle(actorDisplayName)
    }

    private var actorDisplayName: String {
        ActorRegistry.shared.actor(for: contentType).map { Swift.type(of: $0).displayName } ?? contentType
    }

    private var recordRoute: CreateTagRoute {
        switch contentType {
        case VocabActor.typeIdentifier: return .recordVocab
        case MusicActor.typeIdentifier: return .recordMusic
        default: return .recordStory
        }
    }
}
