import SwiftUI

struct ParentDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isCreateFlowPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isCreateFlowPresented = true
                    } label: {
                        Label("Create a New Magic Tag", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }

                Section("My Tags") {
                    NavigationLink(destination: TagLibraryListView()) {
                        Label("Manage My Tags", systemImage: "square.grid.2x2")
                    }
                }

                Section("Setup") {
                    NavigationLink(destination: GuidedAccessHelpView()) {
                        Label("Guided Access Setup", systemImage: "lock.shield")
                    }
                    NavigationLink(destination: NFCTagInspectorView()) {
                        Label("Test / Inspect a Tag", systemImage: "wave.3.right")
                    }
                }

                Section("More") {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("TapStory")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $isCreateFlowPresented) {
                CreateTagFlowView()
            }
        }
    }
}
