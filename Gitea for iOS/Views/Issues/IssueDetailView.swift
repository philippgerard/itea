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
            VStack(alignment: .leading, spacing: 0) {
                issueHeader
                    .padding(.horizontal)
                    .padding(.top)

                if let body = issue.body, !body.isEmpty {
                    issueBody(body)
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
        .navigationTitle("#\(issue.number)")
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadComments()
        }
    }

    private var issueHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(issue.title)
                .font(.title3)
                .fontWeight(.semibold)

            // Status line
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: issue.isOpen ? "circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 8))
                    Text(issue.isOpen ? "Open" : "Closed")
                }
                .font(.subheadline)
                .foregroundStyle(issue.isOpen ? .green : .purple)

                if let date = issue.createdAt {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Labels - inline, subtle
            if issue.hasLabels, let labels = issue.labels {
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

    private func issueBody(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author attribution
            HStack(spacing: 8) {
                UserAvatarView(user: issue.user, size: 24)

                Text(issue.user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let date = issue.createdAt {
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
