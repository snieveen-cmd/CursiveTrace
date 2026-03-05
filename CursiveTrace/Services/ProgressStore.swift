import Foundation
import Combine

class ProgressStore: ObservableObject {
    @Published private(set) var progress: UserProgress

    private let key = "userProgress"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let stored = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.progress = stored
        } else {
            self.progress = .empty
        }
    }

    func record(itemID: String, isWord: Bool, stars: StarRating) {
        var existing = isWord
            ? (progress.wordProgress[itemID] ?? LetterProgress(bestStars: .none, attemptCount: 0))
            : (progress.letterProgress[itemID] ?? LetterProgress(bestStars: .none, attemptCount: 0))

        existing.attemptCount += 1
        if stars > existing.bestStars {
            existing.bestStars = stars
        }

        if isWord {
            progress.wordProgress[itemID] = existing
        } else {
            progress.letterProgress[itemID] = existing
        }

        checkWordsUnlock()
        save()
    }

    func bestStars(for itemID: String, isWord: Bool) -> StarRating {
        if isWord {
            return progress.wordProgress[itemID]?.bestStars ?? .none
        } else {
            return progress.letterProgress[itemID]?.bestStars ?? .none
        }
    }

    func isUnlocked(_ item: any TracingItem) -> Bool {
        switch item.unlockRequirement {
        case .always:
            return true
        case .requiresLetter(let letterID):
            return bestStars(for: letterID, isWord: false) >= .one
        case .requiresAllLetters:
            return progress.wordsUnlocked
        }
    }

    // MARK: - Private

    private func checkWordsUnlock() {
        let allLetters = "abcdefghijklmnopqrstuvwxyz"
        let allCompleted = allLetters.allSatisfy { char in
            bestStars(for: String(char), isWord: false) >= .one
        }
        if allCompleted {
            progress.wordsUnlocked = true
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
