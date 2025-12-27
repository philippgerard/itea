import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String

    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?

    var body: some View {
        Markdown(content)
            .markdownTheme(.subtle)
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
        VStack(alignment: .leading, spacing: 20) {
            MarkdownText(content: "**Bold** and *italic* text")
            MarkdownText(content: "Code: `inline code here`")
            MarkdownText(content: "A [link](https://example.com) in text")
            MarkdownText(content: """
            ## Header

            - List item 1
            - List item 2

            - [ ] Task 1
            - [x] Task 2 (done)
            """)
        }
        .padding()
    }
    .environmentObject(AuthenticationManager())
}

// A restrained theme that doesn't fight the UI
extension Theme {
    @MainActor static let subtle = Theme()
        // Body text: inherit system font
        .text {
            ForegroundColor(.primary)
        }
        // Paragraphs: tight, no excess space
        .paragraph { configuration in
            configuration.label
                .markdownMargin(top: 0, bottom: 4)
        }
        // h1: bold, same size - let context provide hierarchy
        .heading1 { configuration in
            configuration.label
                .markdownMargin(top: 8, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.semibold)
                }
        }
        // h2: semibold, same size
        .heading2 { configuration in
            configuration.label
                .markdownMargin(top: 6, bottom: 2)
                .markdownTextStyle {
                    FontWeight(.semibold)
                }
        }
        // h3: medium weight, same size
        .heading3 { configuration in
            configuration.label
                .markdownMargin(top: 4, bottom: 2)
                .markdownTextStyle {
                    FontWeight(.medium)
                }
        }
        // Inline code: subtle
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
        }
        // Code blocks: minimal
        .codeBlock { configuration in
            ScrollView(.horizontal, showsIndicators: false) {
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
            }
            .padding(10)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .markdownMargin(top: 4, bottom: 4)
        }
        // Blockquotes: subtle left accent
        .blockquote { configuration in
            configuration.label
                .markdownTextStyle {
                    ForegroundColor(.secondary)
                }
                .padding(.leading, 10)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)
                }
                .markdownMargin(top: 4, bottom: 4)
        }
        // Lists: tight
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 1, bottom: 1)
        }
        // Task lists: subtle checkmarks
        .taskListMarker { configuration in
            Image(systemName: configuration.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(configuration.isCompleted ? .secondary : .tertiary)
                .font(.system(size: 14))
        }
        // Thematic break (hr): subtle
        .thematicBreak {
            Divider()
                .markdownMargin(top: 8, bottom: 8)
        }
}
