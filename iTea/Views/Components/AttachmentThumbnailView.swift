import SwiftUI

/// Displays a thumbnail for a pending attachment (before upload)
struct PendingAttachmentThumbnailView: View {
    let attachment: PendingAttachment
    var onRemove: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if attachment.isImage, let thumbnailData = attachment.thumbnail,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if attachment.isImage, let uiImage = UIImage(data: attachment.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // File icon
                    VStack(spacing: 4) {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(attachment.fileExtension.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .tertiarySystemFill))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if let onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white, .red)
                }
                .offset(x: 6, y: -6)
            }
        }
    }

    private var iconName: String {
        switch attachment.fileExtension {
        case "pdf":
            return "doc.fill"
        case "zip", "tar", "gz", "rar", "7z":
            return "doc.zipper"
        case "txt", "md", "markdown":
            return "doc.text.fill"
        default:
            return "doc.fill"
        }
    }
}

/// Displays a thumbnail for an uploaded attachment
struct AttachmentThumbnailView: View {
    let attachment: Attachment
    let token: String?
    var onTap: (() -> Void)?

    init(attachment: Attachment, token: String? = nil, onTap: (() -> Void)? = nil) {
        self.attachment = attachment
        self.token = token
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            Group {
                if attachment.isImage {
                    AuthenticatedAsyncImage(
                        url: URL(string: attachment.browserDownloadUrl),
                        token: token
                    ) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholder
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: attachment.iconName)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(attachment.fileExtension.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .tertiarySystemFill))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .tertiarySystemFill))
    }
}

#Preview("Pending") {
    HStack {
        PendingAttachmentThumbnailView(
            attachment: PendingAttachment(
                data: Data(),
                fileName: "document.pdf",
                mimeType: "application/pdf"
            ),
            onRemove: {}
        )
    }
    .padding()
}
