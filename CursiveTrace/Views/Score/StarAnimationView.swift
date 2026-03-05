import SwiftUI

struct StarAnimationView: View {
    let rating: StarRating
    let starSize: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...3, id: \.self) { i in
                AnimatedStarView(
                    filled: i <= rating.count,
                    delay: Double(i - 1) * 0.18,
                    size: starSize
                )
            }
        }
    }
}
