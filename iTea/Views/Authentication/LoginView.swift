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
                    Spacer(minLength: geometry.size.height * 0.12)

                    // Logo
                    VStack(spacing: 6) {
                        Text("iTea")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("A Gitea client for iOS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 48)

                    // Glass card
                    VStack(spacing: 0) {
                        // Server URL field
                        TextField("Server URL", text: $serverURL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            #if !targetEnvironment(macCatalyst)
                            .keyboardType(.URL)
                            #endif
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                        Divider()
                            .padding(.leading, 16)

                        // Access Token field
                        HStack(spacing: 12) {
                            SecureField("Access Token", text: $accessToken)
                                .textContentType(.password)

                            Button {
                                showTokenInfo = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(uiColor: .separator), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)

                    // Sign In button
                    Button {
                        Task { await login() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .disabled(!isFormValid || isLoading)
                    .foregroundStyle(isFormValid && !isLoading ? .primary : .secondary)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color(uiColor: .separator), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer(minLength: geometry.size.height * 0.15)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color(.systemGroupedBackground))
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
            List {
                Section {
                    StepView(number: 1, text: "Open your Gitea instance in a browser")
                    StepView(number: 2, text: "Go to Settings → Applications")
                    StepView(number: 3, text: "Enter a name for your token")
                    StepView(number: 4, text: "Select scopes: user, repository, issue, notification")
                    StepView(number: 5, text: "Click Generate Token")
                    StepView(number: 6, text: "Copy and paste the token here")
                } header: {
                    Text("Steps")
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Copy your token immediately — it won't be shown again.")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Access Token")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(number)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
