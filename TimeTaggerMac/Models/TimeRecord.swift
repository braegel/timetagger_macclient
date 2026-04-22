import Foundation

struct TimeRecord: Codable, Equatable, Identifiable {
    var id: String { key }
    let key: String
    let t1: Int
    var t2: Int
    var ds: String

    var isRunning: Bool { t2 == 0 }
    var tags: [String] { ds.extractTags() }

    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(t1)) }
    var endDate: Date? { t2 == 0 ? nil : Date(timeIntervalSince1970: TimeInterval(t2)) }
}

extension String {
    func extractTags() -> [String] {
        let pattern = #"#[^\s#]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(self.startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap {
            Range($0.range, in: self).map { String(self[$0]) }
        }
    }
}
