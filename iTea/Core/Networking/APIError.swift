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
            return "Network error: \(error.localizedDescription)"
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
}
