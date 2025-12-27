import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String

    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?

    var body: some View {
        Markdown(content)
            .markdownTheme(.gitHub)
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
