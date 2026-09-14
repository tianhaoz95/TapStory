import SwiftUI

/// A simple arithmetic challenge that gates access to the parent dashboard.
/// This is not meant to be secure against a determined adult (it isn't
/// trying to be) -- it exists to make it very unlikely a toddler stumbles
/// into settings, tag creation, or NFC writing, matching the "parental
/// gate" pattern common in kids' apps.
struct ParentGateChallengeView: View {
    let onUnlocked: () -> Void
    let onCancel: () -> Void

    @State private var a = Int.random(in: 3...9)
    @State private var b = Int.random(in: 3...9)
    @State private var choices: [Int] = []
    @State private var wrongAttempt = false

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Parents Only")
                .font(.title2.bold())

            Text("What is \(a) + \(b)?")
                .font(.title.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        if choice == a + b {
                            onUnlocked()
                        } else {
                            wrongAttempt = true
                            reroll()
                        }
                    } label: {
                        Text("\(choice)")
                            .font(.title2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)

            if wrongAttempt {
                Text("Not quite -- try the new question.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            Spacer()

            Button("Cancel", role: .cancel, action: onCancel)
                .padding(.bottom, 24)
        }
        .onAppear { reroll() }
    }

    private func reroll() {
        a = Int.random(in: 3...9)
        b = Int.random(in: 3...9)
        var options = Set<Int>([a + b])
        while options.count < 4 {
            options.insert(Int.random(in: 2...20))
        }
        choices = Array(options).shuffled()
    }
}
