import Foundation

struct Comment: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let body: String
    let user: User
    let createdAt: Date?
    let updatedAt: Date?
    let attachments: [Attachment]?

    enum CodingKeys: String, CodingKey {
        case id, body, user, createdAt, updatedAt
        case attachments = "assets"
    }

    var isEdited: Bool {
        guard let created = createdAt, let updated = updatedAt else { return false }
        return updated > created
    }

    var hasAttachments: Bool {
        guard let attachments else { return false }
        return !attachments.isEmpty
    }
}
