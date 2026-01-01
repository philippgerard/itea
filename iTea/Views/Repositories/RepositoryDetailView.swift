import SwiftUI

struct RepositoryDetailView: View {
    let repository: Repository
    let repositoryService: RepositoryService

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedSection = 0
    @State private var issueService: IssueService?
    @State private var pullRequestService: PullRequestService?
    @State private var isHeaderExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            repositoryHeader

            Picker("Section", selection: $selectedSection) {
                Text("Issues").tag(0)
                Text("Pull Requests").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(.ultraThinMaterial)

            if let issueService, let pullRequestService {
                switch selectedSection {
                case 0:
                    IssueListView(
                        owner: repository.ownerName,
                        repo: repository.repoName,
                        issueService: issueService
                    )
                case 1:
                    PullRequestListView(
                        owner: repository.ownerName,
                        repo: repository.repoName,
                        pullRequestService: pullRequestService,
                        repositoryService: repositoryService
                    )
                default:
                    EmptyView()
                }
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle(repository.name)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #if !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            setupServices()
        }
    }

    private func setupServices() {
        guard issueService == nil else { return }

        guard let serverURL = authManager.getServerURL(),
              let token = authManager.getAccessToken() else {
            return
        }

        let apiClient = APIClient(baseURL: serverURL, tokenProvider: { token })
        issueService = IssueService(apiClient: apiClient)
        pullRequestService = PullRequestService(apiClient: apiClient)
    }

    private var hasExpandableContent: Bool {
        repository.description?.isEmpty == false
    }

    private var repositoryHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Primary row - always visible, tappable to expand
            Button {
                if hasExpandableContent {
                    withAnimation(.snappy(duration: 0.25)) {
                        isHeaderExpanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(repository.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if repository.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Compact stats
                    Spacer()

                    HStack(spacing: 12) {
                        if let stars = repository.starsCount, stars > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star")
                                Text("\(stars)")
                            }
                        }
                        if let forks = repository.forksCount, forks > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "tuningfork")
                                Text("\(forks)")
                            }
                        }
                        if let issues = repository.openIssuesCount, issues > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.circle")
                                Text("\(issues)")
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                    if hasExpandableContent {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isHeaderExpanded ? 180 : 0))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable description
            if isHeaderExpanded, let description = repository.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial)
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
