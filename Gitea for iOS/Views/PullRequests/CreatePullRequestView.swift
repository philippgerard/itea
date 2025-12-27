import SwiftUI

struct CreatePullRequestView: View {
    let owner: String
    let repo: String
    let pullRequestService: PullRequestService
    let repositoryService: RepositoryService
    let onCreated: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var headBranch = ""
    @State private var baseBranch = ""
    @State private var branches: [Branch] = []
    @State private var isLoadingBranches = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Branches") {
                    if isLoadingBranches {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Picker("Head branch", selection: $headBranch) {
                            Text("Select branch").tag("")
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch.name)
                            }
                        }

                        Picker("Base branch", selection: $baseBranch) {
                            Text("Select branch").tag("")
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch.name)
                            }
                        }
                    }
                }

                Section("Title") {
                    TextField("Pull request title", text: $title)
                }

                Section("Description") {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Pull Request")
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
                        Task { await createPullRequest() }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .task {
                await loadBranches()
            }
        }
    }

    private var isFormValid: Bool {
        !title.isEmpty && !headBranch.isEmpty && !baseBranch.isEmpty && headBranch != baseBranch
    }

    private func loadBranches() async {
        isLoadingBranches = true

        do {
            branches = try await repositoryService.getBranches(owner: owner, repo: repo)

            // Set default base branch if available
            if let defaultBranch = branches.first(where: { $0.name == "main" || $0.name == "master" }) {
                baseBranch = defaultBranch.name
            }
        } catch {
            errorMessage = "Failed to load branches: \(error.localizedDescription)"
            showError = true
        }

        isLoadingBranches = false
    }

    private func createPullRequest() async {
        isSubmitting = true

        do {
            _ = try await pullRequestService.createPullRequest(
                owner: owner,
                repo: repo,
                title: title,
                body: descriptionText,
                head: headBranch,
                base: baseBranch
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
