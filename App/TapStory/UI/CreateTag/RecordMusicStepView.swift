import SwiftUI

struct RecordMusicStepView: View {
    @Binding var path: NavigationPath

    @State private var title = ""
    @State private var symbol = "music.note"
    @State private var loop = true
    @State private var audioRef: MediaRef?

    var body: some View {
        Form {
            Section("Song / Sound") {
                TextField("e.g. Goodnight Lullaby", text: $title)
                Toggle("Repeat until a new tag is tapped", isOn: $loop)
            }

            Section("Picture") {
                SymbolPicker(selection: $symbol)
            }

            Section("Sound") {
                AudioSourceInput(mediaRef: $audioRef, textPlaceholder: "e.g. Time to sleep, sweet dreams...")
                Text("For actual singing/humming, Record Voice usually sounds better than typed text.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Continue") {
                    guard let audioRef, !title.isEmpty else { return }
                    let payload = MusicPayload(
                        title: title,
                        symbol: symbol,
                        audio: audioRef,
                        loop: loop
                    )
                    guard let jsonPayload = try? JSONValue.from(payload) else { return }
                    let record = ContentRecord(type: MusicActor.typeIdentifier, payload: jsonPayload)
                    path.append(CreateTagRoute.writeTag(record: record, title: title))
                }
                .disabled(title.isEmpty || audioRef == nil)
            }
        }
        .navigationTitle("New Song")
    }
}
