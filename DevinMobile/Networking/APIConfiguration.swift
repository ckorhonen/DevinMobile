import Foundation

enum APIConfiguration {
    static let baseURL = "https://api.devin.ai/v1"

    static var token: String? {
        KeychainService.getAPIKey()
    }

    static var v3BaseURL: String? {
        guard let orgId = KeychainService.getOrgId() else { return nil }
        return "https://api.devin.ai/v3beta1/organizations/\(orgId)"
    }
}
