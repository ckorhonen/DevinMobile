import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.logout) private var logout
    @Environment(\.persistenceManager) private var persistence

    var body: some View {
            List {
                Section("API Key") {
                    if viewModel.hasValidKey {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Connected", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    viewModel.showDeleteKeyConfirmation = true
                                }
                                .font(.caption)
                            }
                            if let email = viewModel.userEmail {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if let maskedKey = viewModel.maskedAPIKey {
                                Text(maskedKey)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .monospaced()
                            }
                        }
                    } else {
                        NavigationLink {
                            APIKeySetupView()
                        } label: {
                            Label("Set Up API Key", systemImage: "key")
                        }
                    }
                }

                Section("GitHub") {
                    if viewModel.hasGitHubPAT {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Connected", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    viewModel.showDeleteGitHubPATConfirmation = true
                                }
                                .font(.caption)
                            }
                            if let masked = viewModel.maskedGitHubPAT {
                                Text(masked)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .monospaced()
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add a GitHub token for richer PR details.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            SecureField("ghp_...", text: $viewModel.githubPATInput)
                                .textContentType(.password)

                            Button("Save Token") {
                                _ = viewModel.saveGitHubPAT()
                            }
                            .disabled(viewModel.githubPATInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                Section("Features") {
                    NavigationLink {
                        KnowledgeListView()
                    } label: {
                        Label("Knowledge", systemImage: "book.pages")
                    }

                    NavigationLink {
                        PlaybookListView()
                    } label: {
                        Label("Playbooks", systemImage: "play.rectangle.on.rectangle")
                    }

                    NavigationLink {
                        QuickActionsSettingsView()
                    } label: {
                        Label("Quick Actions", systemImage: "bolt.fill")
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

                Section("Data") {
                    Button("Clear Cache", role: .destructive) {
                        persistence?.clearAllCache()
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
            .confirmationDialog("Remove GitHub Token?", isPresented: $viewModel.showDeleteGitHubPATConfirmation) {
                Button("Remove", role: .destructive) {
                    viewModel.deleteGitHubPAT()
                }
            } message: {
                Text("PR details will no longer be enriched with GitHub data.")
            }
            .onAppear {
                viewModel.checkExistingKey()
            }
    }
}
