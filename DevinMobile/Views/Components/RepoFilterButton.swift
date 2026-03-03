import SwiftUI

struct RepoFilterButton: View {
    let repos: [String]
    @Binding var selectedRepo: RepoFilter

    private var displayText: String {
        switch selectedRepo {
        case .all: "All Repos"
        case .repo(let name): name
        case .noPR: "Other"
        }
    }

    var body: some View {
        Menu {
            Button {
                selectedRepo = .all
            } label: {
                HStack {
                    Text("All Repos")
                    if selectedRepo == .all { Image(systemName: "checkmark") }
                }
            }

            Divider()

            ForEach(repos, id: \.self) { repo in
                Button {
                    selectedRepo = .repo(repo)
                } label: {
                    HStack {
                        Text(repo)
                        if case .repo(let name) = selectedRepo, name == repo {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                selectedRepo = .noPR
            } label: {
                HStack {
                    Text("Other (no PR)")
                    if selectedRepo == .noPR { Image(systemName: "checkmark") }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(displayText)
                    .lineLimit(1)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                selectedRepo == .all
                    ? Color(.systemGray6)
                    : Color.devinBlue.opacity(0.15)
            )
            .foregroundStyle(selectedRepo == .all ? Color.secondary : Color.devinBlue)
            .clipShape(Capsule())
        }
    }
}
