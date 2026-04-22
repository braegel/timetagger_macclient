import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var baseURL: String = "https://timetagger.io/api/v2/"
    @Published var token: String = ""
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false

    private let keychain: KeychainServiceProtocol

    var isOnboardingRequired: Bool {
        let server = URL(string: baseURL)?.host ?? "timetagger.io"
        return (try? keychain.load(for: server)) == nil
    }

    init(keychain: KeychainServiceProtocol) {
        self.keychain = keychain
    }

    func save() {
        if !baseURL.hasSuffix("/") { baseURL += "/" }

        guard !token.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "API token must not be empty."
            return
        }
        guard baseURL.hasPrefix("https://") else {
            errorMessage = "Base URL must start with https://"
            return
        }

        let server = URL(string: baseURL)?.host ?? baseURL
        do {
            try keychain.save(token: token, for: server)
            errorMessage = nil
            isComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
