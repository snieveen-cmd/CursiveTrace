import Foundation

enum UnlockRule: Codable, Hashable {
    case always
    case requiresLetter(String)
    case requiresAllLetters
}

protocol TracingItem: Identifiable {
    var id: String { get }
    var displayName: String { get }
    var paths: [LetterPath] { get }
    var unlockRequirement: UnlockRule { get }
}
