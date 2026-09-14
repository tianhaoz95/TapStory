import SwiftUI

struct RecordMusicStepView: View {
    @Binding var path: NavigationPath

    @State private var title = ""
    @State private var symbol = "music.note"
    @State private var loop = true
    @State private var recordingID: String?

    var body: some View {
        Form {
            Section("Song / Sound") {
                TextField("e.g. Goodnight Lullaby", text: $title)
                Toggle("Repeat until a new tag is tapped", isOn: $loop)
            }

            Section("Picture") {
                SymbolPicker(selection: $symbol)
            }

            Section("Recording") {
                AudioRecorderControl(recordingID: recordingID) { id in
                    recordingID = id
                }
                Text("Sing, hum, or play an instrument -- whatever this tag should trigger.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Continue") {
                    guard let recordingID, !title.isEmpty else { return }
                    let payload = MusicPayload(
                        title: title,
                        symbol: symbol,
                        audio: MediaRef(source: .recording, ref: recordingID),
                        loop: loop
                    )
                    guard let jsonPayload = try? JSONValue.from(payload) else { return }
                    let record = ContentRecord(type: MusicActor.typeIdentifier, payload: jsonPayload)
                    path.append(CreateTagRoute.writeTag(record: record, title: title))
                }
                .disabled(title.isEmpty || recordingID == nil)
            }
        }
        .navigationTitle("New Song")
    }
}
