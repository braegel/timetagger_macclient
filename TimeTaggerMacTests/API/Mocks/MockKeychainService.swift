import Foundation
@testable import TimeTaggerMac

final class MockKeychainService: KeychainServiceProtocol {
    private var store: [String: String] = [:]

    var saveCallCount = 0
    var lastSavedToken: String?
    var lastSavedServer: String?
    var saveError: Error?

    func save(token: String, for server: String) throws {
        saveCallCount += 1
        lastSavedToken = token
        lastSavedServer = server
        if let error = saveError { throw error }
        store[server] = token
    }

    func load(for server: String) throws -> String {
        guard let token = store[server] else { throw KeychainError.notFound }
        return token
    }

    func delete(for server: String) throws {
        store[server] = nil
    }
}
