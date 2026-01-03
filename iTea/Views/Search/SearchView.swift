import SwiftUI

// MARK: - Navigation Items

struct SearchIssueNavItem: Hashable {
    let issue: Issue
    let owner: String
    let repo: String
}

struct SearchPRNavItem: Hashable {
    let pullRequest: PullRequest
    let owner: String
    let repo: String
}

struct SearchView: View {
    let repositoryService: RepositoryService
    let issueService: IssueService?
    let pullRequestService: PullRequestService?
    let attachmentService: AttachmentService?

    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .repositories
    @State private var repositoryResults: [Repository] = []
    @State private var issueResults: [Issue] = []
    @State private var pullRequestResults: [PullRequest] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    enum SearchScope: String, CaseIterable {
        case repositories = "Repos"
        case issues = "Issues"
        case pullRequests = "PRs"
    }

    var body: some View {
        #if targetEnvironment(macCatalyst)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout

    private var macOSLayout: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar header
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task { await performSearch() }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            clearResults()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)

                // Scope picker
                Picker("Scope", selection: $selectedScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)

                Divider()

                // Results content
                if searchText.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if currentResultsEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    resultsListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Search")
            .navigationDestination(for: Repository.self) { repository in
                RepositoryDetailView(repository: repository, repositoryService: repositoryService)
            }
            .navigationDestination(for: SearchIssueNavItem.self) { item in
                if let issueService, let attachmentService {
                    IssueDetailView(
                        issue: item.issue,
                        owner: item.owner,
                        repo: item.repo,
                        issueService: issueService,
                        attachmentService: attachmentService
                    )
                }
            }
            .navigationDestination(for: SearchPRNavItem.self) { item in
                if let pullRequestService {
                    PullRequestDetailView(
                        pullRequest: item.pullRequest,
                        owner: item.owner,
                        repo: item.repo,
                        pullRequestService: pullRequestService
                    )
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            debouncedSearch(query: newValue)
        }
        .onChange(of: selectedScope) { _, _ in
            if !searchText.isEmpty {
                debouncedSearch(query: searchText)
            }
        }
    }

    // MARK: - iOS Layout

    private var iOSLayout: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope picker
                Picker("Scope", selection: $selectedScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)

                Group {
                    if searchText.isEmpty {
                        emptyState
                    } else if isSearching {
                        ProgressView("Searching...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if currentResultsEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        resultsListView
                    }
                }
            }
            .navigationTitle("Search")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Repository.self) { repository in
                RepositoryDetailView(repository: repository, repositoryService: repositoryService)
            }
            .navigationDestination(for: SearchIssueNavItem.self) { item in
                if let issueService, let attachmentService {
                    IssueDetailView(
                        issue: item.issue,
                        owner: item.owner,
                        repo: item.repo,
                        issueService: issueService,
                        attachmentService: attachmentService
                    )
                }
            }
            .navigationDestination(for: SearchPRNavItem.self) { item in
                if let pullRequestService {
                    PullRequestDetailView(
                        pullRequest: item.pullRequest,
                        owner: item.owner,
                        repo: item.repo,
                        pullRequestService: pullRequestService
                    )
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search \(selectedScope.rawValue.lowercased())...")
        .onChange(of: searchText) { _, newValue in
            debouncedSearch(query: newValue)
        }
        .onChange(of: selectedScope) { _, _ in
            if !searchText.isEmpty {
                debouncedSearch(query: searchText)
            }
        }
    }

    // MARK: - Common Views

    private var emptyState: some View {
        ContentUnavailableView(
            "Search \(selectedScope.rawValue)",
            systemImage: searchIcon,
            description: Text("Enter a query to search \(selectedScope.rawValue.lowercased())")
        )
    }

    private var searchIcon: String {
        switch selectedScope {
        case .repositories: return "folder"
        case .issues: return "exclamationmark.circle"
        case .pullRequests: return "arrow.triangle.pull"
        }
    }

    private var currentResultsEmpty: Bool {
        switch selectedScope {
        case .repositories: return repositoryResults.isEmpty
        case .issues: return issueResults.isEmpty
        case .pullRequests: return pullRequestResults.isEmpty
        }
    }

    @ViewBuilder
    private var resultsListView: some View {
        switch selectedScope {
        case .repositories:
            repositoryResultsList
        case .issues:
            issueResultsList
        case .pullRequests:
            pullRequestResultsList
        }
    }

    private var repositoryResultsList: some View {
        List(repositoryResults) { repository in
            NavigationLink(value: repository) {
                RepositoryRowView(repository: repository)
            }
        }
        .listStyle(.plain)
    }

    private var issueResultsList: some View {
        List(issueResults) { issue in
            if let repo = issue.repository {
                NavigationLink(value: SearchIssueNavItem(issue: issue, owner: repo.owner, repo: repo.name)) {
                    SearchIssueRowView(issue: issue)
                }
            } else {
                SearchIssueRowView(issue: issue)
            }
        }
        .listStyle(.plain)
    }

    private var pullRequestResultsList: some View {
        List(pullRequestResults) { pr in
            if let repo = pr.repository {
                NavigationLink(value: SearchPRNavItem(pullRequest: pr, owner: repo.owner, repo: repo.name)) {
                    SearchPRRowView(pullRequest: pr)
                }
            } else {
                SearchPRRowView(pullRequest: pr)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Search Logic

    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            clearResults()
            return
        }

        isSearching = true

        do {
            switch selectedScope {
            case .repositories:
                repositoryResults = try await repositoryService.searchRepositories(query: query)
            case .issues:
                if let issueService {
                    issueResults = try await issueService.searchIssues(query: query)
                }
            case .pullRequests:
                if let pullRequestService {
                    pullRequestResults = try await pullRequestService.searchPullRequests(query: query)
                }
            }
        } catch {
            // Clear results on error
            switch selectedScope {
            case .repositories: repositoryResults = []
            case .issues: issueResults = []
            case .pullRequests: pullRequestResults = []
            }
        }

        isSearching = false
    }

    private func clearResults() {
        repositoryResults = []
        issueResults = []
        pullRequestResults = []
    }

    private func debouncedSearch(query: String) {
        // Cancel any existing search task
        searchTask?.cancel()

        guard !query.isEmpty else {
            clearResults()
            return
        }

        // Create new debounced search task
        searchTask = Task {
            // Wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            await performSearch()
        }
    }
}

// MARK: - Search-specific Row Views

struct SearchIssueRowView: View {
    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Repository info
            if let repo = issue.repository {
                Text(repo.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(issue.title)
                .font(.body)
                .lineLimit(2)

            // Bottom row
            HStack(spacing: 8) {
                // State badge
                HStack(spacing: 4) {
                    Image(systemName: issue.isOpen ? "circle.fill" : "checkmark.circle.fill")
                        .font(.caption2)
                    Text("#\(issue.number)")
                        .font(.caption)
                }
                .foregroundStyle(issue.isOpen ? .green : .purple)

                Spacer()

                // Comment count
                if let comments = issue.comments, comments > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "text.bubble")
                        Text("\(comments)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchPRRowView: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Repository info
            if let repo = pullRequest.repository {
                Text(repo.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(pullRequest.title)
                .font(.body)
                .lineLimit(2)

            // Bottom row
            HStack(spacing: 8) {
                // State badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                    Text("#\(pullRequest.number)")
                        .font(.caption)
                }
                .foregroundStyle(statusColor)

                Spacer()

                // Comment count
                if let comments = pullRequest.comments, comments > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "text.bubble")
                        Text("\(comments)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: String {
        if pullRequest.isMerged {
            return "arrow.triangle.merge"
        } else if pullRequest.isOpen {
            return "arrow.triangle.pull"
        } else {
            return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        if pullRequest.isMerged {
            return .purple
        } else if pullRequest.isOpen {
            return .green
        } else {
            return .red
        }
    }
}

#Preview {
    let apiClient = APIClient(baseURL: URL(string: "https://example.com")!, tokenProvider: { nil })
    SearchView(
        repositoryService: RepositoryService(apiClient: apiClient),
        issueService: nil,
        pullRequestService: nil,
        attachmentService: nil
    )
}
