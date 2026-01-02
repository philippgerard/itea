import SwiftUI

/// Wrapper for navigation targets from notifications
enum NotificationTarget: Hashable {
    case issue(Issue, owner: String, repo: String)
    case pullRequest(PullRequest, owner: String, repo: String)
}

struct NotificationListView: View {
    let notificationService: NotificationService
    let issueService: IssueService
    let pullRequestService: PullRequestService

    @State private var notifications: [GiteaNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAll = false
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var loadingNotificationId: Int?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if isLoading && notifications.isEmpty {
                    ProgressView("Loading notifications...")
                } else if let errorMessage, notifications.isEmpty {
                    ContentUnavailableView {
                        SwiftUI.Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") {
                            Task { await loadNotifications() }
                        }
                    }
                } else if notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text(showAll ? "You have no notifications" : "You have no unread notifications")
                    )
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Toggle("Show All", isOn: $showAll)

                        Divider()

                        Button("Mark All as Read") {
                            Task { await markAllAsRead() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .refreshable {
                await loadNotifications()
            }
            .onChange(of: showAll) { _, _ in
                Task { await loadNotifications() }
            }
            .task {
                await loadNotifications()
            }
        }
    }

    private var notificationList: some View {
        List {
            ForEach(notifications) { notification in
                NotificationRowView(
                    notification: notification,
                    isLoading: loadingNotificationId == notification.id
                ) {
                    Task { await markAsRead(notification) }
                } onTap: {
                    Task { await navigateToNotification(notification) }
                }
                .onAppear {
                    Task { await loadMoreIfNeeded(currentItem: notification) }
                }
            }

            if isLoading && !notifications.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: NotificationTarget.self) { target in
            switch target {
            case let .issue(issue, owner, repo):
                IssueDetailView(
                    issue: issue,
                    owner: owner,
                    repo: repo,
                    issueService: issueService
                )
            case let .pullRequest(pr, owner, repo):
                PullRequestDetailView(
                    pullRequest: pr,
                    owner: owner,
                    repo: repo,
                    pullRequestService: pullRequestService
                )
            }
        }
    }

    private func navigateToNotification(_ notification: GiteaNotification) async {
        guard let number = notification.subject.issueOrPRNumber else { return }

        let owner = notification.repository.ownerName
        let repo = notification.repository.repoName

        loadingNotificationId = notification.id
        defer { loadingNotificationId = nil }

        do {
            switch notification.subject.type.lowercased() {
            case "issue":
                let issue = try await issueService.getIssue(owner: owner, repo: repo, index: number)
                // Mark as read when navigating
                try? await notificationService.markAsRead(notificationId: String(notification.id))
                // Navigate programmatically by pushing to navigation stack
                await MainActor.run {
                    navigateTo(.issue(issue, owner: owner, repo: repo))
                }
            case "pull":
                let pr = try await pullRequestService.getPullRequest(owner: owner, repo: repo, index: number)
                try? await notificationService.markAsRead(notificationId: String(notification.id))
                await MainActor.run {
                    navigateTo(.pullRequest(pr, owner: owner, repo: repo))
                }
            default:
                break
            }
        } catch {
            // Silently fail - could show error in future
        }
    }

    private func navigateTo(_ target: NotificationTarget) {
        navigationPath.append(target)
    }

    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            notifications = try await notificationService.getNotifications(all: showAll, page: currentPage)
            hasMorePages = !notifications.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMoreIfNeeded(currentItem: GiteaNotification) async {
        guard hasMorePages,
              !isLoading,
              notifications.last?.id == currentItem.id else { return }

        currentPage += 1
        isLoading = true

        do {
            let moreNotifications = try await notificationService.getNotifications(
                all: showAll,
                page: currentPage
            )
            hasMorePages = !moreNotifications.isEmpty
            notifications.append(contentsOf: moreNotifications)
        } catch {
            currentPage -= 1
        }

        isLoading = false
    }

    private func markAsRead(_ notification: GiteaNotification) async {
        do {
            try await notificationService.markAsRead(notificationId: String(notification.id))
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications.remove(at: index)
            }
        } catch {
            // Silently fail
        }
    }

    private func markAllAsRead() async {
        do {
            try await notificationService.markAllAsRead()
            if !showAll {
                notifications.removeAll()
            }
        } catch {
            // Silently fail
        }
    }
}

struct NotificationRowView: View {
    let notification: GiteaNotification
    let isLoading: Bool
    let onMarkAsRead: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    notificationIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.subject.title)
                            .font(.headline)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(notification.repository.fullName)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.secondary)

                            Text(notification.subject.typeDisplay)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)

                        if let date = notification.updatedAt {
                            Text(date, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else if notification.unread {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .swipeActions(edge: .trailing) {
            if notification.unread {
                Button {
                    onMarkAsRead()
                } label: {
                    SwiftUI.Label("Read", systemImage: "envelope.open")
                }
                .tint(.blue)
            }
        }
    }

    private var notificationIcon: some View {
        Group {
            switch notification.subject.type.lowercased() {
            case "issue":
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(notification.subject.state == "open" ? .green : .purple)
            case "pull":
                Image(systemName: "arrow.triangle.pull")
                    .foregroundStyle(notification.subject.state == "open" ? .green : .purple)
            case "commit":
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.orange)
            default:
                Image(systemName: "bell")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.title3)
        .frame(width: 28)
    }
}

#Preview {
    let apiClient = APIClient(baseURL: URL(string: "https://example.com")!, tokenProvider: { nil })
    NotificationListView(
        notificationService: NotificationService(apiClient: apiClient),
        issueService: IssueService(apiClient: apiClient),
        pullRequestService: PullRequestService(apiClient: apiClient)
    )
}
