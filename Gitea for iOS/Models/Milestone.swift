import Foundation

struct Milestone: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String?
    let state: String?
    let dueOn: Date?
    let openIssues: Int?
    let closedIssues: Int?

    var isOpen: Bool {
        state == "open"
    }

    var progress: Double {
        let open = Double(openIssues ?? 0)
        let closed = Double(closedIssues ?? 0)
        let total = open + closed
        guard total > 0 else { return 0 }
        return closed / total
    }
}
