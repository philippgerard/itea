import SwiftUI

struct PullRequestDetailView: View {
    let pullRequest: PullRequest
    let owner: String
    let repo: String
    let pullRequestService: PullRequestService
    var onPullRequestUpdated: ((PullRequest) -> Void)?

    @State private var currentPR: PullRequest
    @State private var comments: [Comment] = []
    @State private var commitStatus: CombinedStatus?
    @State private var actionRuns: [ActionRun] = []
    @State private var isLoading = false
    @State private var isLoadingStatus = false
    @State private var newComment = ""
    @State private var isSubmitting = false
    @State private var isTogglingState = false
    @State private var isMerging = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showMergeOptions = false
    @State private var statusPollingTask: Task<Void, Never>?
    @FocusState private var isCommentFocused: Bool

    init(pullRequest: PullRequest, owner: String, repo: String, pullRequestService: PullRequestService, onPullRequestUpdated: ((PullRequest) -> Void)? = nil) {
        self.pullRequest = pullRequest
        self.owner = owner
        self.repo = repo
        self.pullRequestService = pullRequestService
        self.onPullRequestUpdated = onPullRequestUpdated
        self._currentPR = State(initialValue: pullRequest)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                headerCard

                // CI Status card (shows commit statuses - what Gitea displays on PR page)
                if let status = commitStatus, !status.statuses.isEmpty {
                    ciStatusCard(status)
                }

                // Body card (if has body)
                if let body = currentPR.body, !body.isEmpty {
                    bodyCard(body)
                }

                // Comments section
                commentsSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            commentInputBar
        }
        .navigationTitle("#\(currentPR.number)")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    // Merge option (only for open, mergeable PRs)
                    if currentPR.isOpen && !currentPR.isMerged {
                        Button {
                            showMergeOptions = true
                        } label: {
                            SwiftUI.Label("Merge", systemImage: "arrow.triangle.merge")
                        }
                        .disabled(isMerging || currentPR.mergeable == false)

                        Divider()
                    }

                    // Close/Reopen option (not for merged PRs)
                    if !currentPR.isMerged {
                        Button {
                            Task { await togglePRState() }
                        } label: {
                            if currentPR.isOpen {
                                SwiftUI.Label("Close Pull Request", systemImage: "xmark.circle")
                            } else {
                                SwiftUI.Label("Reopen Pull Request", systemImage: "arrow.uturn.left.circle")
                            }
                        }
                        .disabled(isTogglingState)
                    }
                } label: {
                    if isTogglingState || isMerging {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Merge Pull Request", isPresented: $showMergeOptions, titleVisibility: .visible) {
            Button("Merge commit") {
                Task { await mergePR(method: .merge) }
            }
            Button("Squash and merge") {
                Task { await mergePR(method: .squash) }
            }
            Button("Rebase and merge") {
                Task { await mergePR(method: .rebase) }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how to merge this pull request")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .task {
            await loadComments()
            await loadCommitStatus()
        }
        .onAppear {
            startStatusPolling()
        }
        .onDisappear {
            stopStatusPolling()
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(currentPR.title)
                .font(.headline)

            // Status row
            HStack(spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10))
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(statusColor)

                Text("·")
                    .foregroundStyle(.quaternary)

                if let date = currentPR.createdAt {
                    Text(date, style: .relative)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Branch info
            if let head = currentPR.head, let base = currentPR.base {
                HStack(spacing: 6) {
                    Text(head.ref)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(base.ref)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Labels
            if currentPR.hasLabels, let labels = currentPR.labels {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(labels) { label in
                            LabelTagView(label: label)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusIcon: String {
        if currentPR.isMerged {
            return "arrow.triangle.merge"
        } else if currentPR.isOpen {
            return "arrow.triangle.pull"
        } else {
            return "xmark.circle.fill"
        }
    }

    private var statusText: String {
        if currentPR.isMerged {
            return "Merged"
        } else if currentPR.isOpen {
            return "Open"
        } else {
            return "Closed"
        }
    }

    private var statusColor: Color {
        if currentPR.isMerged {
            return .purple
        } else if currentPR.isOpen {
            return .green
        } else {
            return .red
        }
    }

    // MARK: - CI Status Card

    private func ciStatusCard(_ status: CombinedStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with overall status
            HStack(spacing: 8) {
                Image(systemName: status.overallState.iconName)
                    .foregroundStyle(ciStatusColor(status.overallState))

                Text("CI Checks")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if isLoadingStatus {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(status.overallState.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ciStatusColor(status.overallState).opacity(0.12))
                    .foregroundStyle(ciStatusColor(status.overallState))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Individual checks
            ForEach(status.statuses) { check in
                HStack(spacing: 8) {
                    Image(systemName: check.state.iconName)
                        .font(.caption)
                        .foregroundStyle(ciStatusColor(check.state))

                    Text(check.context)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    if let description = check.description, !description.isEmpty {
                        Text(description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func ciStatusColor(_ state: CommitStatusState) -> Color {
        switch state {
        case .pending:
            return .yellow
        case .success:
            return .green
        case .error, .failure:
            return .red
        case .warning:
            return .orange
        case .unknown:
            return .secondary
        }
    }

    // MARK: - Actions Runs Card

    private var actionsRunsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .foregroundStyle(actionsOverallColor)

                Text("Actions")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if isLoadingStatus {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(actionsOverallStatus)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(actionsOverallColor.opacity(0.12))
                    .foregroundStyle(actionsOverallColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Individual runs
            ForEach(actionRuns) { run in
                HStack(spacing: 8) {
                    Image(systemName: run.state.iconName)
                        .font(.caption)
                        .foregroundStyle(actionRunColor(run.state))

                    Text(run.displayName)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    Text(run.state.displayText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionsOverallStatus: String {
        if actionRuns.contains(where: { $0.state == .running }) {
            return "Running"
        } else if actionRuns.contains(where: { $0.state == .waiting || $0.state == .queued }) {
            return "Pending"
        } else if actionRuns.contains(where: { $0.state == .failure }) {
            return "Failed"
        } else if actionRuns.allSatisfy({ $0.state == .success || $0.state == .skipped }) {
            return "Passed"
        } else if actionRuns.contains(where: { $0.state == .cancelled }) {
            return "Cancelled"
        }
        return "Unknown"
    }

    private var actionsOverallColor: Color {
        if actionRuns.contains(where: { $0.state == .running }) {
            return .blue
        } else if actionRuns.contains(where: { $0.state == .waiting || $0.state == .queued }) {
            return .yellow
        } else if actionRuns.contains(where: { $0.state == .failure }) {
            return .red
        } else if actionRuns.allSatisfy({ $0.state == .success || $0.state == .skipped }) {
            return .green
        } else if actionRuns.contains(where: { $0.state == .cancelled }) {
            return .secondary
        }
        return .secondary
    }

    private func actionRunColor(_ state: ActionRunState) -> Color {
        switch state {
        case .waiting, .queued:
            return .yellow
        case .running:
            return .blue
        case .success:
            return .green
        case .failure:
            return .red
        case .cancelled, .skipped:
            return .secondary
        case .unknown:
            return .secondary
        }
    }

    // MARK: - Body Card

    private func bodyCard(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Author row
            HStack(spacing: 10) {
                UserAvatarView(user: currentPR.user, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentPR.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let date = currentPR.createdAt {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Content
            MarkdownText(content: body)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            if !comments.isEmpty || isLoading {
                Text("Comments")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 8)
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else if comments.isEmpty {
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(comments) { comment in
                    CommentView(comment: comment)
                }

                // End of thread indicator
                endOfThreadIndicator
            }
        }
    }

    private var endOfThreadIndicator: some View {
        HStack(spacing: 12) {
            VStack { Divider() }
            Text("End of conversation")
                .font(.caption)
                .foregroundStyle(.tertiary)
            VStack { Divider() }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Comment Input

    private var commentInputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Add a comment...", text: $newComment, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...6)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .focused($isCommentFocused)

            Button {
                Task { await submitComment() }
            } label: {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                        .imageScale(.large)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .background(newComment.isEmpty ? Color.secondary.opacity(0.2) : Color.accentColor)
            .foregroundStyle(newComment.isEmpty ? Color.secondary : Color.white)
            .clipShape(Circle())
            .disabled(newComment.isEmpty || isSubmitting)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await pullRequestService.getComments(
                owner: owner,
                repo: repo,
                prIndex: currentPR.number
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    private func loadCommitStatus() async {
        let sha = currentPR.head?.sha

        isLoadingStatus = true

        // Load Actions runs (works even without SHA, will just get all runs)
        do {
            actionRuns = try await pullRequestService.getActionRuns(
                owner: owner,
                repo: repo,
                sha: sha
            )
        } catch {
            // Silently fail - Actions status is optional
            actionRuns = []
        }

        // Load commit status (requires SHA)
        if let sha {
            do {
                commitStatus = try await pullRequestService.getCommitStatus(
                    owner: owner,
                    repo: repo,
                    sha: sha
                )
            } catch {
                // Silently fail - CI status is optional
                commitStatus = nil
            }
        }

        isLoadingStatus = false
    }

    private func startStatusPolling() {
        // Only poll for open PRs
        guard currentPR.isOpen else { return }

        statusPollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }

                await loadCommitStatus()

                // Stop polling if all checks are complete
                let hasInProgressActions = actionRuns.contains { $0.isInProgress }
                let hasPendingStatus = commitStatus?.hasPending ?? false

                if !hasInProgressActions && !hasPendingStatus {
                    break
                }
            }
        }
    }

    private func stopStatusPolling() {
        statusPollingTask?.cancel()
        statusPollingTask = nil
    }

    private func submitComment() async {
        isSubmitting = true
        isCommentFocused = false

        do {
            let comment = try await pullRequestService.createComment(
                owner: owner,
                repo: repo,
                prIndex: currentPR.number,
                body: newComment
            )
            comments.append(comment)
            newComment = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }

    private func togglePRState() async {
        isTogglingState = true

        do {
            let updatedPR: PullRequest
            if currentPR.isOpen {
                updatedPR = try await pullRequestService.closePullRequest(
                    owner: owner,
                    repo: repo,
                    index: currentPR.number
                )
            } else {
                updatedPR = try await pullRequestService.reopenPullRequest(
                    owner: owner,
                    repo: repo,
                    index: currentPR.number
                )
            }
            currentPR = updatedPR
            onPullRequestUpdated?(updatedPR)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isTogglingState = false
    }

    private func mergePR(method: MergeMethod) async {
        isMerging = true

        do {
            try await pullRequestService.mergePullRequest(
                owner: owner,
                repo: repo,
                index: currentPR.number,
                method: method
            )

            // Refresh the PR to get updated state
            let updatedPR = try await pullRequestService.getPullRequest(
                owner: owner,
                repo: repo,
                index: currentPR.number
            )
            currentPR = updatedPR
            onPullRequestUpdated?(updatedPR)

            // Stop polling since PR is now merged
            stopStatusPolling()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isMerging = false
    }
}
