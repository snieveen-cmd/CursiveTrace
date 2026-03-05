import SwiftUI

@main
struct CursiveTraceApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    @StateObject private var progressStore = ProgressStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appEnvironment)
                .environmentObject(progressStore)
        }
    }
}
