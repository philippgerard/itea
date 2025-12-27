import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String

    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?

    var body: some View {
        Markdown(content)
            .markdownTheme(.iTea)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
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
            MarkdownText(content: """
            ## Section Header

            Some body text here.

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
        // Base text styling
        .text {
            ForegroundColor(.primary)
            FontSize(15)
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
            .background(Color(.systemGray6))
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
                .markdownTableBackgroundStyle(.alternatingRows(Color(.systemGray6), .clear))
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
