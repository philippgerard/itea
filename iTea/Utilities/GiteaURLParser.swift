import Foundation

/// Represents a parsed Gitea PR creation URL
struct GiteaPullRequestURL {
    let owner: String
    let repo: String
    let baseBranch: String
    let headBranch: String
    let title: String?
    let body: String?
}

/// Parses Gitea URLs and extracts relevant information
struct GiteaURLParser {

    /// Checks if a URL is a Gitea compare/PR creation URL
    /// Format: https://gitea.example.com/owner/repo/compare/base...head?quick_pull=1&title=...&body=...
    static func isCompareURL(_ url: URL) -> Bool {
        let path = url.path
        return path.contains("/compare/") && path.contains("...")
    }

    /// Checks if a URL belongs to the given Gitea server
    static func belongsToServer(_ url: URL, serverURL: URL) -> Bool {
        return url.host == serverURL.host
    }

    /// Parses a compare URL into its components
    /// - Parameter url: The compare URL to parse
    /// - Returns: A GiteaPullRequestURL if parsing succeeds, nil otherwise
    static func parseCompareURL(_ url: URL) -> GiteaPullRequestURL? {
        let path = url.path

        // Path format: /owner/repo/compare/base...head
        // Note: branch names can contain "/" so we can't just split by "/"
        // We need to find "/compare/" and extract everything after it
        guard let compareRange = path.range(of: "/compare/") else {
            return nil
        }

        // Get owner/repo from the part before /compare/
        let ownerRepoPath = String(path[..<compareRange.lowerBound])
        let ownerRepoComponents = ownerRepoPath.split(separator: "/").map(String.init)
        guard ownerRepoComponents.count >= 2 else {
            return nil
        }

        let owner = ownerRepoComponents[0]
        let repo = ownerRepoComponents[1]

        // Get everything after /compare/ (this is base...head, where head may contain "/")
        let branchComparison = String(path[compareRange.upperBound...])

        // Handle "base...head" format (3 dots) or "base..head" (2 dots)
        let baseBranch: String
        let headBranch: String

        if branchComparison.contains("...") {
            let parts = branchComparison.components(separatedBy: "...")
            guard parts.count == 2 else { return nil }
            baseBranch = parts[0]
            headBranch = parts[1]
        } else if branchComparison.contains("..") {
            let parts = branchComparison.components(separatedBy: "..")
            guard parts.count == 2 else { return nil }
            baseBranch = parts[0]
            headBranch = parts[1]
        } else {
            return nil
        }

        // Parse query parameters (URLComponents automatically decodes percent-encoding)
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let title = queryItems?.first(where: { $0.name == "title" })?.value?
            .removingPercentEncoding ?? queryItems?.first(where: { $0.name == "title" })?.value
        let body = queryItems?.first(where: { $0.name == "body" })?.value?
            .removingPercentEncoding ?? queryItems?.first(where: { $0.name == "body" })?.value

        return GiteaPullRequestURL(
            owner: owner,
            repo: repo,
            baseBranch: baseBranch,
            headBranch: headBranch,
            title: title,
            body: body
        )
    }

    /// Checks if a URL is an issue URL
    /// Format: https://gitea.example.com/owner/repo/issues/123
    static func isIssueURL(_ url: URL) -> Bool {
        let path = url.path
        let components = path.split(separator: "/")
        return components.count >= 4 && components[2] == "issues"
    }

    /// Checks if a URL is a pull request URL
    /// Format: https://gitea.example.com/owner/repo/pulls/123
    static func isPullRequestURL(_ url: URL) -> Bool {
        let path = url.path
        let components = path.split(separator: "/")
        return components.count >= 4 && components[2] == "pulls"
    }

    /// Parses an issue or PR number from a URL
    static func parseIssueOrPRNumber(_ url: URL) -> (owner: String, repo: String, number: Int)? {
        let path = url.path
        let components = path.split(separator: "/").map(String.init)

        guard components.count >= 4,
              (components[2] == "issues" || components[2] == "pulls"),
              let number = Int(components[3]) else {
            return nil
        }

        return (owner: components[0], repo: components[1], number: number)
    }
}
