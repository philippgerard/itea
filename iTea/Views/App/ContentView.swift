import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("accentColor") private var accentColorRaw: String = AccentColorOption.system.rawValue

    private var accentColor: Color? {
        AccentColorOption(rawValue: accentColorRaw)?.color
    }

    var body: some View {
        Group {
            if authManager.isCheckingAuth {
                ProgressView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .tint(accentColor)
        .animation(.default, value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
