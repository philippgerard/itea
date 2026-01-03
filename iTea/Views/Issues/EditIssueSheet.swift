import SwiftUI

struct EditIssueSheet: View {
    let issue: Issue
    @Binding var isSaving: Bool
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedBody: String

    init(issue: Issue, isSaving: Binding<Bool>, onSave: @escaping (String, String) -> Void) {
        self.issue = issue
        self._isSaving = isSaving
        self.onSave = onSave
        self._editedTitle = State(initialValue: issue.title)
        self._editedBody = State(initialValue: issue.body ?? "")
    }

    private var canSave: Bool {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !trimmedTitle.isEmpty
        let hasChanges = trimmedTitle != issue.title || editedBody != (issue.body ?? "")
        return hasTitle && hasChanges
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("Issue title", text: $editedTitle)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Body field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $editedBody)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Issue")
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
                            onSave(editedTitle, editedBody)
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
    EditIssueSheet(
        issue: Issue(
            id: 1,
            number: 1,
            title: "Test Issue",
            body: "This is the issue body with some content",
            user: User(
                id: 1,
                login: "test",
                fullName: "Test User",
                email: nil,
                avatarUrl: nil,
                isAdmin: false,
                created: nil
            ),
            state: "open",
            labels: nil,
            milestone: nil,
            assignees: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: nil,
            closedAt: nil,
            repository: nil
        ),
        isSaving: .constant(false),
        onSave: { _, _ in }
    )
}
