import SwiftUI

struct PullRequestRowView: View {
    let pullRequest: PullRequest

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            statusIcon
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(pullRequest.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("#\(pullRequest.number)")

                    Text("·")

                    Text(pullRequest.user.displayName)

                    if let comments = pullRequest.comments, comments > 0 {
                        Text("·")
                        Image(systemName: "bubble.right")
                        Text("\(comments)")
                    }

                    if pullRequest.hasLabels, let labels = pullRequest.labels {
                        ForEach(labels.prefix(3)) { label in
                            Text("·")
                            Text(label.name)
                                .foregroundStyle(label.uiColor)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if let head = pullRequest.head, let base = pullRequest.base {
                    HStack(spacing: 4) {
                        Text(head.ref)
                            .foregroundStyle(.blue)
                        Image(systemName: "arrow.right")
                        Text(base.ref)
                            .foregroundStyle(.green)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusIcon: some View {
        Group {
            if pullRequest.isMerged {
                Image(systemName: "arrow.triangle.merge")
                    .foregroundStyle(.purple)
            } else if pullRequest.isOpen {
                Image(systemName: "arrow.triangle.pull")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.system(size: 10))
    }
}

#Preview {
    PullRequestRowView(
        pullRequest: PullRequest(
            id: 1,
            number: 42,
            title: "Add new feature for authentication",
            body: "This PR adds OAuth support",
            user: User(id: 1, login: "user", fullName: "Test User", email: nil, avatarUrl: nil, isAdmin: false, created: nil),
            state: "open",
            labels: [
                Label(id: 1, name: "enhancement", color: "a2eeef", description: nil)
            ],
            milestone: nil,
            assignees: nil,
            head: PRBranch(ref: "feature/oauth", sha: nil, repo: nil),
            base: PRBranch(ref: "main", sha: nil, repo: nil),
            mergeable: true,
            merged: false,
            mergedAt: nil,
            mergedBy: nil,
            comments: 3,
            createdAt: Date(),
            updatedAt: nil,
            repository: nil
        )
    )
    .padding()
}
