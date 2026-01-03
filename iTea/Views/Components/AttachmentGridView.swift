import SwiftUI

/// Displays a grid of uploaded attachments
struct AttachmentGridView: View {
    let attachments: [Attachment]
    let token: String?
    var onAttachmentTap: ((Attachment) -> Void)?

    init(attachments: [Attachment], token: String? = nil, onAttachmentTap: ((Attachment) -> Void)? = nil) {
        self.attachments = attachments
        self.token = token
        self.onAttachmentTap = onAttachmentTap
    }

    var body: some View {
        if attachments.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                ForEach(attachments) { attachment in
                    AttachmentThumbnailView(attachment: attachment, token: token) {
                        onAttachmentTap?(attachment)
                    }
                }
            }
        }
    }
}

/// Displays a horizontal scroll of pending attachments with remove buttons
struct PendingAttachmentRowView: View {
    let attachments: [PendingAttachment]
    var onRemove: ((PendingAttachment) -> Void)?

    var body: some View {
        if attachments.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(attachments) { attachment in
                        PendingAttachmentThumbnailView(attachment: attachment) {
                            onRemove?(attachment)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }
}

/// Full-screen image viewer for attachments
struct AttachmentViewerSheet: View {
    let attachment: Attachment
    let token: String?
    @Environment(\.dismiss) private var dismiss

    init(attachment: Attachment, token: String? = nil) {
        self.attachment = attachment
        self.token = token
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if attachment.isImage {
                    AuthenticatedAsyncImage(
                        url: URL(string: attachment.browserDownloadUrl),
                        token: token
                    ) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } placeholder: {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading image...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: attachment.iconName)
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text(attachment.name)
                            .font(.headline)
                        Text(attachment.formattedSize)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let url = URL(string: attachment.browserDownloadUrl) {
                            Link(destination: url) {
                                SwiftUI.Label("Open in Browser", systemImage: "safari")
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(attachment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if let url = URL(string: attachment.browserDownloadUrl) {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

#Preview("Grid") {
    AttachmentGridView(attachments: [])
}
