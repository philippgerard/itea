import SwiftUI
import MarkdownUI

struct MarkdownText: View {
    let content: String

    var body: some View {
        Markdown(content)
            .markdownTheme(.gitHub)
            .textSelection(.enabled)
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
}
