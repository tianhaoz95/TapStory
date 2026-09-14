import SwiftUI

struct BundledLibraryPickerView: View {
    let type: String
    @Binding var path: NavigationPath

    var body: some View {
        let items = BundledLibrary.items(forType: type)
        List {
            if items.isEmpty {
                Text("No bundled content for this type yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(items) { item in
                Button {
                    path.append(CreateTagRoute.writeTag(record: item.record, title: item.title))
                } label: {
                    Text(item.title).font(.headline)
                }
            }
        }
        .navigationTitle("Choose One")
    }
}
