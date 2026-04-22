import XCTest
@testable import TimeTaggerMac

@MainActor
final class AppViewModelTests: XCTestCase {

    // MARK: - Initial state: no token

    func test_init_noToken_showsOnboarding() {
        let sut = AppViewModel(keychain: MockKeychainService())

        XCTAssertTrue(sut.showsOnboarding)
    }

    func test_init_noToken_doesNotShowMain() {
        let sut = AppViewModel(keychain: MockKeychainService())

        XCTAssertFalse(sut.showsMain)
    }

    // MARK: - Initial state: token present

    func test_init_tokenExists_doesNotShowOnboarding() {
        let keychain = MockKeychainService()
        try! keychain.save(token: "tok", for: "timetagger.io")
        let sut = AppViewModel(keychain: keychain)

        XCTAssertFalse(sut.showsOnboarding)
    }

    func test_init_tokenExists_showsMain() {
        let keychain = MockKeychainService()
        try! keychain.save(token: "tok", for: "timetagger.io")
        let sut = AppViewModel(keychain: keychain)

        XCTAssertTrue(sut.showsMain)
    }

    // MARK: - Transition: onboarding → main

    func test_onboardingComplete_hidesOnboarding() {
        let sut = AppViewModel(keychain: MockKeychainService())
        XCTAssertTrue(sut.showsOnboarding)

        sut.onboardingViewModel.token = "my-token"
        sut.onboardingViewModel.save()

        XCTAssertFalse(sut.showsOnboarding)
    }

    func test_onboardingComplete_showsMain() {
        let sut = AppViewModel(keychain: MockKeychainService())

        sut.onboardingViewModel.token = "my-token"
        sut.onboardingViewModel.save()

        XCTAssertTrue(sut.showsMain)
    }

    func test_onboardingFailed_staysOnOnboarding() {
        let sut = AppViewModel(keychain: MockKeychainService())

        sut.onboardingViewModel.token = ""
        sut.onboardingViewModel.save()

        XCTAssertTrue(sut.showsOnboarding)
        XCTAssertFalse(sut.showsMain)
    }

    // MARK: - OnboardingViewModel is accessible

    func test_exposes_onboardingViewModel() {
        let sut = AppViewModel(keychain: MockKeychainService())

        XCTAssertNotNil(sut.onboardingViewModel)
    }

    func test_onboardingViewModel_usesInjectedKeychain() {
        let keychain = MockKeychainService()
        let sut = AppViewModel(keychain: keychain)

        sut.onboardingViewModel.token = "tok"
        sut.onboardingViewModel.save()

        XCTAssertEqual(keychain.saveCallCount, 1)
    }

    // MARK: - showsOnboarding and showsMain are mutually exclusive

    func test_showsOnboarding_and_showsMain_areMutuallyExclusive_noToken() {
        let sut = AppViewModel(keychain: MockKeychainService())

        XCTAssertNotEqual(sut.showsOnboarding, sut.showsMain)
    }

    func test_showsOnboarding_and_showsMain_areMutuallyExclusive_withToken() {
        let keychain = MockKeychainService()
        try! keychain.save(token: "tok", for: "timetagger.io")
        let sut = AppViewModel(keychain: keychain)

        XCTAssertNotEqual(sut.showsOnboarding, sut.showsMain)
    }
}
