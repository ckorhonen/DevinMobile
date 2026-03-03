import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    var apiKeyInput = ""
    var hasValidKey = false
    var isSaving = false
    var errorMessage: String?
    var secrets: [Secret] = []
    var secretsLoadingState: LoadingState<[Secret]> = .idle
    var showDeleteKeyConfirmation = false
    var userEmail: String?
    var maskedAPIKey: String?

    func checkExistingKey() {
        hasValidKey = KeychainService.hasAPIKey
        userEmail = KeychainService.getUserEmail()
        if let key = KeychainService.getAPIKey(), key.count > 12 {
            maskedAPIKey = "\(key.prefix(8))...\(key.suffix(4))"
        } else {
            maskedAPIKey = nil
        }
    }

    func saveAPIKey() -> Bool {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard KeychainService.isValidKeyFormat(key) else {
            errorMessage = "API key cannot be empty"
            return false
        }

        if KeychainService.save(apiKey: key) {
            hasValidKey = true
            errorMessage = nil
            return true
        } else {
            errorMessage = "Failed to save to Keychain"
            return false
        }
    }

    func deleteAPIKey() {
        KeychainService.delete()
        hasValidKey = false
        apiKeyInput = ""
    }

    func loadSecrets() async {
        secretsLoadingState = .loading
        do {
            let response: [Secret] = try await APIClient.shared.perform(.listSecrets)
            secrets = response
            secretsLoadingState = .loaded(secrets)
        } catch let error as DevinAPIError {
            secretsLoadingState = .error(ErrorInfo(error))
        } catch {
            secretsLoadingState = .error(ErrorInfo(message: error.localizedDescription))
        }
    }

    func deleteSecret(id: String) async {
        do {
            try await APIClient.shared.performVoid(.deleteSecret(id: id))
            secrets.removeAll { $0.id == id }
            secretsLoadingState = .loaded(secrets)
        } catch {
            // Silent fail
        }
    }
}
