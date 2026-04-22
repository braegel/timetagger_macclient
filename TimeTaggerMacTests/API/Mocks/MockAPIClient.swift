import Foundation
@testable import TimeTaggerMac

final class MockAPIClient: TimeTaggerAPIClientProtocol {
    var fetchRecordsResult: Result<[TimeRecord], Error> = .success([])
    var createRecordResult: Result<TimeRecord, Error>?
    var updateRecordResult: Result<TimeRecord, Error>?
    var deleteRecordError: Error?

    var lastCreatedRecord: TimeRecord?
    var lastUpdatedRecord: TimeRecord?
    var lastDeletedKey: String?

    func fetchRecords(from: Date, to: Date) async throws -> [TimeRecord] {
        try fetchRecordsResult.get()
    }

    func createRecord(_ record: TimeRecord) async throws -> TimeRecord {
        lastCreatedRecord = record
        return try (createRecordResult ?? .success(record)).get()
    }

    func updateRecord(_ record: TimeRecord) async throws -> TimeRecord {
        lastUpdatedRecord = record
        return try (updateRecordResult ?? .success(record)).get()
    }

    func deleteRecord(key: String) async throws {
        lastDeletedKey = key
        if let error = deleteRecordError { throw error }
    }
}
