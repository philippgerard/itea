import Foundation

final class AttachmentService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Issue Attachments

    func getIssueAttachments(owner: String, repo: String, index: Int) async throws -> [Attachment] {
        try await apiClient.request(.issueAttachments(owner: owner, repo: repo, index: index))
    }

    func uploadIssueAttachment(
        owner: String,
        repo: String,
        index: Int,
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws -> Attachment {
        try await apiClient.uploadFile(
            .uploadIssueAttachment(owner: owner, repo: repo, index: index),
            fileData: data,
            fileName: fileName,
            mimeType: mimeType
        )
    }

    func deleteIssueAttachment(owner: String, repo: String, index: Int, attachmentId: Int) async throws {
        try await apiClient.requestWithoutResponse(
            .deleteIssueAttachment(owner: owner, repo: repo, index: index, attachmentId: attachmentId)
        )
    }

    // MARK: - Comment Attachments

    func getCommentAttachments(owner: String, repo: String, commentId: Int) async throws -> [Attachment] {
        try await apiClient.request(.commentAttachments(owner: owner, repo: repo, commentId: commentId))
    }

    func uploadCommentAttachment(
        owner: String,
        repo: String,
        commentId: Int,
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws {
        try await apiClient.uploadFileWithoutResponse(
            .uploadCommentAttachment(owner: owner, repo: repo, commentId: commentId),
            fileData: data,
            fileName: fileName,
            mimeType: mimeType
        )
    }

    func deleteCommentAttachment(owner: String, repo: String, commentId: Int, attachmentId: Int) async throws {
        try await apiClient.requestWithoutResponse(
            .deleteCommentAttachment(owner: owner, repo: repo, commentId: commentId, attachmentId: attachmentId)
        )
    }
}
