import SwiftUI

struct RecordVocabStepView: View {
    @Binding var path: NavigationPath

    @State private var word = ""
    @State private var letter = ""
    @State private var symbol = CuratedSymbols.all[0]
    @State private var audioRef: MediaRef?

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
                AudioSourceInput(mediaRef: $audioRef, textPlaceholder: "e.g. M! M is for Monkey.")
            }

            Section {
                Button("Continue") {
                    guard let audioRef, !word.isEmpty else { return }
                    let payload = VocabPayload(
                        title: displayTitle,
                        word: word,
                        letter: letter.isEmpty ? nil : letter,
                        symbol: symbol,
                        audio: audioRef
                    )
                    guard let jsonPayload = try? JSONValue.from(payload) else { return }
                    let record = ContentRecord(type: VocabActor.typeIdentifier, payload: jsonPayload)
                    path.append(CreateTagRoute.writeTag(record: record, title: displayTitle))
                }
                .disabled(word.isEmpty || audioRef == nil)
            }
        }
        .navigationTitle("New Vocab Card")
    }

    private var displayTitle: String {
        letter.isEmpty ? word : "\(letter) is for \(word)"
    }
}
