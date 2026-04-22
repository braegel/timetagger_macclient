import XCTest
@testable import TimeTaggerMac

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    // MARK: - isOnboardingRequired

    func test_isOnboardingRequired_noTokenInKeychain_returnsTrue() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)

        XCTAssertTrue(sut.isOnboardingRequired)
    }

    func test_isOnboardingRequired_tokenExists_returnsFalse() {
        let keychain = MockKeychainService()
        try! keychain.save(token: "existing-token", for: "timetagger.io")
        let sut = OnboardingViewModel(keychain: keychain)

        XCTAssertFalse(sut.isOnboardingRequired)
    }

    // MARK: - Initial state

    func test_initialBaseURL_isTimeTaggerIO() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())

        XCTAssertEqual(sut.baseURL, "https://timetagger.io/api/v2/")
    }

    func test_initialToken_isEmpty() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())

        XCTAssertTrue(sut.token.isEmpty)
    }

    func test_initialErrorMessage_isNil() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())

        XCTAssertNil(sut.errorMessage)
    }

    func test_initialIsComplete_isFalse() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())

        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - save: validation

    func test_save_emptyToken_setsErrorMessage() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = ""

        sut.save()

        XCTAssertNotNil(sut.errorMessage)
    }

    func test_save_emptyToken_doesNotSaveToKeychain() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)
        sut.token = ""

        sut.save()

        XCTAssertEqual(keychain.saveCallCount, 0)
    }

    func test_save_emptyToken_doesNotComplete() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.token = ""

        sut.save()

        XCTAssertFalse(sut.isComplete)
    }

    func test_save_httpURL_setsErrorMessage() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.baseURL = "http://timetagger.io/api/v2/"
        sut.token = "valid-token"

        sut.save()

        XCTAssertNotNil(sut.errorMessage)
    }

    func test_save_httpURL_doesNotSaveToKeychain() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)
        sut.baseURL = "http://timetagger.io/api/v2/"
        sut.token = "valid-token"

        sut.save()

        XCTAssertEqual(keychain.saveCallCount, 0)
    }

    func test_save_blankWhitespaceToken_setsErrorMessage() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = "   "

        sut.save()

        XCTAssertNotNil(sut.errorMessage)
    }

    func test_save_emptyBaseURL_setsErrorMessage() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.baseURL = ""
        sut.token = "valid-token"

        sut.save()

        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - save: success

    func test_save_validInput_savesTokenToKeychain() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = "my-api-token"

        sut.save()

        XCTAssertEqual(keychain.saveCallCount, 1)
        XCTAssertEqual(keychain.lastSavedToken, "my-api-token")
    }

    func test_save_validInput_savesServerFromBaseURL() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = "my-api-token"

        sut.save()

        XCTAssertEqual(keychain.lastSavedServer, "timetagger.io")
    }

    func test_save_selfHostedURL_savesCorrectServer() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)
        sut.baseURL = "https://time.mycompany.com/api/v2/"
        sut.token = "my-api-token"

        sut.save()

        XCTAssertEqual(keychain.lastSavedServer, "time.mycompany.com")
    }

    func test_save_validInput_setsIsComplete() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = "my-api-token"

        sut.save()

        XCTAssertTrue(sut.isComplete)
    }

    func test_save_validInput_clearsErrorMessage() {
        let sut = OnboardingViewModel(keychain: MockKeychainService())
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = "my-api-token"

        sut.save()

        XCTAssertNil(sut.errorMessage)
    }

    func test_save_keychainThrows_setsErrorMessage() {
        let keychain = MockKeychainService()
        keychain.saveError = KeychainError.unhandledError(-1)
        let sut = OnboardingViewModel(keychain: keychain)
        sut.baseURL = "https://timetagger.io/api/v2/"
        sut.token = "my-api-token"

        sut.save()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isComplete)
    }

    // MARK: - trailingSlash normalisation

    func test_save_baseURLWithoutTrailingSlash_normalisesURL() {
        let keychain = MockKeychainService()
        let sut = OnboardingViewModel(keychain: keychain)
        sut.baseURL = "https://timetagger.io/api/v2"
        sut.token = "tok"

        sut.save()

        XCTAssertTrue(sut.baseURL.hasSuffix("/"), "baseURL should end with /")
    }
}
