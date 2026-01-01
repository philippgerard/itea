import Foundation

final class UserService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getCurrentUser() async throws -> User {
        try await apiClient.request(.currentUser)
    }
}
