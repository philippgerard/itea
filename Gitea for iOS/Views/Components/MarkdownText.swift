import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String

    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?

    var body: some View {
        Markdown(content)
            .markdownTheme(.appTheme)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                // Try to handle as internal Gitea link
                if let deepLinkHandler,
                   let serverURL = authManager.getServerURL(),
                   deepLinkHandler.handleURL(url, serverURL: serverURL) {
                    return .handled
                }
                // Otherwise open in default browser
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

            | Column 1 | Column 2 |
            |----------|----------|
            | Cell 1   | Cell 2   |

            - [ ] Task 1
            - [x] Task 2 (done)
            """)
        }
        .padding()
    }
    .environmentObject(AuthenticationManager())
}

extension Theme {
    @MainActor static let appTheme = Theme()
        .text {
            FontSize(.em(1))
        }
        .paragraph { configuration in
            configuration.label
                .markdownMargin(top: 0, bottom: 8)
        }
        .heading1 { configuration in
            configuration.label
                .markdownMargin(top: 16, bottom: 8)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.5))
                }
        }
        .heading2 { configuration in
            configuration.label
                .markdownMargin(top: 12, bottom: 6)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.25))
                }
        }
        .heading3 { configuration in
            configuration.label
                .markdownMargin(top: 8, bottom: 4)
                .markdownTextStyle {
                    FontWeight(.medium)
                    FontSize(.em(1.1))
                }
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            BackgroundColor(Color(.tertiarySystemFill))
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(.em(0.85))
                }
                .padding(12)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .markdownMargin(top: 8, bottom: 8)
        }
        .blockquote { configuration in
            configuration.label
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 3)
                }
                .markdownMargin(top: 8, bottom: 8)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 2, bottom: 2)
        }
}
