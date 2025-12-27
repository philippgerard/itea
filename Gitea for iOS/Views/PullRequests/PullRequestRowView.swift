import SwiftUI

struct PullRequestRowView: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                statusIcon
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pullRequest.title)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text("#\(pullRequest.number)")
                            .foregroundStyle(.secondary)

                        Text("by \(pullRequest.user.displayName)")
                            .foregroundStyle(.secondary)

                        if let comments = pullRequest.comments, comments > 0 {
                            SwiftUI.Label("\(comments)", systemImage: "bubble.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)

                    if let head = pullRequest.head, let base = pullRequest.base {
                        HStack(spacing: 4) {
                            Text(head.ref)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(base.ref)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }

            if pullRequest.hasLabels, let labels = pullRequest.labels {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(labels) { label in
                            LabelTagView(label: label)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
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
        .font(.caption)
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
            updatedAt: nil
        )
    )
    .padding()
}
