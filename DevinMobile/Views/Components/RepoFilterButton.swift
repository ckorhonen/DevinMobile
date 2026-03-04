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
            Image(systemName: selectedRepo == .all
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
                .font(.title3)
                .foregroundStyle(selectedRepo == .all ? Color.secondary : Color.devinBlue)
        }
    }
}
