import Foundation

struct Attachment: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let size: Int
    let downloadCount: Int
    let createdAt: Date?
    let uuid: String
    let browserDownloadUrl: String

    var isImage: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "heic", "heif"]
        let ext = (name as NSString).pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var iconName: String {
        switch fileExtension {
        case "pdf":
            return "doc.fill"
        case "zip", "tar", "gz", "rar", "7z":
            return "doc.zipper"
        case "txt", "md", "markdown":
            return "doc.text.fill"
        case "swift", "js", "ts", "py", "go", "rs", "c", "cpp", "h", "java", "kt":
            return "chevron.left.forwardslash.chevron.right"
        case "json", "xml", "yaml", "yml", "toml":
            return "curlybraces"
        case "mp4", "mov", "avi", "mkv", "webm":
            return "film.fill"
        case "mp3", "wav", "aac", "flac", "m4a":
            return "waveform"
        default:
            return "doc.fill"
        }
    }
}
