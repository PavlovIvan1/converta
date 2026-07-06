import Foundation

private struct GitHubRelease: Decodable {
    let tag_name: String
    let body: String?
    let html_url: String
}

enum UpdateState: Equatable {
    case idle
    case checking
    case upToDate
    case available(version: String, notes: String, url: URL)
    case error(String)
}

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var state: UpdateState = .idle

    func checkForUpdates() async {
        state = .checking
        guard let url = URL(string: "https://api.github.com/repos/\(AppVersion.githubRepo)/releases/latest") else {
            state = .error(L.current.updateCheckerBadURL)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            if Self.isNewer(latestVersion, than: AppVersion.current), let releaseURL = URL(string: release.html_url) {
                state = .available(version: latestVersion, notes: release.body ?? "", url: releaseURL)
            } else {
                state = .upToDate
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    nonisolated static func isNewer(_ candidate: String, than current: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(candidateParts.count, currentParts.count) {
            let a = i < candidateParts.count ? candidateParts[i] : 0
            let b = i < currentParts.count ? currentParts[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
