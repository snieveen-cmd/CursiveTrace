import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var progressStore: ProgressStore

    var body: some View {
        NavigationStack(path: $appEnv.navigationPath) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 48) {
                    VStack(spacing: 8) {
                        Text("Cursive Trace")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.indigo)
                        Text("Learn to write in cursive")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 20) {
                        NavigationLink(value: AppEnvironment.Destination.letterGrid) {
                            MenuButton(
                                title: "Practice Letters",
                                subtitle: "Trace a–z",
                                icon: "a.circle.fill",
                                color: .indigo
                            )
                        }

                        NavigationLink(value: AppEnvironment.Destination.wordGrid) {
                            MenuButton(
                                title: "Practice Words",
                                subtitle: progressStore.progress.wordsUnlocked
                                    ? "Short cursive words"
                                    : "Complete all letters to unlock",
                                icon: progressStore.progress.wordsUnlocked ? "text.cursor" : "lock.fill",
                                color: progressStore.progress.wordsUnlocked ? .teal : .gray
                            )
                        }
                        .disabled(!progressStore.progress.wordsUnlocked)
                    }
                    .padding(.horizontal, 40)
                }
            }
            .navigationDestination(for: AppEnvironment.Destination.self) { destination in
                switch destination {
                case .letterGrid:
                    ProgressGridView(items: Letter.all, isWords: false)
                case .wordGrid:
                    ProgressGridView(items: CursiveWord.all, isWords: true)
                case .tracing(let itemID):
                    tracingView(for: itemID)
                }
            }
        }
    }

    @ViewBuilder
    private func tracingView(for itemID: String) -> some View {
        if let letter = Letter.all.first(where: { $0.id == itemID }) {
            TracingContainerView(item: letter, isWord: false)
        } else if let word = CursiveWord.all.first(where: { $0.id == itemID }) {
            TracingContainerView(item: word, isWord: true)
        } else {
            Text("Item not found").foregroundColor(.red)
        }
    }
}

// MARK: - MenuButton

private struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(color)
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
