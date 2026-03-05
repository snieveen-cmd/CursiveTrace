import PencilKit
import UIKit

enum ScoringEngine {
    // MARK: - Public

    static func score(drawing: PKDrawing, referencePaths: [UIBezierPath]) -> StarRating {
        guard !drawing.strokes.isEmpty else { return .none }

        let studentPoints = extractPoints(from: drawing)
        guard !studentPoints.isEmpty else { return .none }

        // Combine all reference path samples
        let refPoints = referencePaths.flatMap { samplePath($0, count: 80) }
        guard !refPoints.isEmpty else { return .one }

        // Stage 1: Coverage — did they trace enough of the reference path?
        let coverThreshold: CGFloat = 22
        let covered = refPoints.filter { rp in
            studentPoints.contains { dist($0, rp) < coverThreshold }
        }.count
        let coverageRatio = Double(covered) / Double(refPoints.count)
        guard coverageRatio > 0.65 else { return .one }

        // Stage 2: Precision — how close did they stay to the reference?
        let totalDev = studentPoints.reduce(CGFloat(0)) { sum, sp in
            let closest = refPoints.map { dist($0, sp) }.min() ?? 999
            return sum + closest
        }
        let meanDev = totalDev / CGFloat(studentPoints.count)

        switch meanDev {
        case ..<15: return .three
        case ..<28: return .two
        default:    return .one
        }
    }

    // MARK: - Private

    private static func samplePath(_ path: UIBezierPath, count: Int) -> [CGPoint] {
        PathRenderer.samplePoints(from: path, count: count)
    }

    private static func extractPoints(from drawing: PKDrawing) -> [CGPoint] {
        var points: [CGPoint] = []
        for stroke in drawing.strokes {
            let indices = stride(from: 0, to: stroke.path.count, by: max(1, stroke.path.count / 60))
            for i in indices {
                points.append(stroke.path[i].location)
            }
        }
        return points
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
    }
}
