import SwiftUI

/// First step of tag creation: pick which kind of activity this tag will
/// trigger. Reads from `ActorRegistry` rather than a hardcoded list, so a
/// brand new activity type someone adds later shows up here automatically.
struct ChooseTypeStepView: View {
    let onSelect: (String) -> Void

    var body: some View {
        List {
            Section {
                Text("What should happen when this tag is tapped?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(ActorRegistry.shared.allActorTypes.indices, id: \.self) { index in
                let actor = ActorRegistry.shared.allActorTypes[index]
                Button {
                    onSelect(type(of: actor).typeIdentifier)
                } label: {
                    Label(type(of: actor).displayName, systemImage: type(of: actor).iconSystemName)
                        .font(.headline)
                }
            }
        }
    }
}
