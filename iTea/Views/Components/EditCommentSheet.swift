import SwiftUI

struct EditCommentSheet: View {
    let comment: Comment
    @Binding var isSaving: Bool
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedBody: String

    init(comment: Comment, isSaving: Binding<Bool>, onSave: @escaping (String) -> Void) {
        self.comment = comment
        self._isSaving = isSaving
        self.onSave = onSave
        self._editedBody = State(initialValue: comment.body)
    }

    private var canSave: Bool {
        !editedBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editedBody != comment.body
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $editedBody)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()

                Spacer()
            }
            .navigationTitle("Edit Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Save") {
                            onSave(editedBody)
                        }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                    }
                }
            }
        }
    }
}

#Preview {
    EditCommentSheet(
        comment: Comment(
            id: 1,
            body: "This is a test comment",
            user: User(
                id: 1,
                login: "test",
                fullName: "Test User",
                email: nil,
                avatarUrl: nil,
                isAdmin: false,
                created: nil
            ),
            createdAt: Date(),
            updatedAt: nil
        ),
        isSaving: .constant(false),
        onSave: { _ in }
    )
}
