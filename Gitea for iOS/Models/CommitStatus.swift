import Foundation

/// Represents an individual CI check status
struct CommitStatus: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let status: String
    let context: String
    let description: String?
    let targetUrl: String?
    let createdAt: Date?
    let updatedAt: Date?
    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase

    /// The state of this check
    var state: CommitStatusState {
        CommitStatusState(rawValue: status) ?? .unknown
    }
}

/// Represents the combined status of all CI checks for a commit
struct CombinedStatus: Codable, Hashable, Sendable {
    let state: String
    let sha: String
    let totalCount: Int
    let statuses: [CommitStatus]
    let commitUrl: String?
    let url: String?
    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase

    /// The overall state of all checks
    var overallState: CommitStatusState {
        CommitStatusState(rawValue: state) ?? .unknown
    }

    /// Whether all checks have passed
    var allPassed: Bool {
        overallState == .success
    }

    /// Whether any checks are still running
    var hasPending: Bool {
        statuses.contains { $0.state == .pending }
    }

    /// Whether any checks have failed
    var hasFailed: Bool {
        statuses.contains { $0.state == .failure || $0.state == .error }
    }
}

/// The possible states of a CI check
enum CommitStatusState: String, Codable, Sendable {
    case pending
    case success
    case error
    case failure
    case warning
    case unknown

    /// SF Symbol name for this state
    var iconName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .success:
            return "checkmark.circle.fill"
        case .error, .failure:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// Display color for this state
    var displayColor: String {
        switch self {
        case .pending:
            return "yellow"
        case .success:
            return "green"
        case .error, .failure:
            return "red"
        case .warning:
            return "orange"
        case .unknown:
            return "gray"
        }
    }

    /// Human-readable description
    var displayText: String {
        switch self {
        case .pending:
            return "Pending"
        case .success:
            return "Passed"
        case .error:
            return "Error"
        case .failure:
            return "Failed"
        case .warning:
            return "Warning"
        case .unknown:
            return "Unknown"
        }
    }
}
