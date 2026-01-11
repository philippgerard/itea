import SwiftUI

/// A TextEditor wrapper that tracks cursor position for dictation insertion
struct TextEditorWithSelection: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            // Preserve selection when updating text
            let currentSelection = uiView.selectedRange
            uiView.text = text
            // Restore selection if still valid
            if currentSelection.location + currentSelection.length <= text.count {
                uiView.selectedRange = currentSelection
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorWithSelection

        init(_ parent: TextEditorWithSelection) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}
