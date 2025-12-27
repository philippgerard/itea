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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                prHeader
                branchInfo
                prBody
                Divider()
                commentsSection
                addCommentSection
            }
            .padding()
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
        VStack(alignment: .leading, spacing: 12) {
            Text(pullRequest.title)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                statusBadge

                Text("#\(pullRequest.number)")
                    .foregroundStyle(.secondary)

                Spacer()

                if let date = pullRequest.createdAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            if pullRequest.isMerged {
                Image(systemName: "arrow.triangle.merge")
                Text("Merged")
            } else if pullRequest.isOpen {
                Image(systemName: "arrow.triangle.pull")
                Text("Open")
            } else {
                Image(systemName: "xmark.circle.fill")
                Text("Closed")
            }
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(statusColor)
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

    private var branchInfo: some View {
        HStack(spacing: 8) {
            if let head = pullRequest.head {
                Text(head.ref)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            if let base = pullRequest.base {
                Text(base.ref)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Spacer()
        }
    }

    private var prBody: some View {
        Group {
            if let body = pullRequest.body, !body.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
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
                    }

                    MarkdownText(content: body)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: .infinity)
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
