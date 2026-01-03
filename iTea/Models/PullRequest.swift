import Foundation

struct PullRequest: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let user: User
    let state: String
    let labels: [Label]?
    let milestone: Milestone?
    let assignees: [User]?
    let head: PRBranch?
    let base: PRBranch?
    let mergeable: Bool?
    let merged: Bool?
    let mergedAt: Date?
    let mergedBy: User?
    let comments: Int?
    let createdAt: Date?
    let updatedAt: Date?
    /// Repository info - only present in search results
    let repository: IssueRepository?

    var isOpen: Bool {
        state == "open"
    }

    var isMerged: Bool {
        merged ?? false
    }

    var hasLabels: Bool {
        guard let labels else { return false }
        return !labels.isEmpty
    }

    var statusText: String {
        if isMerged {
            return "Merged"
        } else if isOpen {
            return "Open"
        } else {
            return "Closed"
        }
    }
}

struct PRBranch: Codable, Hashable, Sendable {
    let ref: String
    let sha: String?
    let repo: Repository?

    var label: String {
        ref
    }
}
