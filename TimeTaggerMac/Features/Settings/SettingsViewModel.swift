import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var baseURL: String = ""
    @Published var isTokenSaved: Bool = false

    // TODO: Phase 6 — full settings implementation
}
