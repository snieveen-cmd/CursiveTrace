import SwiftUI

struct ProgressGridView<T: TracingItem>: View {
    let items: [T]
    let isWords: Bool

    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var progressStore: ProgressStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    let unlocked = progressStore.isUnlocked(item)
                    let stars = progressStore.bestStars(for: item.id, isWord: isWords)

                    Button {
                        if unlocked {
                            appEnv.navigateTo(.tracing(itemID: item.id))
                        }
                    } label: {
                        LetterProgressCell(
                            title: item.displayName.uppercased(),
                            stars: stars,
                            isUnlocked: unlocked
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                }
            }
            .padding(20)
        }
        .navigationTitle(isWords ? "Words" : "Letters")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
