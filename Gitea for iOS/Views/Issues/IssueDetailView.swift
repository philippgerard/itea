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
    @FocusState private var isCommentFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                headerCard

                // Body card (if has body)
                if let body = issue.body, !body.isEmpty {
                    bodyCard(body)
                }

                // Comments section
                commentsSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 100) // Space for input
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
        .navigationTitle("#\(issue.number)")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadComments()
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(issue.title)
                .font(.headline)

            // Status row
            HStack(spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: issue.isOpen ? "circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 8))
                    Text(issue.isOpen ? "Open" : "Closed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(issue.isOpen ? .green : .purple)

                Text("·")
                    .foregroundStyle(.quaternary)

                if let date = issue.createdAt {
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Labels
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Body Card

    private func bodyCard(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author row
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

                Spacer()
            }

            // Content
            MarkdownText(content: body)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            if !comments.isEmpty || isLoading {
                Text("Comments")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 8)
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else if comments.isEmpty {
                // Empty state - subtle
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(comments) { comment in
                    CommentView(comment: comment)
                }
            }
        }
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .focused($isCommentFocused)

                Button {
                    Task { await submitComment() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                        }
                    }
                    .foregroundStyle(newComment.isEmpty ? Color(.systemGray4) : Color.accentColor)
                }
                .disabled(newComment.isEmpty || isSubmitting)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    // MARK: - Actions

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
        isCommentFocused = false

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
