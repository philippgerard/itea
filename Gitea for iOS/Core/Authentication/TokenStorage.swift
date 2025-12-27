import Foundation

struct StoredCredentials: Codable, Sendable {
    let serverURL: URL
    let accessToken: String
}

actor TokenStorage {
    private let keychain: KeychainHelper
    private let credentialsKey = "stored_credentials"

    init(keychain: KeychainHelper = .shared) {
        self.keychain = keychain
    }

    func save(serverURL: URL, accessToken: String) throws {
        let credentials = StoredCredentials(serverURL: serverURL, accessToken: accessToken)
        let data = try JSONEncoder().encode(credentials)
        try keychain.save(data, forKey: credentialsKey)
    }

    func load() -> StoredCredentials? {
        guard let data = try? keychain.read(forKey: credentialsKey),
              let credentials = try? JSONDecoder().decode(StoredCredentials.self, from: data) else {
            return nil
        }
        return credentials
    }

    func delete() throws {
        try keychain.delete(forKey: credentialsKey)
    }

    var hasCredentials: Bool {
        keychain.exists(forKey: credentialsKey)
    }
}
