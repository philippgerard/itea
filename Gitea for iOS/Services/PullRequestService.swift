import Foundation

final class PullRequestService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getPullRequests(owner: String, repo: String, state: String = "open", page: Int = 1, limit: Int = 20) async throws -> [PullRequest] {
        try await apiClient.request(.pullRequests(owner: owner, repo: repo, state: state, page: page, limit: limit))
    }

    func getPullRequest(owner: String, repo: String, index: Int) async throws -> PullRequest {
        try await apiClient.request(.pullRequest(owner: owner, repo: repo, index: index))
    }

    func createPullRequest(owner: String, repo: String, title: String, body: String, head: String, base: String) async throws -> PullRequest {
        try await apiClient.request(.createPullRequest(owner: owner, repo: repo, title: title, body: body, head: head, base: base))
    }

    func getComments(owner: String, repo: String, prIndex: Int, page: Int = 1) async throws -> [Comment] {
        try await apiClient.request(.pullRequestComments(owner: owner, repo: repo, index: prIndex, page: page))
    }

    func createComment(owner: String, repo: String, prIndex: Int, body: String) async throws -> Comment {
        try await apiClient.request(.createPullRequestComment(owner: owner, repo: repo, index: prIndex, body: body))
    }
}
