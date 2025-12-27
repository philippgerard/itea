import Foundation

/// Represents a Gitea Actions workflow run
struct ActionRun: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let displayTitle: String?
    let status: String
    let conclusion: String?
    let headSha: String?
    let headBranch: String?
    let event: String?
    let path: String?
    let runNumber: Int?
    let startedAt: Date?
    let completedAt: Date?
    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase

    /// Display name for the run - extracts workflow name from path
    var displayName: String {
        if let displayTitle, !displayTitle.isEmpty {
            return displayTitle
        }
        // Extract workflow name from path like "claude.yml@refs/heads/main"
        if let path {
            let filename = path.components(separatedBy: "@").first ?? path
            return filename.replacingOccurrences(of: ".yml", with: "")
                .replacingOccurrences(of: ".yaml", with: "")
        }
        return "Workflow #\(runNumber ?? id)"
    }

    /// Short name for the workflow (extracted from path)
    var workflowName: String {
        if let path {
            let filename = path.components(separatedBy: "@").first ?? path
            return filename.replacingOccurrences(of: ".yml", with: "")
                .replacingOccurrences(of: ".yaml", with: "")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
        return "Workflow"
    }

    /// The current state of the run
    var state: ActionRunState {
        // If there's a conclusion, use that
        if let conclusion, !conclusion.isEmpty {
            return ActionRunState(rawValue: conclusion) ?? .unknown
        }
        // Otherwise use status
        return ActionRunState(rawValue: status) ?? .unknown
    }

    /// Whether the run is still in progress
    var isInProgress: Bool {
        status == "running" || status == "waiting" || status == "queued"
    }

    /// Whether the run has completed
    var isCompleted: Bool {
        conclusion != nil && !conclusion!.isEmpty
    }
}

/// Response from the Actions runs endpoint
struct ActionRunsResponse: Codable, Sendable {
    let totalCount: Int
    let workflowRuns: [ActionRun]
    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase
}

/// The possible states of an Actions run
enum ActionRunState: String, Codable, Sendable {
    case waiting
    case queued
    case running
    case success
    case failure
    case cancelled
    case skipped
    case unknown

    /// SF Symbol name for this state
    var iconName: String {
        switch self {
        case .waiting, .queued:
            return "clock.fill"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        case .cancelled:
            return "stop.circle.fill"
        case .skipped:
            return "forward.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// Human-readable description
    var displayText: String {
        switch self {
        case .waiting:
            return "Waiting"
        case .queued:
            return "Queued"
        case .running:
            return "Running"
        case .success:
            return "Passed"
        case .failure:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .skipped:
            return "Skipped"
        case .unknown:
            return "Unknown"
        }
    }
}
