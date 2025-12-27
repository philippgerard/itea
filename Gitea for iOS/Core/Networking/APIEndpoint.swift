import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    let body: (any Encodable & Sendable)?

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable & Sendable)? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
    }

    // MARK: - User Endpoints

    static var currentUser: APIEndpoint {
        APIEndpoint(path: "/user")
    }

    // MARK: - Repository Endpoints

    static func repositories(page: Int = 1, limit: Int = 20) -> APIEndpoint {
        APIEndpoint(
            path: "/user/repos",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
    }

    static func repository(owner: String, repo: String) -> APIEndpoint {
        APIEndpoint(path: "/repos/\(owner)/\(repo)")
    }

    static func watchRepository(owner: String, repo: String) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/subscription",
            method: .put
        )
    }

    static func unwatchRepository(owner: String, repo: String) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/subscription",
            method: .delete
        )
    }

    static func repositoryBranches(owner: String, repo: String) -> APIEndpoint {
        APIEndpoint(path: "/repos/\(owner)/\(repo)/branches")
    }

    // MARK: - Issue Endpoints

    static func issues(owner: String, repo: String, state: String = "open", page: Int = 1, limit: Int = 20) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues",
            queryItems: [
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "type", value: "issues")
            ]
        )
    }

    static func issue(owner: String, repo: String, index: Int) -> APIEndpoint {
        APIEndpoint(path: "/repos/\(owner)/\(repo)/issues/\(index)")
    }

    static func createIssue(owner: String, repo: String, title: String, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues",
            method: .post,
            body: CreateIssueBody(title: title, body: body)
        )
    }

    static func updateIssue(owner: String, repo: String, index: Int, title: String? = nil, body: String? = nil, state: String? = nil) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues/\(index)",
            method: .patch,
            body: UpdateIssueBody(title: title, body: body, state: state)
        )
    }

    static func issueComments(owner: String, repo: String, index: Int, page: Int = 1) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues/\(index)/comments",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)")
            ]
        )
    }

    static func createIssueComment(owner: String, repo: String, index: Int, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues/\(index)/comments",
            method: .post,
            body: CreateCommentBody(body: body)
        )
    }

    // MARK: - Pull Request Endpoints

    static func pullRequests(owner: String, repo: String, state: String = "open", page: Int = 1, limit: Int = 20) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/pulls",
            queryItems: [
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
    }

    static func pullRequest(owner: String, repo: String, index: Int) -> APIEndpoint {
        APIEndpoint(path: "/repos/\(owner)/\(repo)/pulls/\(index)")
    }

    static func createPullRequest(owner: String, repo: String, title: String, body: String, head: String, base: String) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/pulls",
            method: .post,
            body: CreatePullRequestBody(title: title, body: body, head: head, base: base)
        )
    }

    static func pullRequestComments(owner: String, repo: String, index: Int, page: Int = 1) -> APIEndpoint {
        // PR comments use the issues endpoint in Gitea
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues/\(index)/comments",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)")
            ]
        )
    }

    static func createPullRequestComment(owner: String, repo: String, index: Int, body: String) -> APIEndpoint {
        APIEndpoint(
            path: "/repos/\(owner)/\(repo)/issues/\(index)/comments",
            method: .post,
            body: CreateCommentBody(body: body)
        )
    }

    // MARK: - Notification Endpoints

    static func notifications(all: Bool = false, page: Int = 1, limit: Int = 20) -> APIEndpoint {
        APIEndpoint(
            path: "/notifications",
            queryItems: [
                URLQueryItem(name: "all", value: all ? "true" : "false"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
    }

    static func markNotificationRead(id: String) -> APIEndpoint {
        APIEndpoint(
            path: "/notifications/threads/\(id)",
            method: .patch
        )
    }

    static var markAllNotificationsRead: APIEndpoint {
        APIEndpoint(
            path: "/notifications",
            method: .put
        )
    }
}

// MARK: - Request Bodies

struct CreateIssueBody: Encodable, Sendable {
    let title: String
    let body: String
}

struct UpdateIssueBody: Encodable, Sendable {
    let title: String?
    let body: String?
    let state: String?
}

struct CreateCommentBody: Encodable, Sendable {
    let body: String
}

struct CreatePullRequestBody: Encodable, Sendable {
    let title: String
    let body: String
    let head: String
    let base: String
}
