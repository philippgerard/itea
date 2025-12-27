import SwiftUI

struct IssueDetailView: View {
    let issue: Issue
    let owner: String
    let repo: String
    let issueService: IssueService

    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newComment = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                issueHeader
                issueBody
                Divider()
                commentsSection
                addCommentSection
            }
            .padding()
        }
        .navigationTitle("#\(issue.number)")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadComments()
        }
    }

    private var issueHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(issue.title)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                SwiftUI.Label(
                    issue.isOpen ? "Open" : "Closed",
                    systemImage: issue.isOpen ? "circle.fill" : "checkmark.circle.fill"
                )
                .foregroundStyle(issue.isOpen ? .green : .purple)
                .font(.subheadline)
                .fontWeight(.medium)

                Text("#\(issue.number)")
                    .foregroundStyle(.secondary)

                Spacer()

                if let date = issue.createdAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if issue.hasLabels, let labels = issue.labels {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(labels) { label in
                            LabelTagView(label: label)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var issueBody: some View {
        Group {
            if let body = issue.body, !body.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        UserAvatarView(user: issue.user, size: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.user.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if let date = issue.createdAt {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    MarkdownText(content: body)
                        .font(.body)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if comments.isEmpty {
                Text("No comments yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(comments) { comment in
                    CommentView(comment: comment)
                }
            }
        }
    }

    private var addCommentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a comment")
                .font(.headline)

            TextEditor(text: $newComment)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )

            Button {
                Task { await submitComment() }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(newComment.isEmpty ? Color.secondary : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(newComment.isEmpty || isSubmitting)
        }
    }

    private func loadComments() async {
        isLoading = true

        do {
            comments = try await issueService.getComments(
                owner: owner,
                repo: repo,
                issueIndex: issue.number
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func submitComment() async {
        isSubmitting = true

        do {
            let comment = try await issueService.createComment(
                owner: owner,
                repo: repo,
                issueIndex: issue.number,
                body: newComment
            )
            comments.append(comment)
            newComment = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
