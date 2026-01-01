import Foundation

struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let login: String
    let fullName: String?
    let email: String?
    let avatarUrl: String?
    let isAdmin: Bool?
    let created: Date?

    var displayName: String {
        if let fullName, !fullName.isEmpty {
            return fullName
        }
        return login
    }

    var avatarURL: URL? {
        guard let avatarUrl else { return nil }
        return URL(string: avatarUrl)
    }
}
