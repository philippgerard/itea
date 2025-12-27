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
            VStack(alignment: .leading, spacing: 0) {
                prHeader
                    .padding(.horizontal)
                    .padding(.top)

                if let body = pullRequest.body, !body.isEmpty {
                    prBody(body)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }

                Divider()
                    .padding(.top, 20)

                commentsSection
                    .padding(.horizontal)

                addCommentSection
                    .padding()
            }
        }
        .navigationTitle("#\(pullRequest.number)")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadComments()
        }
    }

    private var prHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(pullRequest.title)
                .font(.title3)
                .fontWeight(.semibold)

            // Status and branch info
            HStack(spacing: 8) {
                // Status
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10))
                    Text(statusText)
                }
                .font(.subheadline)
                .foregroundStyle(statusColor)

                if let date = pullRequest.createdAt {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Branch info - subtle
            if let head = pullRequest.head, let base = pullRequest.base {
                HStack(spacing: 4) {
                    Text(head.ref)
                        .foregroundStyle(.blue)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(base.ref)
                        .foregroundStyle(.green)
                }
                .font(.caption)
            }

            // Labels - inline, subtle
            if pullRequest.hasLabels, let labels = pullRequest.labels {
                HStack(spacing: 6) {
                    ForEach(labels) { label in
                        Text(label.name)
                            .font(.caption)
                            .foregroundStyle(label.uiColor)
                    }
                }
            }
        }
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

    private func prBody(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author attribution
            HStack(spacing: 8) {
                UserAvatarView(user: pullRequest.user, size: 24)

                Text(pullRequest.user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let date = pullRequest.createdAt {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Body content
            MarkdownText(content: body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 24)
                    Spacer()
                }
            } else if comments.isEmpty {
                Text("No comments")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                    CommentView(comment: comment)
                    if index < comments.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var addCommentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(alignment: .top, spacing: 10) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($isCommentFocused)

                Button {
                    Task { await submitComment() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(newComment.isEmpty ? Color.gray : Color.accentColor)
                    }
                }
                .disabled(newComment.isEmpty || isSubmitting)
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

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
