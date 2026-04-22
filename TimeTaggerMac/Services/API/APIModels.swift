import Foundation

enum APIError: Error, Equatable {
    case insecureURL
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingFailed(String)
    case networkError(String)
}

struct RecordsResponse: Codable {
    let records: [TimeRecord]
}
