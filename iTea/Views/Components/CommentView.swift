import SwiftUI

struct CommentView: View {
    let comment: Comment
    let currentUserId: Int?
    let token: String?
    var onEdit: ((Comment) -> Void)?
    var onDelete: ((Comment) -> Void)?
    var onAttachmentTap: ((Attachment) -> Void)?

    init(comment: Comment, currentUserId: Int? = nil, token: String? = nil, onEdit: ((Comment) -> Void)? = nil, onDelete: ((Comment) -> Void)? = nil, onAttachmentTap: ((Attachment) -> Void)? = nil) {
        self.comment = comment
        self.currentUserId = currentUserId
        self.token = token
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onAttachmentTap = onAttachmentTap
    }

    private var canModify: Bool {
        guard let currentUserId else { return false }
        return comment.user.id == currentUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author row
            HStack(spacing: 10) {
                UserAvatarView(user: comment.user, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        if let date = comment.createdAt {
                            Text(date, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if comment.isEdited {
                            Text("· edited")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                // Edit menu button (only for own comments)
                if canModify {
                    Menu {
                        Button {
                            onEdit?(comment)
                        } label: {
                            SwiftUI.Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            onDelete?(comment)
                        } label: {
                            SwiftUI.Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                }
            }

            // Content
            MarkdownText(content: comment.body)

            // Attachments
            if comment.hasAttachments, let attachments = comment.attachments {
                Divider()
                    .padding(.vertical, 4)

                AttachmentGridView(attachments: attachments, token: token) { attachment in
                    onAttachmentTap?(attachment)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            if canModify {
                Button {
                    onEdit?(comment)
                } label: {
                    SwiftUI.Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete?(comment)
                } label: {
                    SwiftUI.Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
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
                    updatedAt: nil,
                    attachments: nil
                )
            )

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
                    updatedAt: Date(),
                    attachments: nil
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
