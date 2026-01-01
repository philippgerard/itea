import SwiftUI

@main
struct GiteaApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @State private var deepLinkHandler = DeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environment(deepLinkHandler)
        }
        #if targetEnvironment(macCatalyst)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        #endif
    }
}
