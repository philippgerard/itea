import SwiftUI

struct CreateIssueView: View {
    let owner: String
    let repo: String
    let issueService: IssueService
    let onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Issue title", text: $title)
                }

                Section("Description") {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Issue")
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createIssue() }
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func createIssue() async {
        isSubmitting = true

        do {
            _ = try await issueService.createIssue(
                owner: owner,
                repo: repo,
                title: title,
                body: descriptionText
            )
            onCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}
