import Foundation

extension PullRequest {
    struct GitHubComponents: Sendable {
        let owner: String
        let repo: String
        let number: Int
    }

    /// Parses the PR URL into structured GitHub components.
    /// Returns nil if the URL is not a valid GitHub PR URL.
    var gitHubComponents: GitHubComponents? {
        guard let urlString = url,
              let url = URL(string: urlString),
              url.host == "github.com" || url.host == "www.github.com"
        else { return nil }

        let parts = url.pathComponents
        // pathComponents for "/org/repo/pull/123" = ["/", "org", "repo", "pull", "123"]
        guard parts.count >= 5,
              parts[3] == "pull",
              let prNumber = Int(parts[4])
        else { return nil }

        return GitHubComponents(owner: parts[1], repo: parts[2], number: prNumber)
    }

    var shortRepoName: String? {
        gitHubComponents?.repo
    }

    var displayLabel: String? {
        guard let number else { return nil }
        return "PR #\(number)"
    }

    /// GitHub iOS app deep link URL (github:// scheme).
    var gitHubAppURL: URL? {
        guard let urlString = url,
              let webURL = URL(string: urlString),
              var components = URLComponents(url: webURL, resolvingAgainstBaseURL: false)
        else { return nil }
        components.scheme = "github"
        return components.url
    }

    /// Standard HTTPS GitHub URL for the PR.
    var gitHubWebURL: URL? {
        guard let urlString = url else { return nil }
        return URL(string: urlString)
    }
}
