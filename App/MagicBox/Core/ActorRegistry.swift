import Foundation

/// Central dispatch table from `ContentRecord.type` to the `ContentActor`
/// that knows how to play it. This is the piece that keeps the schema open:
/// the NFC read path and the tag-authoring UI both go through this registry
/// instead of switching on hardcoded type strings.
final class ActorRegistry {
    static let shared = ActorRegistry()

    private(set) var actorsByType: [String: ContentActor] = [:]
    /// Registration order, preserved so authoring UI ("choose a type") has a
    /// stable, sensible order to present in.
    private(set) var registeredTypesInOrder: [String] = []

    private init() {
        registerBuiltInActors()
    }

    func register(_ actor: ContentActor, forType type: String) {
        actorsByType[type] = actor
        if !registeredTypesInOrder.contains(type) {
            registeredTypesInOrder.append(type)
        }
    }

    func actor(for type: String) -> ContentActor? {
        actorsByType[type]
    }

    /// All actor types, in registration order, exposed as their metatypes so
    /// authoring UI can read `displayName` / `iconSystemName` generically.
    var allActorTypes: [ContentActor] {
        registeredTypesInOrder.compactMap { actorsByType[$0] }
    }

    private func registerBuiltInActors() {
        register(StoryActor(), forType: StoryActor.typeIdentifier)
        register(VocabActor(), forType: VocabActor.typeIdentifier)
        register(MusicActor(), forType: MusicActor.typeIdentifier)
    }
}
