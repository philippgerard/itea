import SwiftUI

struct RepositoryDetailView: View {
    let repository: Repository
    let repositoryService: RepositoryService

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedSection = 0

    private var apiClient: APIClient? {
        guard let serverURL = authManager.getServerURL(),
              let token = authManager.getAccessToken() else {
            return nil
        }
        return APIClient(baseURL: serverURL, tokenProvider: { token })
    }

    var body: some View {
        VStack(spacing: 0) {
            repositoryHeader

            Picker("Section", selection: $selectedSection) {
                Text("Issues").tag(0)
                Text("Pull Requests").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if let apiClient {
                switch selectedSection {
                case 0:
                    IssueListView(
                        owner: repository.ownerName,
                        repo: repository.repoName,
                        issueService: IssueService(apiClient: apiClient)
                    )
                case 1:
                    PullRequestListView(
                        owner: repository.ownerName,
                        repo: repository.repoName,
                        pullRequestService: PullRequestService(apiClient: apiClient),
                        repositoryService: repositoryService
                    )
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(repository.name)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var repositoryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(repository.fullName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if repository.isPrivate {
                    SwiftUI.Label("Private", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let description = repository.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                if let stars = repository.starsCount {
                    SwiftUI.Label("\(stars) stars", systemImage: "star")
                }
                if let forks = repository.forksCount {
                    SwiftUI.Label("\(forks) forks", systemImage: "tuningfork")
                }
                if let issues = repository.openIssuesCount {
                    SwiftUI.Label("\(issues) issues", systemImage: "exclamationmark.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    let apiClient = APIClient(baseURL: URL(string: "https://example.com")!, tokenProvider: { nil })
    NavigationStack {
        RepositoryDetailView(
            repository: Repository(
                id: 1,
                name: "example-repo",
                fullName: "user/example-repo",
                description: "An example repository",
                owner: User(id: 1, login: "user", fullName: nil, email: nil, avatarUrl: nil, isAdmin: false, created: nil),
                private: false,
                fork: false,
                htmlUrl: nil,
                cloneUrl: nil,
                defaultBranch: "main",
                starsCount: 42,
                forksCount: 10,
                openIssuesCount: 5,
                openPrCounter: 2,
                createdAt: nil,
                updatedAt: nil
            ),
            repositoryService: RepositoryService(apiClient: apiClient)
        )
    }
    .environmentObject(AuthenticationManager())
}
