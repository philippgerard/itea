import Foundation

enum AppConfiguration {
    static let apiBasePath = "/api/v1"

    static let defaultScopes = [
        "read:user",
        "read:repository",
        "read:issue",
        "write:issue",
        "read:notification",
        "write:notification"
    ]

    enum Keychain {
        static let service = "de.philippgerard.gitea-ios"
        static let serverURLKey = "server_url"
        static let accessTokenKey = "access_token"
    }
}
