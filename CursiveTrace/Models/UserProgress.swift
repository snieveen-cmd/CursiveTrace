import Foundation

struct LetterProgress: Codable {
    var bestStars: StarRating
    var attemptCount: Int
}

struct UserProgress: Codable {
    var letterProgress: [String: LetterProgress]
    var wordProgress: [String: LetterProgress]
    var wordsUnlocked: Bool

    static var empty: UserProgress {
        UserProgress(letterProgress: [:], wordProgress: [:], wordsUnlocked: false)
    }
}
