import SwiftUI

@main
struct GiteaApp: App {
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
        #if targetEnvironment(macCatalyst)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        #endif
    }
}
