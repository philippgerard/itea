import SwiftUI

struct CommentView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                UserAvatarView(user: comment.user, size: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let date = comment.createdAt {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if comment.isEdited {
                    Text("edited")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            MarkdownText(content: comment.body)
                .font(.body)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CommentView(
        comment: Comment(
            id: 1,
            body: "This is a test comment with some content to display.",
            user: User(
                id: 1,
                login: "testuser",
                fullName: "Test User",
                email: nil,
                avatarUrl: nil,
                isAdmin: false,
                created: nil
            ),
            createdAt: Date(),
            updatedAt: nil
        )
    )
    .padding()
}
