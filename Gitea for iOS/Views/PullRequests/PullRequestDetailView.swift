import SwiftUI

struct PullRequestDetailView: View {
    let pullRequest: PullRequest
    let owner: String
    let repo: String
    let pullRequestService: PullRequestService

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
                if let body = pullRequest.body, !body.isEmpty {
                    bodyCard(body)
                }

                // Comments section
                commentsSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
        .navigationTitle("#\(pullRequest.number)")
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
            Text(pullRequest.title)
                .font(.headline)

            // Status row
            HStack(spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10))
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(statusColor)

                Text("·")
                    .foregroundStyle(.quaternary)

                if let date = pullRequest.createdAt {
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Branch info
            if let head = pullRequest.head, let base = pullRequest.base {
                HStack(spacing: 6) {
                    Text(head.ref)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(base.ref)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Labels
            if pullRequest.hasLabels, let labels = pullRequest.labels {
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

    private var statusIcon: String {
        if pullRequest.isMerged {
            return "arrow.triangle.merge"
        } else if pullRequest.isOpen {
            return "arrow.triangle.pull"
        } else {
            return "xmark.circle.fill"
        }
    }

    private var statusText: String {
        if pullRequest.isMerged {
            return "Merged"
        } else if pullRequest.isOpen {
            return "Open"
        } else {
            return "Closed"
        }
    }

    private var statusColor: Color {
        if pullRequest.isMerged {
            return .purple
        } else if pullRequest.isOpen {
            return .green
        } else {
            return .red
        }
    }

    // MARK: - Body Card

    private func bodyCard(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author row
            HStack(spacing: 10) {
                UserAvatarView(user: pullRequest.user, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pullRequest.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let date = pullRequest.createdAt {
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
            comments = try await pullRequestService.getComments(
                owner: owner,
                repo: repo,
                prIndex: pullRequest.number
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
            let comment = try await pullRequestService.createComment(
                owner: owner,
                repo: repo,
                prIndex: pullRequest.number,
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
