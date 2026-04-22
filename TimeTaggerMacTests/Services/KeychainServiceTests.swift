import XCTest
@testable import TimeTaggerMac

final class KeychainServiceTests: XCTestCase {
    var sut: KeychainService!
    let testServer = "test.timetagger.io"

    override func setUp() {
        super.setUp()
        sut = KeychainService()
        try? sut.delete(for: testServer)
    }

    override func tearDown() {
        try? sut.delete(for: testServer)
        super.tearDown()
    }

    func test_saveAndLoad_roundtrip() throws {
        try sut.save(token: "secret123", for: testServer)
        let loaded = try sut.load(for: testServer)
        XCTAssertEqual(loaded, "secret123")
    }

    func test_load_nonExistentKey_throwsNotFound() {
        XCTAssertThrowsError(try sut.load(for: "nonexistent.example.com")) { error in
            XCTAssertEqual(error as? KeychainError, .notFound)
        }
    }

    func test_overwrite_returnsNewValue() throws {
        try sut.save(token: "first", for: testServer)
        try sut.save(token: "second", for: testServer)
        let loaded = try sut.load(for: testServer)
        XCTAssertEqual(loaded, "second")
    }

    func test_delete_thenLoad_throwsNotFound() throws {
        try sut.save(token: "token", for: testServer)
        try sut.delete(for: testServer)
        XCTAssertThrowsError(try sut.load(for: testServer)) { error in
            XCTAssertEqual(error as? KeychainError, .notFound)
        }
    }
}
