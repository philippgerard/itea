import SwiftUI

struct SearchView: View {
    let repositoryService: RepositoryService
    let issueService: IssueService?
    let pullRequestService: PullRequestService?

    @State private var searchText = ""
    @State private var searchResults: [Repository] = []
    @State private var isSearching = false

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
                // Search bar header - always at top
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search repositories...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)

                Divider()

                // Results content - fills remaining space
                if searchText.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    macOSResultsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Search")
            .navigationDestination(for: Repository.self) { repository in
                RepositoryDetailView(
                    repository: repository,
                    repositoryService: repositoryService
                )
            }
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await search(query: newValue)
            }
        }
    }

    private var macOSResultsList: some View {
        List(searchResults) { repository in
            NavigationLink(value: repository) {
                RepositoryRowView(repository: repository)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - iOS Layout

    private var iOSLayout: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    emptyState
                } else if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .navigationBarTitleDisplayMode(.large)
        }
        .searchable(text: $searchText, prompt: "Search repositories...")
        .onChange(of: searchText) { _, newValue in
            Task {
                await search(query: newValue)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Search Repositories",
            systemImage: "magnifyingglass",
            description: Text("Enter a query to search your repositories")
        )
    }

    private var resultsList: some View {
        List(searchResults) { repository in
            NavigationLink {
                RepositoryDetailView(
                    repository: repository,
                    repositoryService: repositoryService
                )
            } label: {
                RepositoryRowView(repository: repository)
            }
        }
        .listStyle(.plain)
    }

    private func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            // Search through repositories
            let allRepos = try await repositoryService.getRepositories()
            let lowercasedQuery = query.lowercased()

            searchResults = allRepos.filter { repo in
                repo.name.lowercased().contains(lowercasedQuery) ||
                repo.fullName.lowercased().contains(lowercasedQuery) ||
                (repo.description?.lowercased().contains(lowercasedQuery) ?? false)
            }
        } catch {
            searchResults = []
        }

        isSearching = false
    }
}

#Preview {
    let apiClient = APIClient(baseURL: URL(string: "https://example.com")!, tokenProvider: { nil })
    SearchView(
        repositoryService: RepositoryService(apiClient: apiClient),
        issueService: nil,
        pullRequestService: nil
    )
}
