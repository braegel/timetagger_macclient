import XCTest
@testable import TimeTaggerMac

final class TimeTaggerAPIClientTests: XCTestCase {

    // MARK: - insecureURL

    func test_init_rejectsHTTPURL() throws {
        XCTAssertThrowsError(
            try TimeTaggerAPIClient(baseURL: "http://timetagger.io/api/v2/", token: "tok")
        ) { error in
            XCTAssertEqual(error as? APIError, .insecureURL)
        }
    }

    func test_init_acceptsHTTPSURL() {
        XCTAssertNoThrow(
            try TimeTaggerAPIClient(baseURL: "https://timetagger.io/api/v2/", token: "tok")
        )
    }

    // MARK: - generateKey

    func test_generateKey_matchesExpectedFormat() {
        let key = TimeTaggerAPIClient.generateKey()
        let pattern = #"^t\d+-[0-9a-f]{6}$"#
        XCTAssertTrue(key.range(of: pattern, options: .regularExpression) != nil,
                      "Key '\(key)' does not match expected format t<ms>-<hex6>")
    }

    func test_generateKey_isUnique() {
        let k1 = TimeTaggerAPIClient.generateKey()
        let k2 = TimeTaggerAPIClient.generateKey()
        XCTAssertNotEqual(k1, k2)
    }

    // MARK: - fetchRecords (URLSession mock required — Phase 2)

    // TODO: Phase 2 — add URLSession-protocol-based mock tests
    // test_fetchRecords_success
    // test_fetchRecords_unauthorized
    // test_fetchRecords_invalidJSON
    // test_createRecord_success
    // test_stopRecord_setsT2
    // test_deleteRecord_success
}
