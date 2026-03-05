import SwiftUI

struct ScoreView: View {
    let stars: StarRating
    let itemName: String
    let onTryAgain: () -> Void
    let onNext: () -> Void

    @State private var confettiOpacity: Double = 0

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Letter display
                Text(itemName)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4)

                // Stars
                StarAnimationView(rating: stars, starSize: 64)

                // Message
                Text(message)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onNext) {
                        Text("Next Letter")
                            .font(.headline.bold())
                            .foregroundColor(.indigo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(.white)
                            .cornerRadius(16)
                    }

                    Button(action: onTryAgain) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private var message: String {
        switch stars {
        case .none:  return "Give it a try!"
        case .one:   return "Good start! Keep practicing."
        case .two:   return "Nice work! Almost perfect."
        case .three: return "Excellent! Perfect tracing!"
        }
    }

    private var backgroundGradient: LinearGradient {
        let colors: [Color]
        switch stars {
        case .none:  colors = [.gray, .gray.opacity(0.7)]
        case .one:   colors = [.orange, .red.opacity(0.8)]
        case .two:   colors = [.blue, .purple]
        case .three: colors = [.indigo, .purple, .pink]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
