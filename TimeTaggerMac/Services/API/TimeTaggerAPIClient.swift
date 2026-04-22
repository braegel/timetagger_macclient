import Foundation

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class TimeTaggerAPIClient: TimeTaggerAPIClientProtocol {
    private let baseURL: URL
    private let token: String
    private let session: URLSessionProtocol

    init(baseURL: String, token: String, session: URLSessionProtocol = URLSession.shared) throws {
        guard baseURL.hasPrefix("https://") else { throw APIError.insecureURL }
        guard let url = URL(string: baseURL) else { throw APIError.networkError("Invalid URL") }
        self.baseURL = url
        self.token = token
        self.session = session
    }

    func fetchRecords(from: Date, to: Date) async throws -> [TimeRecord] {
        let t1 = Int(from.timeIntervalSince1970)
        let t2 = Int(to.timeIntervalSince1970)
        let url = baseURL.appendingPathComponent("records")
            .appending(queryItems: [URLQueryItem(name: "timerange", value: "\(t1)-\(t2)")])
        let data = try await perform(request: makeRequest(url: url, method: "GET"))
        let response = try decode(RecordsResponse.self, from: data)
        return response.records
    }

    func createRecord(_ record: TimeRecord) async throws -> TimeRecord {
        let url = baseURL.appendingPathComponent("records/\(record.key)")
        let body = try JSONEncoder().encode(record)
        let data = try await perform(request: makeRequest(url: url, method: "PUT", body: body))
        return try decode(TimeRecord.self, from: data)
    }

    func updateRecord(_ record: TimeRecord) async throws -> TimeRecord {
        try await createRecord(record)
    }

    func deleteRecord(key: String) async throws {
        let url = baseURL.appendingPathComponent("records/\(key)")
        _ = try await perform(request: makeRequest(url: url, method: "DELETE"))
    }

    // MARK: - Helpers

    private func makeRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        return req
    }

    private func perform(request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError("No HTTP response")
        }
        switch http.statusCode {
        case 200...299: return data
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        default: throw APIError.serverError(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decodingFailed(error.localizedDescription)
        }
    }
}

extension TimeTaggerAPIClient {
    static func generateKey() -> String {
        let ms = Int(Date().timeIntervalSince1970 * 1000)
        let hex = String(format: "%06x", Int.random(in: 0..<0xFFFFFF))
        return "t\(ms)-\(hex)"
    }
}
