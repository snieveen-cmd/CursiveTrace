import SwiftUI

class AppEnvironment: ObservableObject {
    @Published var navigationPath = NavigationPath()

    enum Destination: Hashable {
        case letterGrid
        case wordGrid
        case tracing(itemID: String)
    }

    func navigateTo(_ destination: Destination) {
        navigationPath.append(destination)
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}
