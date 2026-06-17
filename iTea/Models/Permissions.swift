import Foundation

/// Repository-level permissions returned by the Gitea API.
/// Used to determine whether the current user can modify others' content.
struct Permissions: Codable, Hashable, Sendable {
    let admin: Bool?
    let push: Bool?
    let pull: Bool?

    /// True if the user can edit/delete content they didn't create
    /// (repo admin or write/push access).
    var canModifyOthers: Bool {
        admin == true || push == true
    }
}
