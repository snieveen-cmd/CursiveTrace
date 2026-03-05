import SwiftUI
import UIKit

struct GuideOverlayView: UIViewRepresentable {
    let letterPaths: [LetterPath]
    let canvasSize: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = GuideView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let guideView = uiView as? GuideView else { return }
        guideView.update(letterPaths: letterPaths, in: CGRect(origin: .zero, size: canvasSize))
    }
}

// MARK: - GuideView

private class GuideView: UIView {
    private var guideLayers: [CAShapeLayer] = []
    private var dotLayers: [CAShapeLayer] = []

    func update(letterPaths: [LetterPath], in rect: CGRect) {
        // Remove existing layers
        (guideLayers + dotLayers).forEach { $0.removeFromSuperlayer() }
        guideLayers = []
        dotLayers = []

        for letterPath in letterPaths {
            let bezier = PathRenderer.bezierPath(from: letterPath, fittingIn: rect)

            // Dashed guide line
            let guideLayer = CAShapeLayer()
            guideLayer.path = bezier.cgPath
            guideLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
            guideLayer.fillColor = UIColor.clear.cgColor
            guideLayer.lineWidth = 20
            guideLayer.lineDashPattern = [12, 8]
            guideLayer.lineCap = .round
            layer.addSublayer(guideLayer)

            // Dash phase animation (shows stroke direction)
            let anim = CABasicAnimation(keyPath: "lineDashPhase")
            anim.fromValue = 0
            anim.toValue = -20
            anim.duration = 1.2
            anim.repeatCount = .infinity
            anim.isRemovedOnCompletion = false
            guideLayer.add(anim, forKey: "dashPhase")

            guideLayers.append(guideLayer)

            // Start point dot
            if let startPoint = bezier.cgPath.firstPoint {
                let dotRadius: CGFloat = 10
                let dotPath = UIBezierPath(
                    ovalIn: CGRect(
                        x: startPoint.x - dotRadius,
                        y: startPoint.y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                )
                let dotLayer = CAShapeLayer()
                dotLayer.path = dotPath.cgPath
                dotLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.8).cgColor
                dotLayer.strokeColor = UIColor.white.cgColor
                dotLayer.lineWidth = 2
                layer.addSublayer(dotLayer)
                dotLayers.append(dotLayer)
            }
        }
    }
}

// MARK: - CGPath helper

private extension CGPath {
    var firstPoint: CGPoint? {
        var result: CGPoint?
        applyWithBlock { elementPtr in
            guard result == nil else { return }
            let el = elementPtr.pointee
            if el.type == .moveToPoint {
                result = el.points[0]
            }
        }
        return result
    }
}
