import Foundation

final class NotificationService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getNotifications(all: Bool = false, page: Int = 1, limit: Int = 20) async throws -> [GiteaNotification] {
        try await apiClient.request(.notifications(all: all, page: page, limit: limit))
    }

    func markAsRead(notificationId: String) async throws {
        try await apiClient.requestWithoutResponse(.markNotificationRead(id: notificationId))
    }

    func markAllAsRead() async throws {
        try await apiClient.requestWithoutResponse(.markAllNotificationsRead)
    }
}
