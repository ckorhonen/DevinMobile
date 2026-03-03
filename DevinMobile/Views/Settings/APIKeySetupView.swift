import SwiftUI

struct APIKeySetupView: View {
    var onConnected: (() -> Void)?

    @State private var viewModel = SettingsViewModel()
    @State private var emailInput = ""
    @State private var showKey = false
    @State private var isConnecting = false
    @State private var connectionError: String?
    @Environment(\.dismiss) private var dismiss

    private var canConnect: Bool {
        !viewModel.apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "key.horizontal")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Connect to Devin")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Enter your API key and email to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                HStack {
                    Group {
                        if showKey {
                            TextField("API key", text: $viewModel.apiKeyInput)
                        } else {
                            SecureField("API key", text: $viewModel.apiKeyInput)
                        }
                    }
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)

                TextField("Your email", text: $emailInput)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)

                if let error = connectionError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    connect()
                } label: {
                    Group {
                        if isConnecting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Connect")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .disabled(!canConnect || isConnecting)

                Link("Where do I find my API key?",
                     destination: URL(string: "https://app.devin.ai/settings/api-keys")!)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
    }

    private func connect() {
        isConnecting = true
        connectionError = nil

        guard viewModel.saveAPIKey() else {
            connectionError = viewModel.errorMessage ?? "Failed to save key"
            isConnecting = false
            return
        }

        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty {
            KeychainService.saveUserEmail(email)
        }

        // Validate the key by making a test API call
        Task {
            do {
                let _: SessionListResponse = try await APIClient.shared.perform(
                    .listSessions(limit: 1, offset: 0, userEmail: nil)
                )
                await MainActor.run {
                    isConnecting = false
                    if let onConnected {
                        onConnected()
                    } else {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    // Remove the invalid key
                    KeychainService.delete()
                    viewModel.hasValidKey = false
                    connectionError = "Could not connect — check your API key"
                }
            }
        }
    }
}
