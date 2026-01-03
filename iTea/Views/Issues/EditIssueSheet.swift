import SwiftUI
import PhotosUI

struct IssueEditResult {
    let title: String
    let body: String
    let attachmentsToAdd: [PendingAttachment]
    let attachmentsToDelete: [Attachment]
}

struct EditIssueSheet: View {
    let issue: Issue
    let existingAttachments: [Attachment]
    let token: String?
    @Binding var isSaving: Bool
    let onSave: (IssueEditResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedBody: String
    @State private var attachments: [Attachment]
    @State private var attachmentsToDelete: [Attachment] = []
    @State private var pendingAttachments: [PendingAttachment] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false

    init(issue: Issue, existingAttachments: [Attachment] = [], token: String? = nil, isSaving: Binding<Bool>, onSave: @escaping (IssueEditResult) -> Void) {
        self.issue = issue
        self.existingAttachments = existingAttachments
        self.token = token
        self._isSaving = isSaving
        self.onSave = onSave
        self._editedTitle = State(initialValue: issue.title)
        self._editedBody = State(initialValue: issue.body ?? "")
        self._attachments = State(initialValue: existingAttachments)
    }

    private var hasChanges: Bool {
        let titleChanged = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) != issue.title
        let bodyChanged = editedBody != (issue.body ?? "")
        let attachmentsChanged = !attachmentsToDelete.isEmpty || !pendingAttachments.isEmpty
        return titleChanged || bodyChanged || attachmentsChanged
    }

    private var canSave: Bool {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !trimmedTitle.isEmpty
        return hasTitle && hasChanges
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("Issue title", text: $editedTitle)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Body field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $editedBody)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Existing attachments
                    if !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Attachments")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                                ForEach(attachments) { attachment in
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
            .navigationTitle("Edit Issue")
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
                            let result = IssueEditResult(
                                title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
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
        attachments.removeAll { $0.id == attachment.id }
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
    EditIssueSheet(
        issue: Issue(
            id: 1,
            number: 1,
            title: "Test Issue",
            body: "This is the issue body with some content",
            user: User(
                id: 1,
                login: "test",
                fullName: "Test User",
                email: nil,
                avatarUrl: nil,
                isAdmin: false,
                created: nil
            ),
            state: "open",
            labels: nil,
            milestone: nil,
            assignees: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: nil,
            closedAt: nil,
            repository: nil
        ),
        isSaving: .constant(false),
        onSave: { _ in }
    )
}
