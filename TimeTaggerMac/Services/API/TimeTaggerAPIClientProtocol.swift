import Foundation

protocol TimeTaggerAPIClientProtocol {
    func fetchRecords(from: Date, to: Date) async throws -> [TimeRecord]
    func createRecord(_ record: TimeRecord) async throws -> TimeRecord
    func updateRecord(_ record: TimeRecord) async throws -> TimeRecord
    func deleteRecord(key: String) async throws
}
