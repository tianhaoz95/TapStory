import SwiftUI

struct VocabActor: ContentActor {
    static let typeIdentifier = "vocab_card"
    static let displayName = "Vocabulary Card"
    static let iconSystemName = "textformat.abc"

    func canHandle(_ record: ContentRecord) -> Bool {
        record.type == Self.typeIdentifier && (try? record.payload.decode(as: VocabPayload.self)) != nil
    }

    func makeChildView(for record: ContentRecord, onFinished: @escaping () -> Void) -> AnyView {
        guard let payload = try? record.payload.decode(as: VocabPayload.self) else {
            return AnyView(PlaybackErrorView(onFinished: onFinished))
        }
        return AnyView(VocabCardView(payload: payload, onFinished: onFinished))
    }
}
