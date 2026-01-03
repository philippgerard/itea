import Foundation
import UIKit

/// Represents an attachment that has been selected but not yet uploaded
struct PendingAttachment: Identifiable, Hashable, Sendable {
    let id: UUID
    let data: Data
    let fileName: String
    let mimeType: String
    let thumbnail: Data?

    init(data: Data, fileName: String, mimeType: String, thumbnail: Data? = nil) {
        self.id = UUID()
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.thumbnail = thumbnail
    }

    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }

    var fileExtension: String {
        (fileName as NSString).pathExtension.lowercased()
    }

    static func == (lhs: PendingAttachment, rhs: PendingAttachment) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - MIME Type Detection

extension PendingAttachment {
    static func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic", "heif":
            return "image/heic"
        case "svg":
            return "image/svg+xml"
        case "pdf":
            return "application/pdf"
        case "zip":
            return "application/zip"
        case "txt":
            return "text/plain"
        case "md", "markdown":
            return "text/markdown"
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        default:
            return "application/octet-stream"
        }
    }
}
