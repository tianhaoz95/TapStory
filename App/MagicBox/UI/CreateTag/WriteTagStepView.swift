import SwiftUI

/// Final step, reused both from the creation flow (fresh content) and from
/// "My Tags" (re-writing an existing library entry to a replacement
/// sticker). Either way it's the same act: hold a blank/reusable NTAG21x
/// tag to the phone and commit the record to it.
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

            Text(byteSizeCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)

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

    private var byteSizeCaption: String {
        let size = (try? record.compactData.count) ?? 0
        return "\(size) bytes -- fits an NTAG213 or larger sticker."
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
        resultMessage = nil
        isWriting = true
        NFCWriterService.shared.write(record) { result in
            isWriting = false
            switch result {
            case .success:
                isSuccess = true
                resultMessage = "Tag written! Tap it against the phone anytime to play."
                if let entryID { TagLibraryStore.shared.markWritten(id: entryID) }
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
