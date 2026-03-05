import SwiftUI
import PencilKit

struct TracingContainerView<T: TracingItem>: View {
    let item: T
    let isWord: Bool

    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var progressStore: ProgressStore

    @State private var drawing = PKDrawing()
    @State private var scoreResult: StarRating?
    @State private var showScore = false
    @State private var canvasRect: CGRect = .zero

    var body: some View {
        VStack(spacing: 0) {
            // Letter label
            Text(item.displayName)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.indigo)
                .padding(.vertical, 12)

            // Canvas area
            GeometryReader { geo in
                ZStack {
                    PaperBackgroundView()
                    GuideOverlayView(letterPaths: item.paths, canvasSize: geo.size)
                    TracingCanvasView(drawing: $drawing)
                }
                .cornerRadius(16)
                .padding(16)
                .onAppear {
                    canvasRect = CGRect(
                        x: 16, y: 16,
                        width: geo.size.width - 32,
                        height: geo.size.height - 32
                    )
                }
                .onChange(of: geo.size) { newSize in
                    canvasRect = CGRect(
                        x: 16, y: 16,
                        width: newSize.width - 32,
                        height: newSize.height - 32
                    )
                }
            }

            TracingToolbarView(
                onClear: { drawing = PKDrawing() },
                onSubmit: submitDrawing
            )
        }
        .navigationTitle("Trace")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .fullScreenCover(isPresented: $showScore) {
            if let stars = scoreResult {
                ScoreView(
                    stars: stars,
                    itemName: item.displayName,
                    onTryAgain: {
                        showScore = false
                        drawing = PKDrawing()
                    },
                    onNext: {
                        showScore = false
                        navigateToNext()
                    }
                )
            }
        }
    }

    private func submitDrawing() {
        // Build reference UIBezierPaths scaled to the actual canvas rect
        let rect = canvasRect.isEmpty
            ? CGRect(x: 0, y: 0, width: 600, height: 700)
            : canvasRect
        let refPaths = item.paths.map { PathRenderer.bezierPath(from: $0, fittingIn: rect) }
        let stars = ScoringEngine.score(drawing: drawing, referencePaths: refPaths)
        scoreResult = stars
        progressStore.record(itemID: item.id, isWord: isWord, stars: stars)
        showScore = true
    }

    private func navigateToNext() {
        if isWord {
            let words = CursiveWord.all
            if let idx = words.firstIndex(where: { $0.id == item.id }), idx + 1 < words.count {
                appEnv.navigationPath.removeLast()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appEnv.navigateTo(.tracing(itemID: words[idx + 1].id))
                }
            } else {
                appEnv.pop()
            }
        } else {
            let letters = Letter.all
            if let idx = letters.firstIndex(where: { $0.id == item.id }), idx + 1 < letters.count {
                let next = letters[idx + 1]
                if progressStore.isUnlocked(next) {
                    appEnv.navigationPath.removeLast()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appEnv.navigateTo(.tracing(itemID: next.id))
                    }
                } else {
                    appEnv.pop()
                }
            } else {
                appEnv.pop()
            }
        }
    }
}

// MARK: - Paper background

private struct PaperBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground)

                Path { path in
                    let baseline = geo.size.height * 0.72
                    let xHeight  = geo.size.height * 0.38
                    path.move(to: CGPoint(x: 0, y: baseline))
                    path.addLine(to: CGPoint(x: geo.size.width, y: baseline))
                    path.move(to: CGPoint(x: 0, y: xHeight))
                    path.addLine(to: CGPoint(x: geo.size.width, y: xHeight))
                }
                .stroke(Color.blue.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
        }
    }
}
