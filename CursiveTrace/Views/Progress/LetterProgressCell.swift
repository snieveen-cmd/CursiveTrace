import SwiftUI

struct LetterProgressCell: View {
    let title: String
    let stars: StarRating
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(isUnlocked ? 0.08 : 0), radius: 4, x: 0, y: 2)

                if isUnlocked {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        HStack(spacing: 2) {
                            ForEach(1...3, id: \.self) { i in
                                Image(systemName: i <= stars.count ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundColor(i <= stars.count ? .yellow : .gray.opacity(0.4))
                            }
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    private var backgroundColor: Color {
        guard isUnlocked else { return Color(.systemGray5) }
        switch stars {
        case .none:   return Color(.secondarySystemBackground)
        case .one:    return Color.orange.opacity(0.15)
        case .two:    return Color.yellow.opacity(0.2)
        case .three:  return Color.green.opacity(0.2)
        }
    }
}
