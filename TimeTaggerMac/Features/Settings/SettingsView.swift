import SwiftUI

struct SettingsView: View {
    @State private var baseURL: String = LocalSettingsService.shared.settings.baseURL

    var body: some View {
        Form {
            Section("Connection") {
                TextField("API Base URL", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
            }
            Section {
                Text("Full settings — Phase 6")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    SettingsView()
}
