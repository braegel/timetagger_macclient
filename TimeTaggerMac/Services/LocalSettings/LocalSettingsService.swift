import Foundation

struct AppSettings: Codable {
    var baseURL: String = "https://timetagger.io/api/v2/"
    var buttons: [TagButton] = AppSettings.defaults
    var showInDock: Bool = false

    static let defaults: [TagButton] = [
        TagButton(id: UUID(), label: "telradko",     tags: ["#telradko"],      color: "#E74C3C"),
        TagButton(id: UUID(), label: "gerald",       tags: ["#gerald"],        color: "#3498DB"),
        TagButton(id: UUID(), label: "linus",        tags: ["#linus"],         color: "#2ECC71"),
        TagButton(id: UUID(), label: "isabella",     tags: ["#isabella"],      color: "#9B59B6"),
        TagButton(id: UUID(), label: "hannah",       tags: ["#hannah"],        color: "#F39C12"),
        TagButton(id: UUID(), label: "freiheit",     tags: ["#freiheit"],      color: "#1ABC9C"),
        TagButton(id: UUID(), label: "leidenschaft", tags: ["#leidenschaft"],  color: "#E67E22"),
        TagButton(id: UUID(), label: "kreativität",  tags: ["#kreativität"],   color: "#EC407A"),
    ]
}

final class LocalSettingsService {
    static let shared = LocalSettingsService()

    private let fileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support
            .appendingPathComponent("TimeTaggerMac", isDirectory: true)
            .appendingPathComponent("settings.json")
    }()

    private(set) var settings: AppSettings = AppSettings()

    private init() {
        Task.detached(priority: .utility) { [self] in
            await self.loadFromDisk()
        }
    }

    @MainActor
    private func loadFromDisk() {
        let url = fileURL
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return }
        settings = decoded
    }

    func save() throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(settings)
        try data.write(to: fileURL, options: .atomic)
    }

    func update(_ block: (inout AppSettings) -> Void) throws {
        block(&settings)
        try save()
    }
}
