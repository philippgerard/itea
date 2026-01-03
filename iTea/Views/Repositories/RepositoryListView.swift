import SwiftUI

struct RepositoryListView: View {
    let repositoryService: RepositoryService

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?
    @State private var repositories: [Repository] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var navigationPath = NavigationPath()
    @State private var issueService: IssueService?
    @State private var pullRequestService: PullRequestService?
    @State private var attachmentService: AttachmentService?

    var filteredRepositories: [Repository] {
        if searchText.isEmpty {
            return repositories
        }
        return repositories.filter { repo in
            repo.name.localizedCaseInsensitiveContains(searchText) ||
            (repo.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isLoading && repositories.isEmpty {
                    ProgressView("Loading repositories...")
                } else if let errorMessage, repositories.isEmpty {
                    ContentUnavailableView {
                        SwiftUI.Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") {
                            Task { await loadRepositories() }
                        }
                    }
                } else if repositories.isEmpty {
                    ContentUnavailableView(
                        "No Repositories",
                        systemImage: "folder",
                        description: Text("You don't have any repositories yet")
                    )
                } else {
                    repositoryList
                }
            }
            .navigationTitle("Repositories")
            .searchable(text: $searchText, prompt: "Search repositories")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .refreshable {
                await loadRepositories()
            }
            .task {
                setupServices()
                await loadRepositories()
            }
            .onChange(of: deepLinkHandler?.pendingAction) { _, newAction in
                handleDeepLinkAction(newAction)
            }
        }
    }

    private func setupServices() {
        guard issueService == nil else { return }

        guard let serverURL = authManager.getServerURL(),
              let token = authManager.getAccessToken() else { return }

        let apiClient = APIClient(baseURL: serverURL, tokenProvider: { token })
        issueService = IssueService(apiClient: apiClient)
        pullRequestService = PullRequestService(apiClient: apiClient)
        attachmentService = AttachmentService(apiClient: apiClient)
    }

    private func handleDeepLinkAction(_ action: DeepLinkAction?) {
        guard let action else { return }

        Task {
            switch action {
            case .viewRepository(let owner, let repo):
                await navigateToRepository(owner: owner, repo: repo)
                deepLinkHandler?.clearPendingAction()

            case .viewIssue(let owner, let repo, let number):
                await navigateToIssue(owner: owner, repo: repo, number: number)
                deepLinkHandler?.clearPendingAction()

            case .viewPullRequest(let owner, let repo, let number):
                await navigateToPullRequest(owner: owner, repo: repo, number: number)
                deepLinkHandler?.clearPendingAction()

            case .createPullRequest:
                break // Handled by MainTabView
            }
        }
    }

    private func navigateToRepository(owner: String, repo: String) async {
        do {
            let repository = try await repositoryService.getRepository(owner: owner, repo: repo)
            navigationPath.append(repository)
        } catch {
            // Silently fail - could show error
        }
    }

    private func navigateToIssue(owner: String, repo: String, number: Int) async {
        guard let issueService else { return }
        do {
            let repository = try await repositoryService.getRepository(owner: owner, repo: repo)
            let issue = try await issueService.getIssue(owner: owner, repo: repo, index: number)
            navigationPath.append(repository)
            navigationPath.append(IssueNavigationItem(issue: issue, owner: owner, repo: repo))
        } catch {
            // Silently fail
        }
    }

    private func navigateToPullRequest(owner: String, repo: String, number: Int) async {
        guard let pullRequestService else { return }
        do {
            let repository = try await repositoryService.getRepository(owner: owner, repo: repo)
            let pr = try await pullRequestService.getPullRequest(owner: owner, repo: repo, index: number)
            navigationPath.append(repository)
            navigationPath.append(PRNavigationItem(pullRequest: pr, owner: owner, repo: repo))
        } catch {
            // Silently fail
        }
    }

    private var repositoryList: some View {
        List {
            ForEach(filteredRepositories) { repository in
                NavigationLink(value: repository) {
                    RepositoryRowView(repository: repository)
                }
                .onAppear {
                    Task {
                        await loadMoreIfNeeded(currentItem: repository)
                    }
                }
            }

            if isLoading && !repositories.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Repository.self) { repository in
            RepositoryDetailView(repository: repository, repositoryService: repositoryService)
        }
        .navigationDestination(for: IssueNavigationItem.self) { item in
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
        .navigationDestination(for: PRNavigationItem.self) { item in
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

    private func loadRepositories() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            repositories = try await repositoryService.getRepositories(page: currentPage)
            hasMorePages = !repositories.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMoreIfNeeded(currentItem: Repository) async {
        guard hasMorePages,
              !isLoading,
              repositories.last?.id == currentItem.id else { return }

        currentPage += 1
        isLoading = true

        do {
            let moreRepos = try await repositoryService.getRepositories(page: currentPage)
            hasMorePages = !moreRepos.isEmpty
            repositories.append(contentsOf: moreRepos)
        } catch {
            // Silently fail for pagination
            currentPage -= 1
        }

        isLoading = false
    }
}

// MARK: - Navigation Items

struct IssueNavigationItem: Hashable {
    let issue: Issue
    let owner: String
    let repo: String
}

struct PRNavigationItem: Hashable {
    let pullRequest: PullRequest
    let owner: String
    let repo: String
}

#Preview {
    let apiClient = APIClient(baseURL: URL(string: "https://example.com")!, tokenProvider: { nil })
    RepositoryListView(repositoryService: RepositoryService(apiClient: apiClient))
        .environmentObject(AuthenticationManager())
}
