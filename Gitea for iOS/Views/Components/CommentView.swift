import SwiftUI

struct CommentView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author line: avatar, name, time - all subtle
            HStack(spacing: 8) {
                UserAvatarView(user: comment.user, size: 24)

                Text(comment.user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("·")
                    .foregroundStyle(.tertiary)

                if let date = comment.createdAt {
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if comment.isEdited {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("edited")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }

            // Content: just the markdown, no container
            MarkdownText(content: comment.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 0) {
        CommentView(
            comment: Comment(
                id: 1,
                body: "This is a short comment.",
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
        Divider()
        CommentView(
            comment: Comment(
                id: 2,
                body: """
                This is a longer comment with **markdown**.

                ## A heading

                - List item one
                - List item two

                And some `inline code` too.
                """,
                user: User(
                    id: 2,
                    login: "another",
                    fullName: "Another Person",
                    email: nil,
                    avatarUrl: nil,
                    isAdmin: false,
                    created: nil
                ),
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date()
            )
        )
    }
    .padding(.horizontal)
}
