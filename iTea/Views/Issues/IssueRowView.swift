import SwiftUI

struct IssueRowView: View {
    let issue: Issue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: issue.isOpen ? "circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(issue.isOpen ? .green : .purple)
                .font(.system(size: 8))
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text("#\(issue.number)")

                    Text("·")

                    Text(issue.user.displayName)

                    if let comments = issue.comments, comments > 0 {
                        Text("·")
                        Image(systemName: "bubble.right")
                        Text("\(comments)")
                    }

                    if issue.hasLabels, let labels = issue.labels {
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
            }
        }
        .padding(.vertical, 2)
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
