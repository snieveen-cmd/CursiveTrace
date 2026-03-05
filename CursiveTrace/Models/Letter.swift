import Foundation

struct Letter: TracingItem {
    let id: String
    let displayName: String
    let paths: [LetterPath]
    let unlockRequirement: UnlockRule

    static let all: [Letter] = {
        guard let url = Bundle.main.url(forResource: "cursive_paths", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let letterPaths = try? JSONDecoder().decode([LetterPath].self, from: data) else {
            return []
        }

        let pathMap = Dictionary(uniqueKeysWithValues: letterPaths.map { ($0.character, $0) })

        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        return alphabet.enumerated().compactMap { index, char in
            let key = String(char)
            guard let path = pathMap[key] else { return nil }

            let unlock: UnlockRule
            if index == 0 {
                unlock = .always
            } else {
                let prevIndex = alphabet.index(alphabet.startIndex, offsetBy: index - 1)
                let prev = String(alphabet[prevIndex])
                unlock = .requiresLetter(prev)
            }

            return Letter(id: key, displayName: key, paths: [path], unlockRequirement: unlock)
        }
    }()
}
