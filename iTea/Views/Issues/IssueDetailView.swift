import SwiftUI

struct IssueDetailView: View {
    let issue: Issue
    let owner: String
    let repo: String
    let issueService: IssueService
    var onIssueUpdated: ((Issue) -> Void)?

    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var currentIssue: Issue
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newComment = ""
    @State private var isSubmitting = false
    @State private var isTogglingState = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var isCommentFocused: Bool

    // Comment editing state
    @State private var commentToEdit: Comment?
    @State private var commentToDelete: Comment?
    @State private var isEditingComment = false
    @State private var isDeletingComment = false
    @State private var showDeleteConfirmation = false

    // Issue editing state
    @State private var showEditIssue = false
    @State private var isEditingIssue = false

    init(issue: Issue, owner: String, repo: String, issueService: IssueService, onIssueUpdated: ((Issue) -> Void)? = nil) {
        self.issue = issue
        self.owner = owner
        self.repo = repo
        self.issueService = issueService
        self.onIssueUpdated = onIssueUpdated
        self._currentIssue = State(initialValue: issue)
    }

    private var canEditIssue: Bool {
        guard let currentUserId = authManager.currentUser?.id else { return false }
        return currentIssue.user.id == currentUserId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                headerCard

                // Body card (if has body)
                if let body = currentIssue.body, !body.isEmpty {
                    bodyCard(body)
                }

                // Comments section
                commentsSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .refreshable {
            await refresh()
        }
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
        .navigationTitle("#\(currentIssue.number)")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if canEditIssue {
                        Button {
                            showEditIssue = true
                        } label: {
                            SwiftUI.Label("Edit", systemImage: "pencil")
                        }

                        Divider()
                    }

                    Button {
                        Task { await toggleIssueState() }
                    } label: {
                        if currentIssue.isOpen {
                            SwiftUI.Label("Close Issue", systemImage: "xmark.circle")
                        } else {
                            SwiftUI.Label("Reopen Issue", systemImage: "arrow.uturn.left.circle")
                        }
                    }
                    .disabled(isTogglingState)
                } label: {
                    if isTogglingState || isEditingIssue {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .alert("Delete Comment?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let comment = commentToDelete {
                    Task { await deleteComment(comment) }
                }
            }
            Button("Cancel", role: .cancel) {
                commentToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(item: $commentToEdit) { comment in
            EditCommentSheet(
                comment: comment,
                isSaving: $isEditingComment
            ) { newBody in
                Task { await editComment(comment, newBody: newBody) }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditIssue) {
            EditIssueSheet(
                issue: currentIssue,
                isSaving: $isEditingIssue
            ) { title, body in
                Task { await editIssue(title: title, body: body) }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await loadComments()
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(currentIssue.title)
                .font(.headline)

            // Status row
            HStack(spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: currentIssue.isOpen ? "circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 8))
                    Text(currentIssue.isOpen ? "Open" : "Closed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(currentIssue.isOpen ? .green : .purple)

                Text("·")
                    .foregroundStyle(.quaternary)

                if let date = currentIssue.createdAt {
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Labels
            if currentIssue.hasLabels, let labels = currentIssue.labels {
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
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Body Card

    private func bodyCard(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author row
            HStack(spacing: 10) {
                UserAvatarView(user: currentIssue.user, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentIssue.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let date = currentIssue.createdAt {
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
        .background(.regularMaterial)
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
                    CommentView(
                        comment: comment,
                        currentUserId: authManager.currentUser?.id,
                        onEdit: { commentToEdit = $0 },
                        onDelete: { commentToDelete = $0; showDeleteConfirmation = true }
                    )
                }
            }
        }
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add a comment...", text: $newComment, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isCommentFocused)

            Button {
                Task { await submitComment() }
            } label: {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            .animation(.easeInOut(duration: 0.15), value: newComment.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 3, y: -2)
        }
    }

    // MARK: - Actions

    private func refresh() async {
        async let issueTask: () = refreshIssue()
        async let commentsTask: () = refreshComments()
        _ = await (issueTask, commentsTask)
    }

    private func refreshComments() async {
        do {
            comments = try await issueService.getComments(
                owner: owner,
                repo: repo,
                issueIndex: currentIssue.number
            )
        } catch {
            // Silently fail on refresh - user can pull again
        }
    }

    private func refreshIssue() async {
        do {
            let updatedIssue = try await issueService.getIssue(
                owner: owner,
                repo: repo,
                index: currentIssue.number
            )
            currentIssue = updatedIssue
            onIssueUpdated?(updatedIssue)
        } catch {
            // Silently fail on refresh - data is still shown from before
        }
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await issueService.getComments(
                owner: owner,
                repo: repo,
                issueIndex: currentIssue.number
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
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
                issueIndex: currentIssue.number,
                body: newComment
            )
            comments.append(comment)
            newComment = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }

    private func toggleIssueState() async {
        isTogglingState = true

        do {
            let updatedIssue: Issue
            if currentIssue.isOpen {
                updatedIssue = try await issueService.closeIssue(
                    owner: owner,
                    repo: repo,
                    index: currentIssue.number
                )
            } else {
                updatedIssue = try await issueService.reopenIssue(
                    owner: owner,
                    repo: repo,
                    index: currentIssue.number
                )
            }
            currentIssue = updatedIssue
            onIssueUpdated?(updatedIssue)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isTogglingState = false
    }

    private func editComment(_ comment: Comment, newBody: String) async {
        isEditingComment = true

        do {
            let updatedComment = try await issueService.editComment(
                owner: owner,
                repo: repo,
                commentId: comment.id,
                body: newBody
            )
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                comments[index] = updatedComment
            }
            commentToEdit = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isEditingComment = false
    }

    private func deleteComment(_ comment: Comment) async {
        isDeletingComment = true

        do {
            try await issueService.deleteComment(
                owner: owner,
                repo: repo,
                commentId: comment.id
            )
            comments.removeAll { $0.id == comment.id }
            commentToDelete = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isDeletingComment = false
    }

    private func editIssue(title: String, body: String) async {
        isEditingIssue = true

        do {
            let updatedIssue = try await issueService.updateIssue(
                owner: owner,
                repo: repo,
                index: currentIssue.number,
                title: title,
                body: body
            )
            currentIssue = updatedIssue
            onIssueUpdated?(updatedIssue)
            showEditIssue = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isEditingIssue = false
    }
}
