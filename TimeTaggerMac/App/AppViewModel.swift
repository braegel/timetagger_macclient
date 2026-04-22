import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var showsOnboarding: Bool
    var showsMain: Bool { !showsOnboarding }

    let onboardingViewModel: OnboardingViewModel
    private var cancellable: AnyCancellable?

    init(keychain: KeychainServiceProtocol) {
        let vm = OnboardingViewModel(keychain: keychain)
        self.onboardingViewModel = vm
        self.showsOnboarding = vm.isOnboardingRequired

        cancellable = vm.$isComplete
            .sink { [weak self] isComplete in
                guard isComplete else { return }
                self?.showsOnboarding = false
            }
    }
}
