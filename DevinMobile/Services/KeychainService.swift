import Foundation
import Security

enum KeychainService {
    private static let serviceName = "com.devinmobile.apikey"
    private static let accountName = "devin-api-key"
    private static let orgAccountName = "devin-org-id"
    private static let emailAccountName = "devin-user-email"
    private static let githubPATAccountName = "github-pat"

    // MARK: - API Key

    static func save(apiKey: String) -> Bool {
        deleteItem(account: accountName)

        guard let data = apiKey.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func getAPIKey() -> String? {
        getItem(account: accountName)
    }

    // MARK: - Org ID

    @discardableResult
    static func saveOrgId(_ orgId: String) -> Bool {
        deleteItem(account: orgAccountName)

        guard let data = orgId.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: orgAccountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func getOrgId() -> String? {
        getItem(account: orgAccountName)
    }

    // MARK: - User Email

    @discardableResult
    static func saveUserEmail(_ email: String) -> Bool {
        saveItem(account: emailAccountName, value: email)
    }

    static func getUserEmail() -> String? {
        getItem(account: emailAccountName)
    }

    // MARK: - GitHub PAT

    @discardableResult
    static func saveGitHubPAT(_ pat: String) -> Bool {
        saveItem(account: githubPATAccountName, value: pat)
    }

    static func getGitHubPAT() -> String? {
        getItem(account: githubPATAccountName)
    }

    @discardableResult
    static func deleteGitHubPAT() -> Bool {
        deleteItem(account: githubPATAccountName)
    }

    static var hasGitHubPAT: Bool {
        getGitHubPAT() != nil
    }

    // MARK: - Shared

    @discardableResult
    static func delete() -> Bool {
        deleteItem(account: accountName)
        deleteItem(account: orgAccountName)
        deleteItem(account: emailAccountName)
        deleteItem(account: githubPATAccountName)
        return true
    }

    static var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    static func isValidKeyFormat(_ key: String) -> Bool {
        !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Private

    private static func saveItem(account: String, value: String) -> Bool {
        deleteItem(account: account)
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private static func getItem(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func deleteItem(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
