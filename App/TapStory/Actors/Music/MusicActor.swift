import SwiftUI

struct MusicActor: ContentActor {
    static let typeIdentifier = "music"
    static let displayName = "Music"
    static let iconSystemName = "music.note"

    func canHandle(_ record: ContentRecord) -> Bool {
        record.type == Self.typeIdentifier && (try? record.payload.decode(as: MusicPayload.self)) != nil
    }

    func makeChildView(for record: ContentRecord, onFinished: @escaping () -> Void) -> AnyView {
        guard let payload = try? record.payload.decode(as: MusicPayload.self) else {
            return AnyView(PlaybackErrorView(onFinished: onFinished))
        }
        return AnyView(MusicPlayerView(payload: payload, onFinished: onFinished))
    }
}
