import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showLogoutConfirmation = false
    @State private var showLicenses = false
    @State private var showResetPromptsConfirmation = false
    @AppStorage("quickMentionText") private var quickMentionText = "@claude"
    @AppStorage("accentColor") private var accentColorRaw: String = AccentColorOption.system.rawValue
    @AppStorage("issueTitlePrompt") private var issueTitlePrompt = DefaultPrompts.issue
    @AppStorage("prTitlePrompt") private var prTitlePrompt = DefaultPrompts.pullRequest

    private enum DefaultPrompts {
        static let issue = "Generate a concise issue title (maximum 10 words) for this bug report or feature request.\nRespond with only the title text, no quotes, prefixes, or explanation."
        static let pullRequest = "Generate a concise pull request title (maximum 10 words) for this code change.\nRespond with only the title text, no quotes, prefixes, or explanation."
    }

    private var selectedAccentColor: AccentColorOption {
        AccentColorOption(rawValue: accentColorRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                appearanceSection
                quickActionsSection
                titleGenerationSection
                aboutSection
                legalSection
            }
            .navigationTitle("Settings")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task { await authManager.logout() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Reset Prompts", isPresented: $showResetPromptsConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                issueTitlePrompt = DefaultPrompts.issue
                prTitlePrompt = DefaultPrompts.pullRequest
            }
        } message: {
            Text("This will reset both prompts to their default values.")
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
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            HStack {
                Text("Accent Color")
                Spacer()
                Menu {
                    ForEach(AccentColorOption.allCases) { option in
                        Button {
                            accentColorRaw = option.rawValue
                        } label: {
                            HStack {
                                Circle()
                                    .fill(option.previewColor)
                                    .frame(width: 12, height: 12)
                                Text(option.displayName)
                                if option == selectedAccentColor {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(selectedAccentColor.previewColor)
                            .frame(width: 16, height: 16)
                        Text(selectedAccentColor.displayName)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        Section {
            HStack {
                Text("Quick Mention")
                Spacer()
                TextField("@claude", text: $quickMentionText)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 150)
            }
        } header: {
            Text("Quick Actions")
        } footer: {
            Text("This text will be inserted when you tap the mention button in the new issue form.")
        }
    }

    private var titleGenerationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Issue Title Prompt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $issueTitlePrompt)
                    .frame(height: 80)
                    .font(.footnote)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .listRowSeparator(.hidden)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pull Request Title Prompt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $prTitlePrompt)
                    .frame(height: 80)
                    .font(.footnote)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .listRowSeparator(.hidden)

            Button(role: .destructive) {
                showResetPromptsConfirmation = true
            } label: {
                Text("Reset to Defaults")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        } header: {
            Text("Title Generation")
        } footer: {
            Text("Customize the prompts used when generating titles with the sparkles button. The description you enter will be appended to these prompts.")
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

            Link(destination: URL(string: "https://github.com/philippgerard/itea")!) {
                HStack {
                    Text("GitHub Repository")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
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

    private var legalSection: some View {
        Section("Legal") {
            Link(destination: URL(string: "https://github.com/philippgerard/itea/blob/main/LICENSE")!) {
                HStack {
                    Text("MIT License")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://github.com/philippgerard/itea/blob/main/PRIVACY.md")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }

            NavigationLink {
                LicensesView()
            } label: {
                Text("Open Source Licenses")
            }
        }
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MarkdownUI")
                        .font(.headline)

                    Text("Copyright (c) 2021 Guillermo Gonzalez")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("""
                    MIT License

                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                    """)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("This app uses the following open source software:")
            }
        }
        .navigationTitle("Licenses")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
