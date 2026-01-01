import SwiftUI

struct RepositoryListView: View {
    let repositoryService: RepositoryService

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var repositories: [Repository] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var hasMorePages = true

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
        NavigationStack {
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
                await loadRepositories()
            }
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

#Preview {
    let apiClient = APIClient(baseURL: URL(string: "https://example.com")!, tokenProvider: { nil })
    RepositoryListView(repositoryService: RepositoryService(apiClient: apiClient))
        .environmentObject(AuthenticationManager())
}
