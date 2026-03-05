import UIKit

enum PathRenderer {
    static func bezierPath(from letterPath: LetterPath, fittingIn rect: CGRect) -> UIBezierPath {
        let vb = letterPath.viewBox.cgSize
        let scale = min(rect.width / vb.width, rect.height / vb.height)
        let offsetX = rect.midX - vb.width * scale / 2
        let offsetY = rect.midY - vb.height * scale / 2

        let path = UIBezierPath()

        for segment in letterPath.segments {
            let p = transform(segment.point.cgPoint, scale: scale, offsetX: offsetX, offsetY: offsetY)

            switch segment.type {
            case .moveTo:
                path.move(to: p)

            case .lineTo:
                path.addLine(to: p)

            case .curveTo:
                guard let c1 = segment.control1, let c2 = segment.control2 else {
                    path.addLine(to: p)
                    continue
                }
                let cp1 = transform(c1.cgPoint, scale: scale, offsetX: offsetX, offsetY: offsetY)
                let cp2 = transform(c2.cgPoint, scale: scale, offsetX: offsetX, offsetY: offsetY)
                path.addCurve(to: p, controlPoint1: cp1, controlPoint2: cp2)
            }
        }

        return path
    }

    static func samplePoints(from path: UIBezierPath, count: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        path.cgPath.applyWithBlock { elementPtr in
            let el = elementPtr.pointee
            switch el.type {
            case .moveToPoint:
                points.append(el.points[0])
            case .addLineToPoint:
                points.append(el.points[0])
            case .addCurveToPoint:
                // Sample along cubic bezier
                let start = points.last ?? el.points[0]
                let cp1 = el.points[0]
                let cp2 = el.points[1]
                let end = el.points[2]
                let steps = max(count / 10, 8)
                for i in 1...steps {
                    let t = CGFloat(i) / CGFloat(steps)
                    let pt = cubicBezierPoint(t: t, p0: start, p1: cp1, p2: cp2, p3: end)
                    points.append(pt)
                }
            case .addQuadCurveToPoint:
                points.append(el.points[1])
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }

        // Resample to exactly `count` points evenly spaced
        guard points.count >= 2 else { return points }
        return resample(points, to: count)
    }

    // MARK: - Private

    private static func transform(_ point: CGPoint, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scale + offsetX, y: point.y * scale + offsetY)
    }

    private static func cubicBezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt*mt*mt*p0.x + 3*mt*mt*t*p1.x + 3*mt*t*t*p2.x + t*t*t*p3.x
        let y = mt*mt*mt*p0.y + 3*mt*mt*t*p1.y + 3*mt*t*t*p2.y + t*t*t*p3.y
        return CGPoint(x: x, y: y)
    }

    private static func resample(_ points: [CGPoint], to count: Int) -> [CGPoint] {
        guard points.count >= 2, count >= 2 else { return points }

        // Compute cumulative arc lengths
        var lengths: [CGFloat] = [0]
        for i in 1..<points.count {
            let d = distance(points[i], points[i - 1])
            lengths.append(lengths[i - 1] + d)
        }
        let totalLength = lengths.last!
        guard totalLength > 0 else { return Array(repeating: points[0], count: count) }

        var resampled: [CGPoint] = []
        var segIdx = 0

        for i in 0..<count {
            let targetLen = totalLength * CGFloat(i) / CGFloat(count - 1)
            while segIdx < lengths.count - 2 && lengths[segIdx + 1] < targetLen {
                segIdx += 1
            }
            let segLen = lengths[segIdx + 1] - lengths[segIdx]
            let t = segLen > 0 ? (targetLen - lengths[segIdx]) / segLen : 0
            let p = lerp(points[segIdx], points[segIdx + 1], t: t)
            resampled.append(p)
        }
        return resampled
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
