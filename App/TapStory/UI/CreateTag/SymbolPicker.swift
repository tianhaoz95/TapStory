import SwiftUI

/// A curated set of SF Symbols that read clearly at large size and cover
/// common toddler-content themes (animals, weather, food, family). Keeping
/// illustrations to symbols -- rather than photos -- avoids needing camera
/// or photo-library permissions in a kids' app; see README for the "real
/// artwork" follow-up idea.
enum CuratedSymbols {
    static let all: [String] = [
        "hare.fill", "tortoise.fill", "bird.fill", "fish.fill", "ladybug.fill",
        "pawprint.fill", "leaf.fill", "tree.fill", "sun.max.fill", "moon.stars.fill",
        "cloud.rain.fill", "star.fill", "heart.fill", "house.fill", "car.fill",
        "airplane", "sailboat.fill", "balloon.fill", "gift.fill", "teddybear.fill",
        "carrot.fill", "applelogo", "birthday.cake.fill", "book.fill", "paintpalette.fill",
        "music.note", "guitars.fill", "figure.2.and.child.holdinghands", "person.fill",
        "crown.fill", "sparkles", "drop.fill", "flame.fill", "snowflake",
        "m.circle.fill", "a.circle.fill", "b.circle.fill", "c.circle.fill", "s.circle.fill"
    ]
}

struct SymbolPicker: View {
    @Binding var selection: String
    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CuratedSymbols.all, id: \.self) { symbol in
                    Button {
                        selection = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 24))
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selection == symbol ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selection == symbol ? Color.accentColor : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 220)
    }
}
