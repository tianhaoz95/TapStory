import SwiftUI

/// Magic Box cannot turn on Guided Access itself -- there is no public API
/// for an app to do that, by Apple's design. This screen walks a parent
/// through the one-time setup and the per-session ritual instead.
struct GuidedAccessHelpView: View {
    var body: some View {
        List {
            Section("One-time setup") {
                stepRow(1, "Open Settings > Accessibility > Guided Access, and turn it on.")
                stepRow(2, "Tap Passcode Settings and set a Guided Access passcode (this can be different from your phone's normal passcode). You'll need it to end each session.")
                stepRow(3, "Optional: turn on \"Accessibility Shortcut\" for Guided Access so you can also start/stop it with a triple-click of the side button.")
            }

            Section("Every time you hand over Magic Box") {
                stepRow(1, "Open Magic Box.")
                stepRow(2, "Triple-click the side button (or top button on older iPhones).")
                stepRow(3, "Tap Options to circle out any areas you want to disable (usually not needed -- Magic Box already ignores touches outside the parent gate), then tap Start.")
                stepRow(4, "Hand the phone to your child. They can now only use Magic Box, and only by tapping tags -- the Home gesture, App Switcher, and other apps are unreachable.")
            }

            Section("When you want it back") {
                stepRow(1, "Triple-click the side button again.")
                stepRow(2, "Enter your Guided Access passcode.")
                stepRow(3, "Tap End in the top-left corner.")
            }

            Section {
                Text("Why can't Magic Box just do this automatically?")
                    .font(.subheadline.bold())
                Text("Apple deliberately keeps Guided Access under the parent's direct control -- no app, including this one, is allowed to enable device-wide lockdown on its own. That's a good thing: it means only you decide when the phone is locked to a single app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Guided Access Setup")
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
