#if DEBUG
import SwiftUI

/// DEBUG-only affordance for exercising the tap-to-play flow in the iOS
/// Simulator, which has no NFC hardware -- Apple provides no supported way
/// to simulate an NFC scan there, so this lets you pick any bundled story/
/// vocab card/song and have it play exactly as if that tag had been
/// tapped. This entire file is compiled out of Release builds and will
/// never appear in a build handed to a child.
struct DebugSimulateTapButton: View {
    @State private var isMenuPresented = false

    var body: some View {
        Button {
            isMenuPresented = true
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(10)
                .background(Circle().fill(Color.black.opacity(0.35)))
        }
        .padding(16)
        .sheet(isPresented: $isMenuPresented) {
            DebugSimulateTapMenu { record in
                isMenuPresented = false
                PlaybackCoordinator.shared.debugSimulateTap(record)
            }
        }
        .accessibilityLabel("Simulate NFC Tap (Debug Only)")
    }
}

private struct DebugSimulateTapMenu: View {
    let onSelect: (ContentRecord) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ActorRegistry.shared.allActorTypes.indices, id: \.self) { index in
                    let actor = ActorRegistry.shared.allActorTypes[index]
                    let typeID = type(of: actor).typeIdentifier
                    let items = BundledLibrary.items(forType: typeID)
                    if !items.isEmpty {
                        Section(type(of: actor).displayName) {
                            ForEach(items) { item in
                                Button(item.title) {
                                    onSelect(item.record)
                                }
                            }
                        }
                    }
                }
                Section("Also in My Tags") {
                    ForEach(TagLibraryStore.shared.entries) { entry in
                        Button(entry.title) {
                            onSelect(entry.record)
                        }
                    }
                    if TagLibraryStore.shared.entries.isEmpty {
                        Text("Nothing created yet.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Simulate a Tap")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
#endif
