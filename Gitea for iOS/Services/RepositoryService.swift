import Foundation

final class RepositoryService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getRepositories(page: Int = 1, limit: Int = 20) async throws -> [Repository] {
        try await apiClient.request(.repositories(page: page, limit: limit))
    }

    func getRepository(owner: String, repo: String) async throws -> Repository {
        try await apiClient.request(.repository(owner: owner, repo: repo))
    }

    func getBranches(owner: String, repo: String) async throws -> [Branch] {
        try await apiClient.request(.repositoryBranches(owner: owner, repo: repo))
    }

    func watchRepository(owner: String, repo: String) async throws {
        try await apiClient.requestWithoutResponse(.watchRepository(owner: owner, repo: repo))
    }

    func unwatchRepository(owner: String, repo: String) async throws {
        try await apiClient.requestWithoutResponse(.unwatchRepository(owner: owner, repo: repo))
    }
}
