import Foundation

struct Comment: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let body: String
    let user: User
    let createdAt: Date?
    let updatedAt: Date?

    var isEdited: Bool {
        guard let created = createdAt, let updated = updatedAt else { return false }
        return updated > created
    }
}
