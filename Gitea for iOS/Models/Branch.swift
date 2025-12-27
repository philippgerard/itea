import Foundation

struct Branch: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let commit: BranchCommit?
    let protected: Bool?

    var id: String { name }
}

struct BranchCommit: Codable, Hashable, Sendable {
    let id: String?
    let message: String?
}
