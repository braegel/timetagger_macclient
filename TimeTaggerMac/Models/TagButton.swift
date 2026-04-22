import Foundation

struct TagButton: Codable, Identifiable, Equatable {
    let id: UUID
    var label: String
    var tags: [String]
    var color: String

    var tagString: String { tags.joined(separator: " ") }
}
