import SwiftUI
import PhotosUI

struct CommentEditResult {
    let body: String
    let attachmentsToAdd: [PendingAttachment]
    let attachmentsToDelete: [Attachment]
}

struct EditCommentSheet: View {
    let comment: Comment
    let token: String?
    @Binding var isSaving: Bool
    let onSave: (CommentEditResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedBody: String
    @State private var existingAttachments: [Attachment]
    @State private var attachmentsToDelete: [Attachment] = []
    @State private var pendingAttachments: [PendingAttachment] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false

    init(comment: Comment, token: String? = nil, isSaving: Binding<Bool>, onSave: @escaping (CommentEditResult) -> Void) {
        self.comment = comment
        self.token = token
        self._isSaving = isSaving
        self.onSave = onSave
        self._editedBody = State(initialValue: comment.body)
        self._existingAttachments = State(initialValue: comment.attachments ?? [])
    }

    private var hasChanges: Bool {
        let bodyChanged = editedBody != comment.body
        let attachmentsChanged = !attachmentsToDelete.isEmpty || !pendingAttachments.isEmpty
        return bodyChanged || attachmentsChanged
    }

    private var canSave: Bool {
        let hasContent = !editedBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        !existingAttachments.isEmpty ||
                        !pendingAttachments.isEmpty
        return hasContent && hasChanges
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Text editor
                    TextEditor(text: $editedBody)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Existing attachments
                    if !existingAttachments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Attachments")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                                ForEach(existingAttachments) { attachment in
                                    ZStack(alignment: .topTrailing) {
                                        AttachmentThumbnailView(attachment: attachment, token: token)

                                        Button {
                                            removeExistingAttachment(attachment)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(.white, .red)
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                        }
                    }

                    // Pending new attachments
                    if !pendingAttachments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Attachments")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                                ForEach(pendingAttachments) { attachment in
                                    PendingAttachmentThumbnailView(attachment: attachment) {
                                        pendingAttachments.removeAll { $0.id == attachment.id }
                                    }
                                }
                            }
                        }
                    }

                    // Add attachment button
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .any(of: [.images, .screenshots])
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Add Photos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    if isLoadingPhotos {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading photos...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Save") {
                            let result = CommentEditResult(
                                body: editedBody,
                                attachmentsToAdd: pendingAttachments,
                                attachmentsToDelete: attachmentsToDelete
                            )
                            onSave(result)
                        }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                    }
                }
            }
            .onChange(of: selectedPhotos) { _, newValue in
                if !newValue.isEmpty {
                    Task { await loadSelectedPhotos() }
                }
            }
        }
    }

    private func removeExistingAttachment(_ attachment: Attachment) {
        existingAttachments.removeAll { $0.id == attachment.id }
        attachmentsToDelete.append(attachment)
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
                    await MainActor.run {
                        pendingAttachments.append(pending)
                    }
                }
            } catch {
                continue
            }
        }
    }
}

#Preview {
    EditCommentSheet(
        comment: Comment(
            id: 1,
            body: "This is a test comment",
            user: User(
                id: 1,
                login: "test",
                fullName: "Test User",
                email: nil,
                avatarUrl: nil,
                isAdmin: false,
                created: nil
            ),
            createdAt: Date(),
            updatedAt: nil,
            attachments: nil
        ),
        isSaving: .constant(false),
        onSave: { _ in }
    )
}
