import SwiftUI

struct IssueRowView: View {
    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: issue.isOpen ? "circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(issue.isOpen ? .green : .purple)
                    .font(.caption)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text("#\(issue.number)")
                            .foregroundStyle(.secondary)

                        Text("by \(issue.user.displayName)")
                            .foregroundStyle(.secondary)

                        if let comments = issue.comments, comments > 0 {
                            SwiftUI.Label("\(comments)", systemImage: "bubble.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }

            if issue.hasLabels, let labels = issue.labels {
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
}

#Preview {
    IssueRowView(
        issue: Issue(
            id: 1,
            number: 42,
            title: "Fix bug in authentication flow",
            body: "There's a bug in the login process",
            user: User(id: 1, login: "user", fullName: "Test User", email: nil, avatarUrl: nil, isAdmin: false, created: nil),
            state: "open",
            labels: [
                Label(id: 1, name: "bug", color: "d73a4a", description: nil),
                Label(id: 2, name: "high-priority", color: "fbca04", description: nil)
            ],
            milestone: nil,
            assignees: nil,
            comments: 5,
            createdAt: Date(),
            updatedAt: nil,
            closedAt: nil
        )
    )
    .padding()
}
