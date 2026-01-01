import SwiftUI

struct CreatePullRequestView: View {
    let owner: String
    let repo: String
    let pullRequestService: PullRequestService
    let repositoryService: RepositoryService
    let onCreated: () -> Void

    // Optional prefilled values (from URL)
    var initialTitle: String?
    var initialBody: String?
    var initialHeadBranch: String?
    var initialBaseBranch: String?

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
    @State private var hasAppliedInitialValues = false

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
                Text("New Pull Request")
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
                    // Branches section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Branches")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        if isLoadingBranches {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Source branch")
                                        .frame(width: 100, alignment: .leading)
                                    Picker("", selection: $headBranch) {
                                        Text("Select branch").tag("")
                                        ForEach(branches) { branch in
                                            Text(branch.name).tag(branch.name)
                                        }
                                    }
                                    .labelsHidden()
                                }

                                HStack {
                                    Text("Target branch")
                                        .frame(width: 100, alignment: .leading)
                                    Picker("", selection: $baseBranch) {
                                        Text("Select branch").tag("")
                                        ForEach(branches) { branch in
                                            Text(branch.name).tag(branch.name)
                                        }
                                    }
                                    .labelsHidden()
                                }
                            }
                        }
                    }

                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField("Pull request title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $descriptionText)
                            .frame(minHeight: 150)
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

                Button("Create Pull Request") {
                    Task { await createPullRequest() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid || isSubmitting)
            }
            .padding(20)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 540, minHeight: 520)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .task {
            await loadBranches()
        }
    }

    // MARK: - iOS Layout

    private var iOSLayout: some View {
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
                        Picker("Source branch", selection: $headBranch) {
                            Text("Select branch").tag("")
                            ForEach(branches) { branch in
                                Text(branch.name).tag(branch.name)
                            }
                        }

                        Picker("Target branch", selection: $baseBranch) {
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
                        Task { await createPullRequest() }
                    }
                    .buttonStyle(.borderedProminent)
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

            // Apply initial values if provided (from URL)
            if !hasAppliedInitialValues {
                hasAppliedInitialValues = true

                if let initialTitle {
                    title = initialTitle
                }
                if let initialBody {
                    descriptionText = initialBody
                }
                if let initialBaseBranch, branches.contains(where: { $0.name == initialBaseBranch }) {
                    baseBranch = initialBaseBranch
                } else if let defaultBranch = branches.first(where: { $0.name == "main" || $0.name == "master" }) {
                    // Fallback to default base branch
                    baseBranch = defaultBranch.name
                }
                if let initialHeadBranch, branches.contains(where: { $0.name == initialHeadBranch }) {
                    headBranch = initialHeadBranch
                }
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
