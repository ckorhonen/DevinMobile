import Foundation

enum APIConfiguration {
    static let baseURL = "https://api.devin.ai/v1"

    static var token: String? {
        KeychainService.getAPIKey()
    }
}
