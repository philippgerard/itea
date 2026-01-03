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

    func updatePullRequest(owner: String, repo: String, index: Int, title: String? = nil, body: String? = nil, state: String? = nil) async throws -> PullRequest {
        try await apiClient.request(.updatePullRequest(owner: owner, repo: repo, index: index, title: title, body: body, state: state))
    }

    /// Closes an open pull request
    func closePullRequest(owner: String, repo: String, index: Int) async throws -> PullRequest {
        try await updatePullRequest(owner: owner, repo: repo, index: index, state: "closed")
    }

    /// Reopens a closed pull request (only works if not merged)
    func reopenPullRequest(owner: String, repo: String, index: Int) async throws -> PullRequest {
        try await updatePullRequest(owner: owner, repo: repo, index: index, state: "open")
    }

    /// Merges a pull request
    func mergePullRequest(owner: String, repo: String, index: Int, method: MergeMethod = .merge, message: String? = nil) async throws {
        try await apiClient.requestWithoutResponse(.mergePullRequest(owner: owner, repo: repo, index: index, method: method, message: message))
    }

    /// Gets the combined CI status for the head commit of a pull request
    func getCommitStatus(owner: String, repo: String, sha: String) async throws -> CombinedStatus {
        try await apiClient.request(.commitStatus(owner: owner, repo: repo, sha: sha))
    }

    /// Gets Actions workflow runs for a repository, filtered by a specific SHA
    func getActionRuns(owner: String, repo: String, sha: String?) async throws -> [ActionRun] {
        let response: ActionRunsResponse = try await apiClient.request(.actionRuns(owner: owner, repo: repo, limit: 50))

        // Filter runs matching the head SHA if provided
        guard let sha else {
            return response.workflowRuns
        }

        return response.workflowRuns.filter { $0.headSha == sha }
    }

    func getComments(owner: String, repo: String, prIndex: Int, page: Int = 1) async throws -> [Comment] {
        try await apiClient.request(.pullRequestComments(owner: owner, repo: repo, index: prIndex, page: page))
    }

    func createComment(owner: String, repo: String, prIndex: Int, body: String) async throws -> Comment {
        try await apiClient.request(.createPullRequestComment(owner: owner, repo: repo, index: prIndex, body: body))
    }

    func editComment(owner: String, repo: String, commentId: Int, body: String) async throws -> Comment {
        try await apiClient.request(.editComment(owner: owner, repo: repo, commentId: commentId, body: body))
    }

    func deleteComment(owner: String, repo: String, commentId: Int) async throws {
        try await apiClient.requestWithoutResponse(.deleteComment(owner: owner, repo: repo, commentId: commentId))
    }

    func searchPullRequests(query: String, page: Int = 1, limit: Int = 20) async throws -> [PullRequest] {
        try await apiClient.request(.searchPullRequests(query: query, page: page, limit: limit))
    }
}
