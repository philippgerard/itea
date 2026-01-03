import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case repositories
    case notifications
    case search
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .repositories: "Repositories"
        case .notifications: "Notifications"
        case .search: "Search"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .repositories: "folder"
        case .notifications: "bell"
        case .search: "magnifyingglass"
        case .settings: "gear"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?
    @State private var selectedTab: NavigationItem = .repositories
    @State private var selectedItem: NavigationItem? = .repositories
    @State private var showCreatePRSheet = false
    @State private var pendingPRAction: DeepLinkAction?

    // Stable services - created once to prevent view recreation
    @State private var repositoryService: RepositoryService?
    @State private var notificationService: NotificationService?
    @State private var issueService: IssueService?
    @State private var pullRequestService: PullRequestService?

    private func setupServices() {
        guard repositoryService == nil else { return }

        guard let serverURL = authManager.getServerURL(),
              let token = authManager.getAccessToken() else {
            return
        }

        let apiClient = APIClient(baseURL: serverURL, tokenProvider: { token })
        repositoryService = RepositoryService(apiClient: apiClient)
        notificationService = NotificationService(apiClient: apiClient)
        issueService = IssueService(apiClient: apiClient)
        pullRequestService = PullRequestService(apiClient: apiClient)
    }

    var body: some View {
        Group {
            #if targetEnvironment(macCatalyst)
            sidebarNavigation
                .frame(minWidth: 900, minHeight: 600)
            #else
            tabNavigation
            #endif
        }
        .task {
            setupServices()
        }
        .onChange(of: deepLinkHandler?.pendingAction) { _, newAction in
            guard let newAction else { return }

            switch newAction {
            case .createPullRequest:
                pendingPRAction = newAction
                showCreatePRSheet = true
                deepLinkHandler?.clearPendingAction()

            case .viewRepository, .viewIssue, .viewPullRequest:
                // Switch to repositories tab and let RepositoryListView handle navigation
                selectedTab = .repositories
                selectedItem = .repositories

            }
        }
        .sheet(isPresented: $showCreatePRSheet) {
            if let pullRequestService, let repositoryService,
               case let .createPullRequest(owner, repo, base, head, title, body) = pendingPRAction {
                CreatePullRequestView(
                    owner: owner,
                    repo: repo,
                    pullRequestService: pullRequestService,
                    repositoryService: repositoryService,
                    onCreated: { },
                    initialTitle: title,
                    initialBody: body,
                    initialHeadBranch: head,
                    initialBaseBranch: base
                )
                #if targetEnvironment(macCatalyst)
                .presentationSizing(.fitted)
                #endif
            }
        }
    }

    // MARK: - macOS Sidebar Navigation

    private var sidebarNavigation: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                ForEach(NavigationItem.allCases) { item in
                    SwiftUI.Label(item.title, systemImage: item.icon)
                        .tag(item)
                }
            }
            .navigationTitle("iTea")
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
        } detail: {
            if let selectedItem {
                destinationView(for: selectedItem)
            } else {
                ContentUnavailableView(
                    "Select an item",
                    systemImage: "sidebar.left",
                    description: Text("Choose from the sidebar")
                )
            }
        }
    }

    @ViewBuilder
    private func destinationView(for item: NavigationItem) -> some View {
        switch item {
        case .repositories:
            if let repositoryService {
                RepositoryListView(repositoryService: repositoryService)
            } else {
                ProgressView()
            }
        case .notifications:
            if let notificationService, let issueService, let pullRequestService {
                NotificationListView(
                    notificationService: notificationService,
                    issueService: issueService,
                    pullRequestService: pullRequestService
                )
            } else {
                ProgressView()
            }
        case .search:
            if let repositoryService, let issueService, let pullRequestService {
                SearchView(
                    repositoryService: repositoryService,
                    issueService: issueService,
                    pullRequestService: pullRequestService
                )
            } else {
                ProgressView()
            }
        case .settings:
            SettingsView()
        }
    }

    // MARK: - iOS Tab Navigation

    private var tabNavigation: some View {
        TabView(selection: $selectedTab) {
            if let repositoryService, let notificationService, let issueService, let pullRequestService {
                RepositoryListView(repositoryService: repositoryService)
                    .tabItem {
                        SwiftUI.Label("Repositories", systemImage: "folder")
                    }
                    .tag(NavigationItem.repositories)

                NotificationListView(
                    notificationService: notificationService,
                    issueService: issueService,
                    pullRequestService: pullRequestService
                )
                    .tabItem {
                        SwiftUI.Label("Notifications", systemImage: "bell")
                    }
                    .tag(NavigationItem.notifications)

                SearchView(
                    repositoryService: repositoryService,
                    issueService: issueService,
                    pullRequestService: pullRequestService
                )
                .tabItem {
                    SwiftUI.Label("Search", systemImage: "magnifyingglass")
                }
                .tag(NavigationItem.search)
            }

            SettingsView()
                .tabItem {
                    SwiftUI.Label("Settings", systemImage: "gear")
                }
                .tag(NavigationItem.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
