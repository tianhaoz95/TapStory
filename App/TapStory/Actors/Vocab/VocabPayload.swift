import Foundation

struct VocabPayload: Codable, Equatable {
    var title: String
    var word: String
    /// Optional single letter this card teaches (e.g. "M"). Nil for
    /// general-vocabulary cards that aren't part of an alphabet set.
    var letter: String?
    var symbol: String
    var audio: MediaRef
}
