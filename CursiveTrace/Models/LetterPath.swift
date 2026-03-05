import CoreGraphics
import Foundation

struct PathSegment: Codable {
    enum SegmentType: String, Codable {
        case moveTo
        case lineTo
        case curveTo
    }

    let type: SegmentType
    let point: CodableCGPoint
    let control1: CodableCGPoint?
    let control2: CodableCGPoint?
}

struct LetterPath: Codable {
    let character: String
    let segments: [PathSegment]
    let viewBox: CodableCGSize
}

// MARK: - Codable CGPoint / CGSize wrappers

struct CodableCGPoint: Codable {
    let x: CGFloat
    let y: CGFloat

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

struct CodableCGSize: Codable {
    let width: CGFloat
    let height: CGFloat

    var cgSize: CGSize { CGSize(width: width, height: height) }
}
