import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await authManager.logout() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if let user = authManager.currentUser {
                HStack(spacing: 12) {
                    UserAvatarView(user: user, size: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.headline)

                        Text("@\(user.login)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if let serverURL = authManager.getServerURL() {
                HStack {
                    Text("Server")
                    Spacer()
                    Text(serverURL.host ?? serverURL.absoluteString)
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                    Spacer()
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://docs.gitea.com/api/1.24/")!) {
                HStack {
                    Text("Gitea API Documentation")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
