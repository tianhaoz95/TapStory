import Foundation

struct MusicPayload: Codable, Equatable {
    var title: String
    var symbol: String
    var audio: MediaRef
    /// Lullabies/songs typically loop until the child taps a new tag;
    /// short sound-effect-style clips can set this to false to play once.
    var loop: Bool
}
