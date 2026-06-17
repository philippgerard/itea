import Foundation

/// Manages comment CRUD state and logic shared between IssueDetailView and PullRequestDetailView.
/// Both issue and PR comments hit the same Gitea endpoint (`/repos/{owner}/{repo}/issues/{index}/comments`),
/// so a single manager covers both use cases.
@MainActor
@Observable
final class CommentManager {
    // MARK: - State

    var comments: [Comment] = []
    var isLoading = false
    var isSubmitting = false
    var newComment = ""

    // Error state
    var errorMessage: String?
    var showError = false

    // Comment editing state
    var commentToEdit: Comment?
    var commentToDelete: Comment?
    var isEditingComment = false
    var isDeletingComment = false
    var showDeleteConfirmation = false

    // MARK: - Private

    private let fetch: (Int) async throws -> [Comment]
    private let create: (String) async throws -> Comment
    private let edit: (Int, String) async throws -> Comment
    private let delete: (Int) async throws -> Void

    // MARK: - Init

    init(
        fetch: @escaping @MainActor (Int) async throws -> [Comment],
        create: @escaping @MainActor (String) async throws -> Comment,
        edit: @escaping @MainActor (Int, String) async throws -> Comment,
        delete: @escaping @MainActor (Int) async throws -> Void
    ) {
        self.fetch = fetch
        self.create = create
        self.edit = edit
        self.delete = delete
    }

    // MARK: - Loading

    func loadComments() async {
        isLoading = true
        do {
            comments = try await fetch(1)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func refreshComments() async {
        do {
            comments = try await fetch(1)
        } catch {
            // Silently fail on refresh — stale data is still visible
        }
    }

    // MARK: - Submission

    var canSubmit: Bool {
        !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Creates a comment with the given body. Returns the created comment so
    /// callers can perform post-creation work (e.g. uploading attachments).
    func submitComment(body: String) async -> Comment? {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let comment = try await create(body)
            comments.append(comment)
            newComment = ""
            return comment
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return nil
        }
    }

    // MARK: - Editing

    func editCommentBody(_ comment: Comment, newBody: String) async {
        do {
            let updated = try await edit(comment.id, newBody)
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                comments[index] = updated
            }
            commentToEdit = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteComment(_ comment: Comment) async {
        isDeletingComment = true
        defer { isDeletingComment = false }

        do {
            try await delete(comment.id)
            comments.removeAll { $0.id == comment.id }
            commentToDelete = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
