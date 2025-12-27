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
        #if targetEnvironment(macCatalyst)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout

    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Issue")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField("Issue title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $descriptionText)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(uiColor: .separator), lineWidth: 1)
                            )
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer with buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button("Create Issue") {
                    Task { await createIssue() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || isSubmitting)
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 500, minHeight: 450)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - iOS Layout

    private var iOSLayout: some View {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                    .buttonStyle(.borderedProminent)
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
