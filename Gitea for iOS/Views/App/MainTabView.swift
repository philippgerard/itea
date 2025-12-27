import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case repositories
    case notifications
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .repositories: "Repositories"
        case .notifications: "Notifications"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .repositories: "folder"
        case .notifications: "bell"
        case .settings: "gear"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler: DeepLinkHandler?
    @State private var selectedTab = 0
    @State private var selectedItem: NavigationItem? = .repositories
    @State private var showCreatePRSheet = false
    @State private var pendingPRAction: DeepLinkAction?

    private var apiClient: APIClient? {
        guard let serverURL = authManager.getServerURL(),
              let token = authManager.getAccessToken() else {
            return nil
        }
        return APIClient(baseURL: serverURL, tokenProvider: { token })
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
        .onChange(of: deepLinkHandler?.pendingAction) { _, newAction in
            if case .createPullRequest = newAction {
                pendingPRAction = newAction
                showCreatePRSheet = true
                deepLinkHandler?.clearPendingAction()
            }
        }
        .sheet(isPresented: $showCreatePRSheet) {
            if let apiClient,
               case let .createPullRequest(owner, repo, base, head, title, body) = pendingPRAction {
                CreatePullRequestView(
                    owner: owner,
                    repo: repo,
                    pullRequestService: PullRequestService(apiClient: apiClient),
                    repositoryService: RepositoryService(apiClient: apiClient),
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
            if let apiClient {
                RepositoryListView(repositoryService: RepositoryService(apiClient: apiClient))
            }
        case .notifications:
            if let apiClient {
                NotificationListView(notificationService: NotificationService(apiClient: apiClient))
            }
        case .settings:
            SettingsView()
        }
    }

    // MARK: - iOS Tab Navigation

    private var tabNavigation: some View {
        TabView(selection: $selectedTab) {
            Tab("Repositories", systemImage: "folder", value: 0) {
                if let apiClient {
                    RepositoryListView(repositoryService: RepositoryService(apiClient: apiClient))
                }
            }

            Tab("Notifications", systemImage: "bell", value: 1) {
                if let apiClient {
                    NotificationListView(notificationService: NotificationService(apiClient: apiClient))
                }
            }

            Tab("Settings", systemImage: "gear", value: 2) {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
