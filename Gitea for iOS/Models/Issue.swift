import Foundation

struct Issue: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let user: User
    let state: String
    let labels: [Label]?
    let milestone: Milestone?
    let assignees: [User]?
    let comments: Int?
    let createdAt: Date?
    let updatedAt: Date?
    let closedAt: Date?

    var isOpen: Bool {
        state == "open"
    }

    var hasLabels: Bool {
        guard let labels else { return false }
        return !labels.isEmpty
    }

    var hasAssignees: Bool {
        guard let assignees else { return false }
        return !assignees.isEmpty
    }
}
