import SwiftUI

@main
struct TimeTaggerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty MenuBarExtra keeps the SwiftUI lifecycle alive without a Dock icon.
        // The actual UI is driven by AppDelegate's NSStatusItem + NSPopover.
        MenuBarExtra("TimeTagger", systemImage: "clock") {
            ButtonMatrixView()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
