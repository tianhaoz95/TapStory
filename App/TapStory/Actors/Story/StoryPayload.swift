import Foundation

struct StoryPage: Codable, Equatable {
    var caption: String
    /// SF Symbol name used as the page's illustration. Keeping illustrations
    /// to symbols (rather than photo/art assets) avoids needing camera or
    /// photo-library permissions in a toddler-facing app -- see README for
    /// the "real illustrations" follow-up idea.
    var symbol: String
    var audio: MediaRef
}

struct StoryPayload: Codable, Equatable {
    var title: String
    var pages: [StoryPage]
}
