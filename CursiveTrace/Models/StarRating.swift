import Foundation

enum StarRating: Int, Codable, Comparable {
    case none = 0
    case one = 1
    case two = 2
    case three = 3

    static func < (lhs: StarRating, rhs: StarRating) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayText: String {
        switch self {
        case .none: return "No stars"
        case .one: return "1 star"
        case .two: return "2 stars"
        case .three: return "3 stars"
        }
    }

    var count: Int { rawValue }
}
