import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.logout) private var logout

    var body: some View {
        NavigationStack {
            List {
                Section("API Key") {
                    if viewModel.hasValidKey {
                        HStack {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Button("Remove", role: .destructive) {
                                viewModel.showDeleteKeyConfirmation = true
                            }
                            .font(.caption)
                        }
                    } else {
                        NavigationLink {
                            APIKeySetupView()
                        } label: {
                            Label("Set Up API Key", systemImage: "key")
                        }
                    }
                }

                Section("Organization") {
                    NavigationLink {
                        SecretsListView()
                    } label: {
                        Label("Secrets", systemImage: "lock.shield")
                    }

                    NavigationLink {
                        ConsumptionView()
                    } label: {
                        Label("ACU Consumption", systemImage: "chart.bar")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Remove API Key?", isPresented: $viewModel.showDeleteKeyConfirmation) {
                Button("Remove", role: .destructive) {
                    viewModel.deleteAPIKey()
                    logout()
                }
            } message: {
                Text("You'll need to re-enter your API key to use the app.")
            }
            .onAppear {
                viewModel.checkExistingKey()
            }
        }
    }
}
