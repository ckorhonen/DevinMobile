import Foundation

enum DevinAPIError: Error, LocalizedError, Sendable {
    case noAuthToken
    case invalidToken
    case unauthorized
    case rateLimited
    case notFound
    case serverError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .noAuthToken: "No API key configured"
        case .invalidToken: "Invalid API key format"
        case .unauthorized: "Invalid or expired API key"
        case .rateLimited: "Rate limited — try again shortly"
        case .notFound: "Resource not found"
        case .serverError(let code): "Server error (\(code))"
        case .networkError(let error): error.localizedDescription
        case .decodingError: "Failed to parse response"
        case .invalidURL: "Invalid URL"
        }
    }

    var isAuthError: Bool {
        switch self {
        case .noAuthToken, .invalidToken, .unauthorized: true
        default: false
        }
    }

    var isNetworkError: Bool {
        if case .networkError = self { return true }
        return false
    }

    var systemImage: String {
        switch self {
        case .noAuthToken, .invalidToken, .unauthorized: "lock.circle"
        case .networkError: "wifi.slash"
        case .rateLimited: "clock.arrow.circlepath"
        case .notFound: "magnifyingglass"
        default: "exclamationmark.triangle"
        }
    }

    var actionLabel: String {
        switch self {
        case .noAuthToken, .invalidToken, .unauthorized: "Check API Key"
        case .rateLimited: "Try Again"
        default: "Retry"
        }
    }
}
