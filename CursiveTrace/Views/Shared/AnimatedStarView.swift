import SwiftUI

struct AnimatedStarView: View {
    let filled: Bool
    let delay: Double
    let size: CGFloat

    @State private var appeared = false

    var body: some View {
        Image(systemName: filled ? "star.fill" : "star")
            .font(.system(size: size))
            .foregroundColor(filled ? .yellow : .gray.opacity(0.3))
            .scaleEffect(appeared ? 1 : 0.1)
            .rotationEffect(.degrees(appeared ? 0 : -30))
            .shadow(color: filled ? .yellow.opacity(0.6) : .clear, radius: 8)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                    appeared = true
                }
            }
    }
}
