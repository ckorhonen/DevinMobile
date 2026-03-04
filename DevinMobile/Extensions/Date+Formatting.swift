import Foundation

extension Date {
    nonisolated(unsafe) static let iso8601Full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let iso8601Basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init?(iso8601String: String) {
        if let date = Date.iso8601Full.date(from: iso8601String) {
            self = date
        } else if let date = Date.iso8601Basic.date(from: iso8601String) {
            self = date
        } else {
            return nil
        }
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}

extension String {
    var asRelativeDate: String {
        guard let date = Date(iso8601String: self) else { return self }
        return date.relativeFormatted
    }
}
