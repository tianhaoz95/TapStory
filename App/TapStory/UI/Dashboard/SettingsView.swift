import SwiftUI

struct SettingsView: View {
    @ObservedObject private var library = TagLibraryStore.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var isResetConfirmationPresented = false

    var body: some View {
        List {
            Section("About") {
                LabeledContent("Version", value: Bundle.main.appVersionString)
                Text("TapStory keeps everything on this device: no accounts, no internet connection required, no analytics. Stories, recordings, and your tag library live only in this phone's storage.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Show content on screen", isOn: $settings.isScreenDisplayEnabled)
                Text(settings.isScreenDisplayEnabled
                     ? "Tapping a tag shows the story page, word, or song on screen while it plays."
                     : "Off (recommended): tapping a tag plays sound only. The screen stays exactly as it is right now, even while something is playing -- as close to \"not a screen\" as a phone can get.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Screen Display")
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
