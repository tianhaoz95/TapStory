import SwiftUI

struct StoryActor: ContentActor {
    static let typeIdentifier = "story"
    static let displayName = "Story"
    static let iconSystemName = "book.fill"

    func canHandle(_ record: ContentRecord) -> Bool {
        guard record.type == Self.typeIdentifier,
              let payload = try? record.payload.decode(as: StoryPayload.self) else { return false }
        return !payload.pages.isEmpty
    }

    func makeChildView(for record: ContentRecord, onFinished: @escaping () -> Void) -> AnyView {
        guard let payload = try? record.payload.decode(as: StoryPayload.self) else {
            return AnyView(PlaybackErrorView(onFinished: onFinished))
        }
        return AnyView(StoryPlayerView(payload: payload, onFinished: onFinished))
    }
}
