import SwiftUI

/// The entire Watch app: a remote control for the parent, never touched
/// by the toddler holding the phone. No accounts, no settings beyond
/// what's here -- it exists purely to avoid making the parent pick up
/// (and thus add screen time to) the phone itself.
struct ContentView: View {
    @ObservedObject private var connectivity = WatchConnectivityService.shared

    var body: some View {
        NavigationStack {
            List {
                if !connectivity.isReachable {
                    Label("iPhone not nearby", systemImage: "iphone.slash")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }

                Section("Now Playing") {
                    if let title = connectivity.status.nowPlayingTitle {
                        Text(title).font(.headline)
                        Button(role: .destructive) {
                            connectivity.send(.stopPlayback)
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                    } else {
                        Text("Nothing playing").foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { connectivity.status.isScreenDisplayEnabled },
                        set: { connectivity.send(.setScreenDisplayEnabled($0)) }
                    )) {
                        Label("Screen Display", systemImage: "rectangle.on.rectangle")
                    }
                } footer: {
                    Text("Shows the story on the phone screen while it plays. Off by default.")
                }

                if !connectivity.status.library.isEmpty {
                    Section("Play a Saved Tag") {
                        ForEach(connectivity.status.library) { item in
                            Button {
                                connectivity.send(.playLibraryEntry(id: item.id))
                            } label: {
                                Label(item.title, systemImage: item.iconSystemName)
                            }
                        }
                    }
                }
            }
            .navigationTitle("TapStory")
        }
    }
}
