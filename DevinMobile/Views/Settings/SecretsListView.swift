import SwiftUI

struct SecretsListView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        Group {
            switch viewModel.secretsLoadingState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                if viewModel.secrets.isEmpty {
                    ContentUnavailableView {
                        Label("No Secrets", systemImage: "lock.shield")
                    } description: {
                        Text("Organization secrets are managed here.")
                    }
                } else {
                    List {
                        ForEach(viewModel.secrets) { secret in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(secret.key)
                                        .font(.body)
                                        .fontWeight(.medium)

                                    HStack(spacing: 8) {
                                        Text(secret.type.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(.quaternary)
                                            .clipShape(Capsule())

                                        if let note = secret.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()

                                if secret.isSensitive == true {
                                    Image(systemName: "eye.slash")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteSecret(id: secret.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            case .error(let info):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: info.systemImage)
                } description: {
                    Text(info.message)
                } actions: {
                    Button(info.actionLabel) {
                        Task { await viewModel.loadSecrets() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Secrets")
        .task {
            await viewModel.loadSecrets()
        }
    }
}
