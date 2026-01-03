import SwiftUI

struct EditPullRequestSheet: View {
    let pullRequest: PullRequest
    @Binding var isSaving: Bool
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedTitle: String
    @State private var editedBody: String

    init(pullRequest: PullRequest, isSaving: Binding<Bool>, onSave: @escaping (String, String) -> Void) {
        self.pullRequest = pullRequest
        self._isSaving = isSaving
        self.onSave = onSave
        self._editedTitle = State(initialValue: pullRequest.title)
        self._editedBody = State(initialValue: pullRequest.body ?? "")
    }

    private var canSave: Bool {
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !trimmedTitle.isEmpty
        let hasChanges = trimmedTitle != pullRequest.title || editedBody != (pullRequest.body ?? "")
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

                        TextField("Pull request title", text: $editedTitle)
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
            .navigationTitle("Edit Pull Request")
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
    EditPullRequestSheet(
        pullRequest: PullRequest(
            id: 1,
            number: 1,
            title: "Test PR",
            body: "This is the PR body with some content",
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
            head: nil,
            base: nil,
            mergeable: true,
            merged: false,
            mergedAt: nil,
            mergedBy: nil,
            comments: nil,
            createdAt: Date(),
            updatedAt: nil,
            repository: nil
        ),
        isSaving: .constant(false),
        onSave: { _, _ in }
    )
}
