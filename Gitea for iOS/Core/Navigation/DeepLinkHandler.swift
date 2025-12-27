import SwiftUI

/// Represents a pending deep link action
enum DeepLinkAction: Equatable {
    case createPullRequest(owner: String, repo: String, base: String, head: String, title: String?, body: String?)
    case viewIssue(owner: String, repo: String, number: Int)
    case viewPullRequest(owner: String, repo: String, number: Int)
}

/// Handles deep links and URL navigation throughout the app
@MainActor
@Observable
final class DeepLinkHandler {
    var pendingAction: DeepLinkAction?

    /// Attempts to handle a URL, returning true if it was handled
    func handleURL(_ url: URL, serverURL: URL?) -> Bool {
        // Check if URL belongs to the configured server
        guard let serverURL,
              GiteaURLParser.belongsToServer(url, serverURL: serverURL) else {
            return false
        }

        // Try to parse as compare URL (PR creation)
        if GiteaURLParser.isCompareURL(url),
           let prURL = GiteaURLParser.parseCompareURL(url) {
            pendingAction = .createPullRequest(
                owner: prURL.owner,
                repo: prURL.repo,
                base: prURL.baseBranch,
                head: prURL.headBranch,
                title: prURL.title,
                body: prURL.body
            )
            return true
        }

        // Try to parse as issue URL
        if GiteaURLParser.isIssueURL(url),
           let parsed = GiteaURLParser.parseIssueOrPRNumber(url) {
            pendingAction = .viewIssue(
                owner: parsed.owner,
                repo: parsed.repo,
                number: parsed.number
            )
            return true
        }

        // Try to parse as PR URL
        if GiteaURLParser.isPullRequestURL(url),
           let parsed = GiteaURLParser.parseIssueOrPRNumber(url) {
            pendingAction = .viewPullRequest(
                owner: parsed.owner,
                repo: parsed.repo,
                number: parsed.number
            )
            return true
        }

        return false
    }

    /// Clears the pending action after it's been handled
    func clearPendingAction() {
        pendingAction = nil
    }
}
