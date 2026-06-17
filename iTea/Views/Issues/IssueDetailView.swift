import SwiftUI
import PhotosUI

struct IssueDetailView: View {
    let issue: Issue
    let owner: String
    let repo: String
    let issueService: IssueService
    let attachmentService: AttachmentService
    var canModifyOthers: Bool
    var onIssueUpdated: ((Issue) -> Void)?

    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var currentIssue: Issue
    @State private var attachments: [Attachment] = []
    @State private var isTogglingState = false
    @State private var commentManager: CommentManager
    @FocusState private var isCommentFocused: Bool
    @State private var stateToggleTrigger = 0

    // Issue editing state
    @State private var showEditIssue = false
    @State private var isEditingIssue = false

    // Attachment viewer
    @State private var selectedAttachment: Attachment?

    // Comment attachments
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var pendingCommentAttachments: [PendingAttachment] = []
    @State private var isLoadingPhotos = false

    init(issue: Issue, owner: String, repo: String, issueService: IssueService, attachmentService: AttachmentService, canModifyOthers: Bool = false, onIssueUpdated: ((Issue) -> Void)? = nil) {
        self.issue = issue
        self.owner = owner
        self.repo = repo
        self.issueService = issueService
        self.attachmentService = attachmentService
        self.canModifyOthers = canModifyOthers
        self.onIssueUpdated = onIssueUpdated
        self._currentIssue = State(initialValue: issue)

        let number = issue.number
        self._commentManager = State(initialValue: CommentManager(
            fetch: { [issueService, owner, repo, number] page in
                try await issueService.getComments(owner: owner, repo: repo, issueIndex: number, page: page)
            },
            create: { [issueService, owner, repo, number] body in
                try await issueService.createComment(owner: owner, repo: repo, issueIndex: number, body: body)
            },
            edit: { [issueService, owner, repo] commentId, body in
                try await issueService.editComment(owner: owner, repo: repo, commentId: commentId, body: body)
            },
            delete: { [issueService, owner, repo] commentId in
                try await issueService.deleteComment(owner: owner, repo: repo, commentId: commentId)
            }
        ))
    }

    private var canEditIssue: Bool {
        guard let currentUserId = authManager.currentUser?.id else { return false }
        return currentIssue.user.id == currentUserId || canModifyOthers
    }

    var body: some View {
        @Bindable var commentManager = commentManager

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
        .sensoryFeedback(.impact(weight: .medium), trigger: stateToggleTrigger)
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
                .accessibilityLabel("More Options")
            }
        }
        .alert("Error", isPresented: $commentManager.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(commentManager.errorMessage ?? "Unknown error")
        }
        .alert("Delete Comment?", isPresented: $commentManager.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let comment = commentManager.commentToDelete {
                    Task { await commentManager.deleteComment(comment) }
                }
            }
            Button("Cancel", role: .cancel) {
                commentManager.commentToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(item: $commentManager.commentToEdit) { comment in
            EditCommentSheet(
                comment: comment,
                token: authManager.getAccessToken(),
                isSaving: $commentManager.isEditingComment
            ) { result in
                Task { await editComment(comment, result: result) }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditIssue) {
            EditIssueSheet(
                issue: currentIssue,
                existingAttachments: attachments,
                token: authManager.getAccessToken(),
                isSaving: $isEditingIssue
            ) { result in
                Task { await editIssue(result: result) }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            async let commentsTask: () = self.commentManager.loadComments()
            async let attachmentsTask: () = loadAttachments()
            _ = await (commentsTask, attachmentsTask)
        }
        .sheet(item: $selectedAttachment) { attachment in
            AttachmentViewerSheet(attachment: attachment, token: authManager.getAccessToken())
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

            // Attachments
            if !attachments.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                Text("Attachments")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                AttachmentGridView(attachments: attachments, token: authManager.getAccessToken()) { attachment in
                    selectedAttachment = attachment
                }
            }
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
            if !commentManager.comments.isEmpty || commentManager.isLoading {
                Text("Comments")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 8)
            }

            if commentManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else if commentManager.comments.isEmpty {
                // Empty state - subtle
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(commentManager.comments) { comment in
                    CommentView(
                        comment: comment,
                        currentUserId: authManager.currentUser?.id,
                        token: authManager.getAccessToken(),
                        canModifyOthers: canModifyOthers,
                        onEdit: { commentManager.commentToEdit = $0 },
                        onDelete: { commentManager.commentToDelete = $0; commentManager.showDeleteConfirmation = true },
                        onAttachmentTap: { selectedAttachment = $0 }
                    )
                }
            }
        }
    }

    // MARK: - Comment Input

    private var canSubmitComment: Bool {
        commentManager.canSubmit || !pendingCommentAttachments.isEmpty
    }

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            // Pending attachments row
            if !pendingCommentAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(pendingCommentAttachments) { attachment in
                            PendingAttachmentThumbnailView(attachment: attachment) {
                                pendingCommentAttachments.removeAll { $0.id == attachment.id }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            // Loading indicator
            if isLoadingPhotos {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading photos...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Input row
            HStack(alignment: .center, spacing: 8) {
                // Attachment button
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 5,
                    matching: .any(of: [.images, .screenshots])
                ) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Add Attachment")
                .buttonStyle(.plain)

                TextField("Add a comment...", text: $commentManager.newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .focused($isCommentFocused)

                Button {
                    Task { await submitComment() }
                } label: {
                    if commentManager.isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(canSubmitComment ? Color.accentColor : Color.secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSubmitComment || commentManager.isSubmitting)
                .animation(.easeInOut(duration: 0.15), value: canSubmitComment)
                .accessibilityLabel("Send Comment")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 3, y: -2)
        }
        .onChange(of: selectedPhotos) { _, newValue in
            if !newValue.isEmpty {
                Task { await loadSelectedPhotos() }
            }
        }
    }

    // MARK: - Actions

    private func refresh() async {
        async let issueTask: () = refreshIssue()
        async let commentsTask: () = commentManager.refreshComments()
        async let attachmentsTask: () = loadAttachments()
        _ = await (issueTask, commentsTask, attachmentsTask)
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

    private func loadAttachments() async {
        do {
            attachments = try await attachmentService.getIssueAttachments(
                owner: owner,
                repo: repo,
                index: currentIssue.number
            )
        } catch {
            // Silently fail - attachments are supplementary
        }
    }

    private func submitComment() async {
        isCommentFocused = false

        // Use a placeholder body if only attachments are provided
        let trimmed = commentManager.newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        let commentBody = trimmed.isEmpty
            ? (pendingCommentAttachments.isEmpty ? "" : " ")
            : commentManager.newComment

        guard !commentBody.isEmpty else { return }

        if let comment = await commentManager.submitComment(body: commentBody) {
            // Upload attachments if any
            for attachment in pendingCommentAttachments {
                try? await attachmentService.uploadCommentAttachment(
                    owner: owner,
                    repo: repo,
                    commentId: comment.id,
                    data: attachment.data,
                    fileName: attachment.fileName,
                    mimeType: attachment.mimeType
                )
            }

            // Reload comments to get the updated comment with attachments
            await commentManager.refreshComments()
            pendingCommentAttachments = []
        }
    }

    private func loadSelectedPhotos() async {
        guard !selectedPhotos.isEmpty else { return }

        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            selectedPhotos = []
        }

        for item in selectedPhotos {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    // Determine file name and type
                    let fileName: String
                    let mimeType: String

                    if let contentType = item.supportedContentTypes.first {
                        let ext = contentType.preferredFilenameExtension ?? "jpg"
                        fileName = "image_\(UUID().uuidString.prefix(8)).\(ext)"
                        mimeType = contentType.preferredMIMEType ?? "image/jpeg"
                    } else {
                        fileName = "image_\(UUID().uuidString.prefix(8)).jpg"
                        mimeType = "image/jpeg"
                    }

                    // Create thumbnail
                    let thumbnailData: Data?
                    if let uiImage = UIImage(data: data) {
                        let maxSize: CGFloat = 200
                        let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
                        let newSize = CGSize(
                            width: uiImage.size.width * scale,
                            height: uiImage.size.height * scale
                        )
                        let renderer = UIGraphicsImageRenderer(size: newSize)
                        let thumbnail = renderer.image { _ in
                            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                        }
                        thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
                    } else {
                        thumbnailData = nil
                    }

                    let pending = PendingAttachment(
                        data: data,
                        fileName: fileName,
                        mimeType: mimeType,
                        thumbnail: thumbnailData
                    )
                    pendingCommentAttachments.append(pending)
                }
            } catch {
                // Skip failed items
                continue
            }
        }
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
            commentManager.errorMessage = error.localizedDescription
            commentManager.showError = true
        }

        isTogglingState = false
    }

    private func editComment(_ comment: Comment, result: CommentEditResult) async {
        commentManager.isEditingComment = true
        defer { commentManager.isEditingComment = false }

        do {
            // Delete attachments marked for removal
            for attachment in result.attachmentsToDelete {
                try await attachmentService.deleteCommentAttachment(
                    owner: owner,
                    repo: repo,
                    commentId: comment.id,
                    attachmentId: attachment.id
                )
            }

            // Update comment body only if it changed
            if result.body != comment.body {
                try await commentManager.editCommentBody(comment, newBody: result.body)
            } else {
                commentManager.commentToEdit = nil
            }

            // Upload new attachments
            for attachment in result.attachmentsToAdd {
                try await attachmentService.uploadCommentAttachment(
                    owner: owner,
                    repo: repo,
                    commentId: comment.id,
                    data: attachment.data,
                    fileName: attachment.fileName,
                    mimeType: attachment.mimeType
                )
            }

            // Refresh comments to get updated data
            await commentManager.refreshComments()
        } catch {
            commentManager.errorMessage = error.localizedDescription
            commentManager.showError = true
        }
    }

    private func editIssue(result: IssueEditResult) async {
        isEditingIssue = true

        do {
            // Delete attachments marked for removal
            for attachment in result.attachmentsToDelete {
                try await attachmentService.deleteIssueAttachment(
                    owner: owner,
                    repo: repo,
                    index: currentIssue.number,
                    attachmentId: attachment.id
                )
            }

            // Update issue title/body only if changed
            let titleChanged = result.title != currentIssue.title
            let bodyChanged = result.body != (currentIssue.body ?? "")
            if titleChanged || bodyChanged {
                let updatedIssue = try await issueService.updateIssue(
                    owner: owner,
                    repo: repo,
                    index: currentIssue.number,
                    title: result.title,
                    body: result.body
                )
            currentIssue = updatedIssue
            onIssueUpdated?(updatedIssue)
            stateToggleTrigger += 1
            }

            // Upload new attachments
            for attachment in result.attachmentsToAdd {
                _ = try await attachmentService.uploadIssueAttachment(
                    owner: owner,
                    repo: repo,
                    index: currentIssue.number,
                    data: attachment.data,
                    fileName: attachment.fileName,
                    mimeType: attachment.mimeType
                )
            }

            // Refresh attachments to get updated data
            await loadAttachments()
            showEditIssue = false
        } catch {
            commentManager.errorMessage = error.localizedDescription
            commentManager.showError = true
        }

        isEditingIssue = false
    }
}
