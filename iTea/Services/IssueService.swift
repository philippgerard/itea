import Foundation

final class IssueService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getIssues(owner: String, repo: String, state: String = "open", page: Int = 1, limit: Int = 20) async throws -> [Issue] {
        try await apiClient.request(.issues(owner: owner, repo: repo, state: state, page: page, limit: limit))
    }

    func getIssue(owner: String, repo: String, index: Int) async throws -> Issue {
        try await apiClient.request(.issue(owner: owner, repo: repo, index: index))
    }

    func createIssue(owner: String, repo: String, title: String, body: String) async throws -> Issue {
        try await apiClient.request(.createIssue(owner: owner, repo: repo, title: title, body: body))
    }

    func updateIssue(owner: String, repo: String, index: Int, title: String? = nil, body: String? = nil, state: String? = nil) async throws -> Issue {
        try await apiClient.request(.updateIssue(owner: owner, repo: repo, index: index, title: title, body: body, state: state))
    }

    /// Closes an open issue
    func closeIssue(owner: String, repo: String, index: Int) async throws -> Issue {
        try await updateIssue(owner: owner, repo: repo, index: index, state: "closed")
    }

    /// Reopens a closed issue
    func reopenIssue(owner: String, repo: String, index: Int) async throws -> Issue {
        try await updateIssue(owner: owner, repo: repo, index: index, state: "open")
    }

    func getComments(owner: String, repo: String, issueIndex: Int, page: Int = 1) async throws -> [Comment] {
        try await apiClient.request(.issueComments(owner: owner, repo: repo, index: issueIndex, page: page))
    }

    func createComment(owner: String, repo: String, issueIndex: Int, body: String) async throws -> Comment {
        try await apiClient.request(.createIssueComment(owner: owner, repo: repo, index: issueIndex, body: body))
    }

    func searchIssues(query: String, page: Int = 1, limit: Int = 20) async throws -> [Issue] {
        try await apiClient.request(.searchIssues(query: query, page: page, limit: limit))
    }
}
