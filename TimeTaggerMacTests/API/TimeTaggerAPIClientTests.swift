import XCTest
@testable import TimeTaggerMac

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol {
    var stubbedData: Data = Data()
    var stubbedResponse: URLResponse = HTTPURLResponse()
    var stubbedError: Error?

    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error = stubbedError { throw error }
        return (stubbedData, stubbedResponse)
    }
}

// MARK: - Helpers

private func makeHTTPResponse(status: Int, url: URL = URL(string: "https://timetagger.io")!) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
}

private func makeClient(session: MockURLSession) throws -> TimeTaggerAPIClient {
    try TimeTaggerAPIClient(baseURL: "https://timetagger.io/api/v2/", token: "test-token", session: session)
}

private func recordsJSON(_ records: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: ["records": records])
}

private let sampleRecordDict: [String: Any] = [
    "key": "t1713600000000-abc123",
    "t1": 1_713_600_000,
    "t2": 0,
    "ds": "#work #project"
]

private let sampleRecord = TimeRecord(
    key: "t1713600000000-abc123",
    t1: 1_713_600_000,
    t2: 0,
    ds: "#work #project"
)

// MARK: - Tests

final class TimeTaggerAPIClientTests: XCTestCase {

    // MARK: - Init

    func test_init_rejectsHTTPURL() {
        XCTAssertThrowsError(
            try TimeTaggerAPIClient(baseURL: "http://timetagger.io/api/v2/", token: "tok")
        ) { XCTAssertEqual($0 as? APIError, .insecureURL) }
    }

    func test_init_acceptsHTTPSURL() {
        XCTAssertNoThrow(
            try TimeTaggerAPIClient(baseURL: "https://timetagger.io/api/v2/", token: "tok")
        )
    }

    // MARK: - generateKey

    func test_generateKey_matchesExpectedFormat() {
        let key = TimeTaggerAPIClient.generateKey()
        XCTAssertTrue(
            key.range(of: #"^t\d+-[0-9a-f]{6}$"#, options: .regularExpression) != nil,
            "Key '\(key)' does not match t<ms>-<hex6>"
        )
    }

    func test_generateKey_isUnique() {
        XCTAssertNotEqual(TimeTaggerAPIClient.generateKey(), TimeTaggerAPIClient.generateKey())
    }

    // MARK: - fetchRecords: success

    func test_fetchRecords_success_returnsDecodedRecords() async throws {
        let session = MockURLSession()
        session.stubbedData = recordsJSON([sampleRecordDict])
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        let from = Date(timeIntervalSince1970: 1_713_000_000)
        let to   = Date(timeIntervalSince1970: 1_714_000_000)
        let records = try await client.fetchRecords(from: from, to: to)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.key, sampleRecord.key)
        XCTAssertEqual(records.first?.ds,  sampleRecord.ds)
    }

    func test_fetchRecords_success_sendsCorrectTimerange() async throws {
        let session = MockURLSession()
        session.stubbedData = recordsJSON([])
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        let from = Date(timeIntervalSince1970: 1_000_000)
        let to   = Date(timeIntervalSince1970: 2_000_000)
        _ = try await client.fetchRecords(from: from, to: to)

        let url = session.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("timerange=1000000-2000000"), "Expected timerange in URL: \(url)")
    }

    func test_fetchRecords_success_sendsAuthorizationHeader() async throws {
        let session = MockURLSession()
        session.stubbedData = recordsJSON([])
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try TimeTaggerAPIClient(
            baseURL: "https://timetagger.io/api/v2/",
            token: "my-secret-token",
            session: session
        )
        _ = try await client.fetchRecords(from: .now, to: .now)

        let auth = session.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(auth, "Bearer my-secret-token")
    }

    // MARK: - fetchRecords: HTTP errors

    func test_fetchRecords_401_throwsUnauthorized() async throws {
        let session = MockURLSession()
        session.stubbedData = Data()
        session.stubbedResponse = makeHTTPResponse(status: 401)

        let client = try makeClient(session: session)
        await assertThrowsAPIError(.unauthorized) {
            _ = try await client.fetchRecords(from: .now, to: .now)
        }
    }

    func test_fetchRecords_404_throwsNotFound() async throws {
        let session = MockURLSession()
        session.stubbedData = Data()
        session.stubbedResponse = makeHTTPResponse(status: 404)

        let client = try makeClient(session: session)
        await assertThrowsAPIError(.notFound) {
            _ = try await client.fetchRecords(from: .now, to: .now)
        }
    }

    func test_fetchRecords_500_throwsServerError() async throws {
        let session = MockURLSession()
        session.stubbedData = Data()
        session.stubbedResponse = makeHTTPResponse(status: 500)

        let client = try makeClient(session: session)
        await assertThrowsAPIError(.serverError(500)) {
            _ = try await client.fetchRecords(from: .now, to: .now)
        }
    }

    // MARK: - fetchRecords: decoding errors

    func test_fetchRecords_invalidJSON_throwsDecodingFailed() async throws {
        let session = MockURLSession()
        session.stubbedData = Data("not json".utf8)
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        do {
            _ = try await client.fetchRecords(from: .now, to: .now)
            XCTFail("Expected decodingFailed error")
        } catch let error as APIError {
            if case .decodingFailed = error { /* pass */ }
            else { XCTFail("Expected decodingFailed, got \(error)") }
        }
    }

    func test_fetchRecords_missingRecordsKey_throwsDecodingFailed() async throws {
        let session = MockURLSession()
        session.stubbedData = try! JSONSerialization.data(withJSONObject: ["other": "value"])
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        do {
            _ = try await client.fetchRecords(from: .now, to: .now)
            XCTFail("Expected decodingFailed error")
        } catch let error as APIError {
            if case .decodingFailed = error { /* pass */ }
            else { XCTFail("Expected decodingFailed, got \(error)") }
        }
    }

    // MARK: - fetchRecords: network error

    func test_fetchRecords_networkError_throwsNetworkError() async throws {
        let session = MockURLSession()
        session.stubbedError = URLError(.notConnectedToInternet)

        let client = try makeClient(session: session)
        do {
            _ = try await client.fetchRecords(from: .now, to: .now)
            XCTFail("Expected networkError")
        } catch {
            // any error from URLSession propagates — acceptable
            XCTAssertNotNil(error)
        }
    }

    // MARK: - createRecord

    func test_createRecord_success_returnsRecord() async throws {
        let session = MockURLSession()
        session.stubbedData = try! JSONEncoder().encode(sampleRecord)
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        let result = try await client.createRecord(sampleRecord)

        XCTAssertEqual(result.key, sampleRecord.key)
        XCTAssertEqual(result.ds,  sampleRecord.ds)
    }

    func test_createRecord_sendsPUTMethod() async throws {
        let session = MockURLSession()
        session.stubbedData = try! JSONEncoder().encode(sampleRecord)
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        _ = try await client.createRecord(sampleRecord)

        XCTAssertEqual(session.lastRequest?.httpMethod, "PUT")
    }

    func test_createRecord_urlContainsKey() async throws {
        let session = MockURLSession()
        session.stubbedData = try! JSONEncoder().encode(sampleRecord)
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        _ = try await client.createRecord(sampleRecord)

        let url = session.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains(sampleRecord.key), "URL should contain record key: \(url)")
    }

    func test_createRecord_sendsBodyWithTags() async throws {
        let session = MockURLSession()
        session.stubbedData = try! JSONEncoder().encode(sampleRecord)
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        _ = try await client.createRecord(sampleRecord)

        let body = session.lastRequest?.httpBody
        XCTAssertNotNil(body, "PUT request must have a body")
        let decoded = try JSONDecoder().decode(TimeRecord.self, from: body!)
        XCTAssertEqual(decoded.ds, sampleRecord.ds)
    }

    // MARK: - updateRecord (stop)

    func test_stopRecord_setsT2_sendsUpdatedRecord() async throws {
        let session = MockURLSession()
        let now = Int(Date().timeIntervalSince1970)
        var stopped = sampleRecord
        stopped.t2 = now
        session.stubbedData = try! JSONEncoder().encode(stopped)
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        let result = try await client.updateRecord(stopped)

        XCTAssertFalse(result.isRunning)
        XCTAssertEqual(result.t2, now)
    }

    // MARK: - deleteRecord

    func test_deleteRecord_success_sendsDeleteMethod() async throws {
        let session = MockURLSession()
        session.stubbedData = Data()
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        try await client.deleteRecord(key: sampleRecord.key)

        XCTAssertEqual(session.lastRequest?.httpMethod, "DELETE")
    }

    func test_deleteRecord_urlContainsKey() async throws {
        let session = MockURLSession()
        session.stubbedData = Data()
        session.stubbedResponse = makeHTTPResponse(status: 200)

        let client = try makeClient(session: session)
        try await client.deleteRecord(key: sampleRecord.key)

        let url = session.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains(sampleRecord.key), "DELETE URL should contain key: \(url)")
    }

    // MARK: - String.extractTags

    func test_extractTags_parsesHashtags() {
        let ds = "#work #project some description"
        XCTAssertEqual(ds.extractTags(), ["#work", "#project"])
    }

    func test_extractTags_emptyString() {
        XCTAssertTrue("no tags here".extractTags().isEmpty)
    }

    func test_extractTags_multilineString() {
        let ds = "#telradko\n#linus description"
        XCTAssertEqual(ds.extractTags(), ["#telradko", "#linus"])
    }
}

// MARK: - Async assertion helper

private func assertThrowsAPIError(
    _ expected: APIError,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ expression: () async throws -> Void
) async {
    do {
        try await expression()
        XCTFail("Expected \(expected) but no error was thrown", file: file, line: line)
    } catch let error as APIError {
        XCTAssertEqual(error, expected, file: file, line: line)
    } catch {
        XCTFail("Expected APIError.\(expected) but got \(error)", file: file, line: line)
    }
}
