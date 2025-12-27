import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var serverURL = ""
    @State private var accessToken = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showTokenInfo = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)

                        Text("iTea")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("A Gitea client")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 48)

                    // Form card
                    VStack(spacing: 24) {
                        // Server URL field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server URL")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            TextField("", text: $serverURL, prompt: Text("gitea.example.com"))
                                .textFieldStyle(.plain)
                                .textContentType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                #if !targetEnvironment(macCatalyst)
                                .keyboardType(.URL)
                                #endif
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Access Token field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Access Token")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    showTokenInfo = true
                                } label: {
                                    Image(systemName: "questionmark.circle")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            SecureField("", text: $accessToken, prompt: Text("Paste your token here"))
                                .textFieldStyle(.plain)
                                .textContentType(.password)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Sign In button
                        Button {
                            Task { await login() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .disabled(!isFormValid || isLoading)
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 400)

                    // Help link
                    Button {
                        showTokenInfo = true
                    } label: {
                        Text("How to create an access token")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)

                    Spacer(minLength: 60)
                }
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showTokenInfo) {
            TokenInfoSheet()
        }
    }

    private var isFormValid: Bool {
        !serverURL.isEmpty && !accessToken.isEmpty
    }

    private func login() async {
        // Normalize the URL - add https:// if no scheme provided
        var urlString = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.contains("://") {
            urlString = "https://" + urlString
        }

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid server URL"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authManager.login(serverURL: url, accessToken: accessToken)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

struct TokenInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Creating an Access Token")
                        .font(.title2)
                        .fontWeight(.bold)

                    VStack(alignment: .leading, spacing: 20) {
                        StepView(number: 1, text: "Open your Gitea instance in a browser")
                        StepView(number: 2, text: "Go to Settings → Applications")
                        StepView(number: 3, text: "Enter a name for your token")
                        StepView(number: 4, text: "Select scopes: user, repository, issue, notification")
                        StepView(number: 5, text: "Click Generate Token")
                        StepView(number: 6, text: "Copy and paste the token here")
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Copy your token immediately — it won't be shown again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(24)
            }
            .navigationTitle("Access Token")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct StepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
