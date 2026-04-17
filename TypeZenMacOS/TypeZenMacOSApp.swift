import SwiftUI
import SwiftData

@main
struct TypeZenMacOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PracticeSession.self, FavoriteText.self])
        .defaultSize(width: 1000, height: 700)
    }
}
