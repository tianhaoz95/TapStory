import SwiftUI

/// Final step, reused both from the creation flow (fresh content) and from
/// "My Tags" (re-writing an existing library entry to a replacement
/// sticker). Either way it's the same act: hold a blank/reusable NTAG21x
/// tag to the phone -- but what actually gets written is just a small
/// `TagReference` id pointing back at this content in `TagLibraryStore`,
/// not the content itself. That's why tag capacity never comes up here:
/// any cheap sticker, even an NTAG213, comfortably fits an id.
struct WriteTagStepView: View {
    let record: ContentRecord
    let title: String
    /// Non-nil when re-writing an existing library entry; nil when this is
    /// brand new content that hasn't been saved to the library yet.
    var libraryEntryID: String?
    var onDone: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var resultMessage: String?
    @State private var isSuccess = false
    @State private var isWriting = false
    @State private var entryID: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: isSuccess ? "checkmark.seal.fill" : "wave.3.right.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(isSuccess ? .green : .accentColor)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Only a small reference is written to the tag -- any NFC sticker works, even the cheapest kind.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let resultMessage {
                Text(resultMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSuccess ? .green : .red)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                write()
            } label: {
                Label(isSuccess ? "Write to Another Tag" : (isWriting ? "Hold Tag Steady..." : "Hold Tag & Write"), systemImage: "wave.3.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWriting)
            .padding(.horizontal, 32)

            if isSuccess {
                Button("Done") {
                    finish()
                }
                .padding(.bottom, 16)
            } else {
                Color.clear.frame(height: 16)
            }
        }
        .navigationTitle("Write Tag")
        .navigationBarBackButtonHidden(isWriting)
        .onAppear(perform: ensureLibraryEntry)
    }

    private func ensureLibraryEntry() {
        guard entryID == nil else { return }
        if let libraryEntryID {
            entryID = libraryEntryID
        } else {
            let entry = TagLibraryEntry(title: title, record: record)
            TagLibraryStore.shared.add(entry)
            entryID = entry.id
        }
    }

    private func write() {
        guard let entryID else { return }
        resultMessage = nil
        isWriting = true
        NFCWriterService.shared.write(TagReference(id: entryID)) { result in
            isWriting = false
            switch result {
            case .success:
                isSuccess = true
                resultMessage = "Tag written! Tap it against the phone anytime to play."
                TagLibraryStore.shared.markWritten(id: entryID)
            case .failure(let message):
                isSuccess = false
                resultMessage = message
            }
        }
    }

    private func finish() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }
}
