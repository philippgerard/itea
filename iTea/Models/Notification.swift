import Foundation

struct GiteaNotification: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let subject: NotificationSubject
    let repository: Repository
    let unread: Bool
    let pinned: Bool?
    let updatedAt: Date?
}

struct NotificationSubject: Codable, Hashable, Sendable {
    let title: String
    let url: String?
    let latestCommentUrl: String?
    let type: String
    let state: String?

    var typeDisplay: String {
        switch type.lowercased() {
        case "issue":
            return "Issue"
        case "pull":
            return "Pull Request"
        case "commit":
            return "Commit"
        case "repository":
            return "Repository"
        default:
            return type
        }
    }

    var issueOrPRNumber: Int? {
        guard let url else { return nil }
        // URL format: .../issues/123 or .../pulls/123
        let components = url.split(separator: "/")
        guard let last = components.last, let number = Int(last) else { return nil }
        return number
    }
}
