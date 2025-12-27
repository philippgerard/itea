import Foundation

struct Repository: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let owner: User
    let `private`: Bool
    let fork: Bool
    let htmlUrl: String?
    let cloneUrl: String?
    let defaultBranch: String?
    let starsCount: Int?
    let forksCount: Int?
    let openIssuesCount: Int?
    let openPrCounter: Int?
    let createdAt: Date?
    let updatedAt: Date?

    var ownerName: String {
        fullName.split(separator: "/").first.map(String.init) ?? owner.login
    }

    var repoName: String {
        fullName.split(separator: "/").last.map(String.init) ?? name
    }

    var isPrivate: Bool {
        `private`
    }
}
