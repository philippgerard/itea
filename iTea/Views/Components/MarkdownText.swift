import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String

    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?

    /// Pre-process content to highlight @mentions as links and handle HTML img tags
    private var processedContent: String {
        var result = content

        // Process HTML img tags intelligently:
        // - Small inline icons (< 50px) are stripped (they're decorative and won't render well)
        // - Larger images are converted to markdown
        let imgPattern = #"<img\s+([^>]*)\/?>"#
        if let imgRegex = try? NSRegularExpression(pattern: imgPattern, options: .caseInsensitive) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = imgRegex.matches(in: result, range: range).reversed()

            for match in matches {
                guard let fullRange = Range(match.range, in: result),
                      let attrsRange = Range(match.range(at: 1), in: result) else { continue }

                let attrs = String(result[attrsRange])

                // Extract src URL
                guard let src = extractAttribute("src", from: attrs) else {
                    result.replaceSubrange(fullRange, with: "")
                    continue
                }

                // Extract dimensions (if specified)
                let width = extractNumericAttribute("width", from: attrs)
                let height = extractNumericAttribute("height", from: attrs)

                // If both dimensions are explicitly small (< 50px), it's an inline icon - strip it
                // Default to 100 if not specified (assume it's a real image)
                let isSmallInlineIcon = (width ?? 100) < 50 && (height ?? 100) < 50

                if isSmallInlineIcon {
                    result.replaceSubrange(fullRange, with: "")
                } else {
                    result.replaceSubrange(fullRange, with: "![](\(src))")
                }
            }
        }

        // Match @username patterns (alphanumeric, underscores, hyphens)
        // Avoid matching email addresses by requiring word boundary or start
        let pattern = #"(?<![a-zA-Z0-9.])@([a-zA-Z0-9][-a-zA-Z0-9_]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }

        let range = NSRange(result.startIndex..., in: result)

        // Process matches in reverse to preserve indices
        let matches = regex.matches(in: result, range: range).reversed()
        for match in matches {
            guard let fullRange = Range(match.range, in: result),
                  let usernameRange = Range(match.range(at: 1), in: result) else { continue }

            let username = String(result[usernameRange])
            let replacement = "[@\(username)](mention:\(username))"
            result.replaceSubrange(fullRange, with: replacement)
        }

        return result
    }

    /// Extract a string attribute value from HTML attributes
    private func extractAttribute(_ name: String, from attrs: String) -> String? {
        let pattern = "\(name)\\s*=\\s*[\"']([^\"']+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: attrs, range: NSRange(attrs.startIndex..., in: attrs)),
              let valueRange = Range(match.range(at: 1), in: attrs) else {
            return nil
        }
        return String(attrs[valueRange])
    }

    /// Extract a numeric attribute value from HTML attributes (handles "14px", "14", etc.)
    private func extractNumericAttribute(_ name: String, from attrs: String) -> Int? {
        let pattern = "\(name)\\s*=\\s*[\"']?(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: attrs, range: NSRange(attrs.startIndex..., in: attrs)),
              let valueRange = Range(match.range(at: 1), in: attrs) else {
            return nil
        }
        return Int(attrs[valueRange])
    }

    var body: some View {
        Markdown(processedContent)
            .markdownTheme(.iTea)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                // Handle mention: links (no-op, just visual)
                if url.scheme == "mention" {
                    return .handled
                }
                if let deepLinkHandler,
                   let serverURL = authManager.getServerURL(),
                   deepLinkHandler.handleURL(url, serverURL: serverURL) {
                    return .handled
                }
                return .systemAction
            })
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            MarkdownText(content: "Regular paragraph text that flows naturally.")
            MarkdownText(content: "**Bold** and *italic* and `code`")
            MarkdownText(content: "Hey @claude, can you help with this? cc @username")
            MarkdownText(content: """
            ## Section Header

            Some body text here with @mentions inline.

            ### Subsection

            - Item one
            - Item two

            - [ ] Unchecked task
            - [x] Completed task
            """)
        }
        .padding()
    }
    .environmentObject(AuthenticationManager())
}

extension Theme {
    @MainActor static let iTea = Theme()
        // Base text styling - use system font to match app
        .text {
            FontFamily(.system())
            ForegroundColor(.primary)
            FontSize(15)
        }
        // Links (including @mentions) - accent color
        .link {
            ForegroundColor(.accentColor)
        }
        // Paragraphs with comfortable spacing
        .paragraph { configuration in
            configuration.label
                .markdownMargin(top: 0, bottom: 8)
        }
        // h1: Slightly larger, semibold
        .heading1 { configuration in
            configuration.label
                .markdownMargin(top: 12, bottom: 6)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(17)
                }
        }
        // h2: Same size as body, just semibold
        .heading2 { configuration in
            configuration.label
                .markdownMargin(top: 10, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(15)
                }
        }
        // h3: Same size, medium weight
        .heading3 { configuration in
            configuration.label
                .markdownMargin(top: 8, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.medium)
                    FontSize(15)
                }
        }
        // Inline code
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(13)
            BackgroundColor(Color(.systemGray6))
        }
        // Code blocks
        .codeBlock { configuration in
            ScrollView(.horizontal, showsIndicators: false) {
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(13)
                    }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .markdownMargin(top: 8, bottom: 8)
        }
        // Blockquotes
        .blockquote { configuration in
            configuration.label
                .markdownTextStyle {
                    ForegroundColor(.secondary)
                    FontSize(15)
                }
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 3)
                }
                .markdownMargin(top: 6, bottom: 6)
        }
        // Lists
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 2, bottom: 2)
        }
        // Task list markers - subtle SF Symbols
        .taskListMarker { configuration in
            Image(systemName: configuration.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(configuration.isCompleted ? Color.secondary : Color(.systemGray4))
        }
        // Thematic breaks
        .thematicBreak {
            Divider()
                .markdownMargin(top: 12, bottom: 12)
        }
        // Tables - cleaner styling
        .table { configuration in
            configuration.label
                .markdownMargin(top: 8, bottom: 8)
                .markdownTableBorderStyle(.init(color: .clear))
                .markdownTableBackgroundStyle(.alternatingRows(Color(.tertiarySystemFill), .clear))
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(14)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
        }
}
