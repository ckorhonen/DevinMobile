import Foundation

struct ErrorInfo: Sendable {
    let message: String
    let systemImage: String
    let actionLabel: String

    init(_ error: DevinAPIError) {
        self.message = error.localizedDescription
        self.systemImage = error.systemImage
        self.actionLabel = error.actionLabel
    }

    init(message: String) {
        self.message = message
        self.systemImage = "exclamationmark.triangle"
        self.actionLabel = "Retry"
    }
}

enum LoadingState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case error(ErrorInfo)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    var errorMessage: String? {
        if case .error(let info) = self { return info.message }
        return nil
    }
}
