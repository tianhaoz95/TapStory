import SwiftUI

struct RecordVocabStepView: View {
    @Binding var path: NavigationPath

    @State private var word = ""
    @State private var letter = ""
    @State private var symbol = CuratedSymbols.all[0]
    @State private var recordingID: String?

    var body: some View {
        Form {
            Section("Word") {
                TextField("e.g. Monkey", text: $word)
                TextField("Letter (optional, e.g. M)", text: $letter)
                    .onChange(of: letter) { newValue in
                        letter = String(newValue.prefix(1)).uppercased()
                    }
            }

            Section("Picture") {
                SymbolPicker(selection: $symbol)
            }

            Section("Pronunciation") {
                AudioRecorderControl(recordingID: recordingID) { id in
                    recordingID = id
                }
                Text("Say the word clearly, e.g. \u{201C}Monkey!\u{201D}")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Continue") {
                    guard let recordingID, !word.isEmpty else { return }
                    let payload = VocabPayload(
                        title: displayTitle,
                        word: word,
                        letter: letter.isEmpty ? nil : letter,
                        symbol: symbol,
                        audio: MediaRef(source: .recording, ref: recordingID)
                    )
                    guard let jsonPayload = try? JSONValue.from(payload) else { return }
                    let record = ContentRecord(type: VocabActor.typeIdentifier, payload: jsonPayload)
                    path.append(CreateTagRoute.writeTag(record: record, title: displayTitle))
                }
                .disabled(word.isEmpty || recordingID == nil)
            }
        }
        .navigationTitle("New Vocab Card")
    }

    private var displayTitle: String {
        letter.isEmpty ? word : "\(letter) is for \(word)"
    }
}
