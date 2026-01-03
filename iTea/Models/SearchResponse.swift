import Foundation

/// Response wrapper for repository search endpoint
struct RepositorySearchResponse: Codable, Sendable {
    let data: [Repository]
    let ok: Bool
}
