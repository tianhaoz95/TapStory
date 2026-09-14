import SwiftUI

struct SettingsView: View {
    @ObservedObject private var library = TagLibraryStore.shared
    @State private var isResetConfirmationPresented = false

    var body: some View {
        List {
            Section("About") {
                LabeledContent("Version", value: Bundle.main.appVersionString)
                Text("Magic Box keeps everything on this device: no accounts, no internet connection required, no analytics. Stories, recordings, and your tag library live only in this phone's storage.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Data") {
                LabeledContent("Tags in library", value: "\(library.entries.count)")
                Button(role: .destructive) {
                    isResetConfirmationPresented = true
                } label: {
                    Text("Erase All My Tags & Recordings")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Erase everything?", isPresented: $isResetConfirmationPresented) {
            Button("Erase", role: .destructive) { eraseEverything() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes every entry in your library and every custom recording. Every physical tag you've written will stop working, since tags only store a reference back to this library, not the content itself.")
        }
    }

    private func eraseEverything() {
        for entry in library.entries {
            library.delete(id: entry.id)
        }
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }
}
