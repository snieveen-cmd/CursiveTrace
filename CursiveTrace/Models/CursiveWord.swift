import Foundation

struct CursiveWord: TracingItem {
    let id: String
    let displayName: String
    let paths: [LetterPath]
    let unlockRequirement: UnlockRule = .requiresAllLetters

    static let all: [CursiveWord] = {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let wordDefs = try? JSONDecoder().decode([WordDefinition].self, from: data) else {
            return []
        }

        guard let pathsURL = Bundle.main.url(forResource: "cursive_paths", withExtension: "json"),
              let pathsData = try? Data(contentsOf: pathsURL),
              let letterPaths = try? JSONDecoder().decode([LetterPath].self, from: pathsData) else {
            return []
        }

        let pathMap = Dictionary(uniqueKeysWithValues: letterPaths.map { ($0.character, $0) })

        return wordDefs.compactMap { def in
            let wordPaths = def.word.lowercased().compactMap { pathMap[String($0)] }
            guard wordPaths.count == def.word.count else { return nil }
            return CursiveWord(id: def.word, displayName: def.word, paths: wordPaths)
        }
    }()
}

private struct WordDefinition: Codable {
    let word: String
}
