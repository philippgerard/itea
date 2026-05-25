import Foundation
import SwiftUI

@MainActor
final class AuthenticationManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isCheckingAuth = true
    @Published private(set) var currentUser: User?
    @Published private(set) var serverURL: URL?

    private let tokenStorage = TokenStorage()
    private var accessToken: String?

    init() {
        Task {
            await loadStoredCredentials()
        }
    }

    private func loadStoredCredentials() async {
        defer { isCheckingAuth = false }

        // UI testing path: pull credentials from launch arguments instead of
        // the Keychain so screenshot tests can boot straight into the app.
        // Production behavior is unchanged when no -UITesting* args are set.
        if let testCreds = UITestingLaunchArguments.credentials() {
            self.serverURL = testCreds.serverURL
            self.accessToken = testCreds.accessToken
            do {
                self.currentUser = try await validateAndFetchUser()
                self.isAuthenticated = true
            } catch {
                self.serverURL = nil
                self.accessToken = nil
            }
            return
        }

        guard let credentials = await tokenStorage.load() else { return }

        self.serverURL = credentials.serverURL
        self.accessToken = credentials.accessToken

        // Validate the token by fetching current user
        do {
            let user = try await validateAndFetchUser()
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            // Token is invalid, clear credentials
            try? await tokenStorage.delete()
            self.serverURL = nil
            self.accessToken = nil
        }
    }

    func login(serverURL: URL, accessToken: String) async throws {
        self.serverURL = serverURL
        self.accessToken = accessToken

        // Validate credentials by fetching current user
        let user = try await validateAndFetchUser()

        // Store credentials securely
        try await tokenStorage.save(serverURL: serverURL, accessToken: accessToken)

        self.currentUser = user
        self.isAuthenticated = true
    }

    func logout() async {
        try? await tokenStorage.delete()
        self.isAuthenticated = false
        self.currentUser = nil
        self.serverURL = nil
        self.accessToken = nil
    }

    func getAccessToken() -> String? {
        accessToken
    }

    func getServerURL() -> URL? {
        serverURL
    }

    private func validateAndFetchUser() async throws -> User {
        guard let serverURL = serverURL, let token = accessToken else {
            throw AuthenticationError.notAuthenticated
        }

        let apiClient = APIClient(baseURL: serverURL, tokenProvider: { token })
        let userService = UserService(apiClient: apiClient)
        return try await userService.getCurrentUser()
    }
}

private enum UITestingLaunchArguments {
    struct Credentials {
        let serverURL: URL
        let accessToken: String
    }

    static func credentials() -> Credentials? {
        let args = ProcessInfo.processInfo.arguments
        guard
            let serverIdx = args.firstIndex(of: "-UITestingServerURL"),
            serverIdx + 1 < args.count,
            let serverURL = URL(string: args[serverIdx + 1]),
            let tokenIdx = args.firstIndex(of: "-UITestingToken"),
            tokenIdx + 1 < args.count
        else { return nil }

        return Credentials(serverURL: serverURL, accessToken: args[tokenIdx + 1])
    }
}

enum AuthenticationError: Error, LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidCredentials:
            return "Invalid server URL or access token"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
