import Foundation
import Combine

@MainActor
final class ButtonMatrixViewModel: ObservableObject {
    @Published var buttons: [TagButton] = []
    @Published var activeRecord: TimeRecord?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient: TimeTaggerAPIClientProtocol
    private let settings: LocalSettingsService

    init(apiClient: TimeTaggerAPIClientProtocol, settings: LocalSettingsService = .shared) {
        self.apiClient = apiClient
        self.settings = settings
        self.buttons = settings.settings.buttons
    }

    func loadActiveRecord() async {
        // TODO: Phase 5 — fetch today's records, find running one
    }

    func startTracking(button: TagButton) async {
        // TODO: Phase 5
    }

    func stopTracking() async {
        // TODO: Phase 5
    }
}
