import SwiftUI

struct NotificationListView: View {
    let notificationService: NotificationService

    @State private var notifications: [GiteaNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAll = false
    @State private var currentPage = 1
    @State private var hasMorePages = true

    var body: some View {
        NavigationStack {
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
                NotificationRowView(notification: notification) {
                    Task { await markAsRead(notification) }
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
    let onMarkAsRead: () -> Void

    var body: some View {
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

                if notification.unread {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 4)
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
    NotificationListView(notificationService: NotificationService(apiClient: apiClient))
}
