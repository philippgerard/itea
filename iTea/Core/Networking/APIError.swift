import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validationError(String)
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Authentication required. Please check your access token."
        case .forbidden:
            return "Access denied. You don't have permission to access this resource."
        case .notFound:
            return "Resource not found"
        case .conflict:
            return "A pull request already exists for this branch"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .serverError(let code):
            return "Server error (\(code))"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return Self.networkErrorDescription(for: error)
        case .unknown(let code):
            return "Unknown error (HTTP \(code))"
        }
    }

    var isAuthenticationError: Bool {
        switch self {
        case .unauthorized, .forbidden:
            return true
        default:
            return false
        }
    }

    /// True when the underlying failure is a user/task cancellation, so callers
    /// can suppress an error alert when the user cancelled a request themselves.
    var isCancellation: Bool {
        if case .networkError(let error) = self, (error as? URLError)?.code == .cancelled {
            return true
        }
        return false
    }

    private static func networkErrorDescription(for error: Error) -> String {
        guard let urlError = error as? URLError else {
            return "Network error: \(error.localizedDescription)"
        }
        switch urlError.code {
        case .timedOut:
            return "The server took too long to respond. Check the Server URL and your connection, then try again."
        case .notConnectedToInternet:
            return "No internet connection. Check your network and try again."
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return "Couldn't reach the server. Check that the Server URL points to a valid Gitea instance."
        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateNotYetValid:
            return "Couldn't establish a secure connection to the server."
        case .cancelled:
            return "Request cancelled."
        default:
            return "Network error: \(urlError.localizedDescription)"
        }
    }
}
