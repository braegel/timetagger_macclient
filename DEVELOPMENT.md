# TimeTagger macOS Client — Development Guide

> **For AI agents (Opus 4.7):** Work through phases top-to-bottom. Each phase ends with a `git commit` and optional `git tag`. Never skip a phase. If a test fails, fix it before moving on. Do NOT add features beyond what is specified in the current phase.

---

## Project Overview

A native macOS menu-bar application that interacts with the [TimeTagger](https://timetagger.io) time-tracking API. It shows the currently running timer in the menu bar, opens a popover panel with a configurable button matrix for quick tag-based time tracking.

**Key constraints:**
- Test-Driven Development (TDD): write the test first, then the implementation
- No App Store — distributed as unsigned DMG via GitHub Releases
- No third-party networking libraries — URLSession only
- Minimal dependencies — prefer Swift Standard Library and Apple frameworks
- Local user settings must never be committed to git (see `.gitignore`)

---

## Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| Language | Swift 5.9+ | Native performance, type safety |
| UI | SwiftUI | Declarative, testable ViewModels, macOS 13+ |
| Min macOS | 13.0 (Ventura) | Wide install base, full SwiftUI feature set |
| Testing | XCTest + Swift Testing | Built-in, no extra deps |
| Networking | URLSession | No third-party dep |
| Credential storage | Keychain (Security.framework) | Secure, OS-managed |
| Local config | UserDefaults + JSON file | Simple, gitignored |
| Concurrency | Swift async/await | Modern, safe |
| CI | GitHub Actions | Free for open source |
| Release | Universal binary (arm64 + x86_64) DMG | Covers all Macs since 2006 |

---

## Repository Layout

```
timetagger_macclient/
├── DEVELOPMENT.md              ← this file
├── README.md
├── LICENSE                     (CC BY-SA 4.0)
├── .gitignore                  (local settings excluded)
├── .github/
│   └── workflows/
│       ├── ci.yml              (build + test on every push)
│       └── release.yml         (build universal DMG on tag push)
├── TimeTaggerMac/              ← Xcode project root
│   ├── TimeTaggerMac.xcodeproj
│   ├── TimeTaggerMac/          ← app source
│   │   ├── App/
│   │   │   ├── TimeTaggerMacApp.swift
│   │   │   └── AppDelegate.swift
│   │   ├── Features/
│   │   │   ├── StatusBar/
│   │   │   │   ├── StatusBarController.swift
│   │   │   │   └── StatusBarViewModel.swift
│   │   │   ├── ButtonMatrix/
│   │   │   │   ├── ButtonMatrixView.swift
│   │   │   │   └── ButtonMatrixViewModel.swift
│   │   │   ├── Settings/
│   │   │   │   ├── SettingsView.swift
│   │   │   │   └── SettingsViewModel.swift
│   │   │   └── TagSuggestions/
│   │   │       ├── TagSuggestionsView.swift
│   │   │       └── TagSuggestionsViewModel.swift
│   │   ├── Services/
│   │   │   ├── API/
│   │   │   │   ├── TimeTaggerAPIClient.swift
│   │   │   │   ├── TimeTaggerAPIClientProtocol.swift
│   │   │   │   └── APIModels.swift
│   │   │   ├── Keychain/
│   │   │   │   └── KeychainService.swift
│   │   │   └── LocalSettings/
│   │   │       └── LocalSettingsService.swift
│   │   ├── Models/
│   │   │   ├── TimeRecord.swift
│   │   │   └── TagButton.swift
│   │   └── Resources/
│   │       ├── Assets.xcassets
│   │       └── Info.plist
│   └── TimeTaggerMacTests/     ← unit + integration tests
│       ├── API/
│       │   ├── TimeTaggerAPIClientTests.swift
│       │   └── Mocks/
│       │       └── MockAPIClient.swift
│       ├── Features/
│       │   ├── StatusBarViewModelTests.swift
│       │   ├── ButtonMatrixViewModelTests.swift
│       │   └── TagSuggestionsViewModelTests.swift
│       └── Services/
│           └── KeychainServiceTests.swift
```

---

## TimeTagger API Reference

**Base URL:** `https://timetagger.io/api/v2/`  
**Self-hosted:** `https://<your-domain>/api/v2/`  
**Auth header:** `Authorization: Bearer <api_token>`  
**Content-Type:** `application/json`

The API token is found in the TimeTagger web UI under user settings → "API tokens".

### Endpoints Used

| Method | Path | Purpose |
|---|---|---|
| GET | `/records?timerange=<t1>-<t2>` | Fetch time records in range |
| PUT | `/records/<key>` | Create or update a time record |
| DELETE | `/records/<key>` | Delete a time record |

### TimeRecord JSON Shape

```json
{
  "key": "abc123xyz",
  "t1": 1713600000,
  "t2": 0,
  "ds": "#work #projectname description text"
}
```

- `key`: unique string (generate with UUID-based key on client)
- `t1`: Unix timestamp (seconds), record start
- `t2`: Unix timestamp (seconds), record end; `0` means currently running
- `ds`: description string — tags are `#hashtags` anywhere in the string

### Timerange Format

`timerange` query param: `<unix_start>-<unix_end>` (both seconds).  
Example for last 30 days: `?timerange=1711008000-1713600000`

### Key Generation

Generate record keys as: `t<unix_timestamp_ms>-<random_6_hex>`, e.g. `t1713600000123-a3f7c1`.  
This matches TimeTagger's own key format.

---

## Security Requirements

Apply these throughout **all** phases:

1. **API token in Keychain only** — never in UserDefaults, never in files, never logged
2. **HTTPS always** — reject HTTP base URLs with a clear error
3. **Certificate validation** — do not disable SSL validation under any circumstances
4. **No logging of tokens or record descriptions** — log only anonymized events
5. **Input validation** — sanitize/validate all user-provided strings before sending to API
6. **Gitignore local settings** — `LocalSettings.json`, `*.local.*` are excluded (already in `.gitignore`)
7. **Dependency pinning** — pin all Swift Package dependencies to exact versions

---

## Phase 1 — Project Foundation

**Goal:** Runnable Xcode project, clean architecture skeleton, git history starts here.

### Steps

1. Create a new Xcode project:
   - Template: **macOS → App**
   - Product Name: `TimeTaggerMac`
   - Bundle ID: `net.braegelmann.timetaggermac` (or your domain)
   - Language: Swift
   - Interface: SwiftUI
   - Uncheck "Include Tests" (we'll add the test target manually with the right structure)
   - Save inside `timetagger_macclient/TimeTaggerMac/`

2. Configure `Info.plist`:
   ```xml
   <key>LSUIElement</key><true/>           <!-- no Dock icon -->
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key><false/>
   </dict>
   ```

3. Add a test target:
   - File → New → Target → Unit Testing Bundle
   - Name: `TimeTaggerMacTests`

4. Create the folder structure from the Repository Layout section above (empty Swift files with just the type declaration + `TODO` comment).

5. Set minimum deployment target to **macOS 13.0** in project settings.

6. Verify: `⌘+B` builds cleanly, `⌘+U` runs 0 tests with 0 failures.

### Git Checkpoint

```bash
git add .
git commit -m "feat: initial Xcode project structure"
git tag v0.1.0-foundation
```

---

## Phase 2 — API Models & Client (TDD)

**Goal:** A fully tested API client that can communicate with TimeTagger. The UI does NOT exist yet.

### 2.1 — Write Tests First

In `TimeTaggerMacTests/API/TimeTaggerAPIClientTests.swift`:

```swift
// Tests to implement (TDD order):
// 1. test_fetchRecords_success — mock URLSession returns valid JSON → decoded TimeRecord array
// 2. test_fetchRecords_httpError — 401 response → throws APIError.unauthorized
// 3. test_fetchRecords_invalidJSON — malformed JSON → throws APIError.decodingFailed
// 4. test_createRecord_success — PUT with correct body → returns created TimeRecord
// 5. test_createRecord_rejectsHTTP — http:// URL → throws APIError.insecureURL
// 6. test_stopRecord_success — PUT with t2 set → returns updated TimeRecord
// 7. test_deleteRecord_success — DELETE → completes without error
// 8. test_generateKey_format — key matches pattern t<ms>-<hex6>
```

Use a `MockURLSession` (protocol-based injection) — do NOT make real network calls in unit tests.

### 2.2 — Implement Models

`TimeTaggerMac/Models/TimeRecord.swift`:
```swift
struct TimeRecord: Codable, Equatable, Identifiable {
    var id: String { key }
    let key: String
    let t1: Int       // Unix seconds
    var t2: Int       // 0 = running
    var ds: String    // description with #tags

    var isRunning: Bool { t2 == 0 }
    var tags: [String] { ds.extractTags() }
}
```

`TimeTaggerMac/Models/TagButton.swift`:
```swift
struct TagButton: Codable, Identifiable, Equatable {
    let id: UUID
    var label: String
    var tags: [String]
    var color: String    // hex string e.g. "#4A90D9"
}
```

String extension `extractTags()` — parses `#word` tokens from a string (tested separately).

### 2.3 — Implement the Protocol

`TimeTaggerMac/Services/API/TimeTaggerAPIClientProtocol.swift`:
```swift
protocol TimeTaggerAPIClientProtocol {
    func fetchRecords(from: Date, to: Date) async throws -> [TimeRecord]
    func createRecord(_ record: TimeRecord) async throws -> TimeRecord
    func updateRecord(_ record: TimeRecord) async throws -> TimeRecord
    func deleteRecord(key: String) async throws
}
```

### 2.4 — Implement the Client

`TimeTaggerMac/Services/API/TimeTaggerAPIClient.swift` — implement the protocol using URLSession.  
Inject `URLSession` via constructor for testability.  
Validate that `baseURL` starts with `https://` — throw `APIError.insecureURL` otherwise.

### 2.5 — Error Type

```swift
enum APIError: Error, Equatable {
    case insecureURL
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingFailed(String)
    case networkError(String)
}
```

### Git Checkpoint

All tests must be green before committing.

```bash
git add .
git commit -m "feat: TimeTagger API client with full test coverage"
git tag v0.2.0-api-client
```

---

## Phase 3 — Keychain & Local Settings (TDD)

**Goal:** Secure credential storage + gitignored user preferences.

### 3.1 — Keychain Service

`TimeTaggerMac/Services/Keychain/KeychainService.swift`

```swift
protocol KeychainServiceProtocol {
    func save(token: String, for server: String) throws
    func load(for server: String) throws -> String
    func delete(for server: String) throws
}
```

Implement using `Security.SecItemAdd`, `SecItemCopyMatching`, `SecItemDelete`.  
Service label: `net.braegelmann.timetaggermac`.

Tests in `TimeTaggerMacTests/Services/KeychainServiceTests.swift`:
- Save → Load roundtrip
- Load non-existent key → throws `KeychainError.notFound`
- Overwrite existing → new value returned on next load
- Delete → subsequent load throws `KeychainError.notFound`

### 3.2 — Local Settings Service

`TimeTaggerMac/Services/LocalSettings/LocalSettingsService.swift`

Stores to `Application Support/TimeTaggerMac/settings.json` (NOT in the repo).  
The file path must appear in `.gitignore` — double-check.

```swift
struct AppSettings: Codable {
    var baseURL: String = "https://timetagger.io/api/v2/"
    var buttons: [TagButton] = AppSettings.defaults
    var showInDock: Bool = false

    static let defaults: [TagButton] = [
        TagButton(id: UUID(), label: "telradko",  tags: ["#telradko"],  color: "#E74C3C"),
        TagButton(id: UUID(), label: "gerald",    tags: ["#gerald"],    color: "#3498DB"),
        TagButton(id: UUID(), label: "linus",     tags: ["#linus"],     color: "#2ECC71"),
        TagButton(id: UUID(), label: "isabella",  tags: ["#isabella"],  color: "#9B59B6"),
        TagButton(id: UUID(), label: "hannah",    tags: ["#hannah"],    color: "#F39C12"),
        TagButton(id: UUID(), label: "freiheit",  tags: ["#freiheit"],  color: "#1ABC9C"),
        TagButton(id: UUID(), label: "leidenschaft", tags: ["#leidenschaft"], color: "#E67E22"),
        TagButton(id: UUID(), label: "kreativität",  tags: ["#kreativität"],  color: "#EC407A"),
    ]
}
```

Tests: load defaults on first run, save + reload preserves values, malformed JSON falls back to defaults (does not crash).

### Git Checkpoint

```bash
git add .
git commit -m "feat: Keychain and LocalSettings services"
git tag v0.3.0-services
```

---

## Phase 4 — Menu Bar & App Shell (TDD ViewModels)

**Goal:** App runs in menu bar, shows a popover on click. No actual tracking yet.

### 4.1 — StatusBarViewModel (test first)

Tests:
- `test_statusText_noActiveRecord` → returns `"–"` or clock icon
- `test_statusText_activeRecord` → returns truncated tag string
- `test_statusText_elapsedTime` → after 90 seconds returns `"0:01:30"`

```swift
@MainActor
final class StatusBarViewModel: ObservableObject {
    @Published var statusText: String = "–"
    @Published var activeRecord: TimeRecord?
    // ...
}
```

### 4.2 — App Structure

`TimeTaggerMac/App/TimeTaggerMacApp.swift`:
```swift
@main
struct TimeTaggerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
```

`TimeTaggerMac/App/AppDelegate.swift`:
- Creates `NSStatusItem`
- Attaches `NSPopover` with `ButtonMatrixView` as the content
- Toggles popover on status item click
- Updates status bar title from `StatusBarViewModel`
- Sets `NSApp.setActivationPolicy(.accessory)` to suppress Dock icon

### 4.3 — Popover Shell

`ButtonMatrixView` — placeholder `Text("Button Matrix")` for now.  
`SettingsView` — placeholder with just a "Base URL" text field bound to `AppSettings.baseURL`.

### 4.4 — Onboarding: First-Launch Token Entry

On first launch (no token in Keychain), show a sheet asking for:
1. API base URL (prefilled with `https://timetagger.io/api/v2/`)
2. API token (SecureField)

Validate: URL must start with `https://`. Token must be non-empty.  
On save: store token in Keychain, store URL in `AppSettings`.

### Git Checkpoint

```bash
git add .
git commit -m "feat: menu bar shell, popover, and first-launch onboarding"
git tag v0.4.0-menu-bar
```

---

## Phase 5 — Button Matrix & Time Tracking (TDD)

**Goal:** The core feature — buttons that start/stop/switch time records.

### 5.1 — ButtonMatrixViewModel (test first)

```swift
@MainActor
final class ButtonMatrixViewModel: ObservableObject {
    @Published var buttons: [TagButton]
    @Published var activeRecord: TimeRecord?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Inject API client for testability
    init(apiClient: TimeTaggerAPIClientProtocol, settings: LocalSettingsService)
}
```

Tests to write first:
- `test_startTracking_createsRecord` — tap button → API `createRecord` called with correct tags
- `test_stopTracking_setsT2` — tap active button → API `updateRecord` called with `t2 = now`
- `test_switchTracking_stopsOldStartsNew` — tap different button → stops current, creates new
- `test_startTracking_setsActiveRecord` — after start, `activeRecord` is set
- `test_stopTracking_clearsActiveRecord` — after stop, `activeRecord` is nil
- `test_startTracking_apiError_showsError` — API throws → `errorMessage` is set
- `test_loadActiveRecord_onAppear` — on init, fetches today's records, finds running one

### 5.2 — ButtonMatrixView

```
┌──────────────────────────────────────┐
│  ● telradko  ● gerald   ● linus      │  ← row 1
│  ● isabella  ● hannah   ● freiheit   │  ← row 2
│  ● leidensch ● kreativit             │  ← row 3
│                                      │
│  [■ Stop]        Running: 0:42:17    │
│                                      │
│  ⚙ Settings                          │
└──────────────────────────────────────┘
```

- Active button is highlighted (filled background)
- Running time updates every second via `Timer.publish`
- "Stop" button only shown when a record is active
- Show a spinner on `isLoading`
- Show error banner if `errorMessage` is set (auto-dismiss after 4 s)

### 5.3 — Tag Combination Logic

When a button has multiple tags (e.g. `["#work", "#client-acme"]`), the `ds` field of the created record is those tags joined by a space: `"#work #client-acme"`.

### Git Checkpoint

```bash
git add .
git commit -m "feat: button matrix with start/stop/switch time tracking"
git tag v0.5.0-button-matrix
```

---

## Phase 6 — Tag Suggestions & Configurable Matrix (TDD)

**Goal:** Learn from TimeTagger history, suggest tag combos, let user edit buttons.

### 6.1 — Tag Frequency Analyzer (test first)

`TimeTaggerMac/Features/TagSuggestions/TagSuggestionsViewModel.swift`

Algorithm:
1. Fetch records for the last 90 days
2. For each record, extract the set of `#tags` from `ds`
3. Count occurrences of each unique tag-set (order-insensitive)
4. Return top N combinations sorted by frequency
5. Exclude combinations already present as buttons

Tests:
- `test_topCombinations_correctOrder` — given mock records, returns most frequent first
- `test_topCombinations_excludesExisting` — already-configured buttons not suggested
- `test_topCombinations_emptyRecords` — returns empty array, no crash

### 6.2 — SettingsView (full implementation)

Sections:
1. **Connection** — Base URL field + token field (SecureField) + "Test Connection" button
2. **Button Matrix** — drag-to-reorder list of `TagButton`s (label, tags, color)
   - Add button: opens a sheet to enter label + tags
   - Delete button: swipe-to-delete
   - Reorder: drag handle
3. **Suggestions** — list of top tag combos from history, each with "+ Add as Button" action
4. **About** — version, license link, GitHub link

### 6.3 — Export/Import Buttons Config

Allow exporting `buttons` array as JSON and importing from a JSON file.  
This lets users share button configurations without sharing their token.

### Git Checkpoint

```bash
git add .
git commit -m "feat: tag suggestions and configurable button matrix settings"
git tag v0.6.0-settings
```

---

## Phase 7 — CI/CD & Release Pipeline

**Goal:** Automated builds and universal binary DMG releases on GitHub.

### 7.1 — GitHub Actions: CI

`.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app
      - name: Build and Test
        run: |
          xcodebuild test \
            -project TimeTaggerMac/TimeTaggerMac.xcodeproj \
            -scheme TimeTaggerMac \
            -destination 'platform=macOS' \
            -enableCodeCoverage YES \
            | xcpretty
```

### 7.2 — GitHub Actions: Release

`.github/workflows/release.yml` — triggered by pushing a tag `v*.*.*`:

```yaml
name: Release
on:
  push:
    tags: ['v*.*.*']

jobs:
  build-dmg:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Build Universal Binary
        run: |
          xcodebuild archive \
            -project TimeTaggerMac/TimeTaggerMac.xcodeproj \
            -scheme TimeTaggerMac \
            -archivePath build/TimeTaggerMac.xcarchive \
            -destination 'generic/platform=macOS' \
            ARCHS="arm64 x86_64"
          xcodebuild -exportArchive \
            -archivePath build/TimeTaggerMac.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ExportOptions.plist
      - name: Create DMG
        run: |
          mkdir -p dist
          hdiutil create -volname "TimeTaggerMac" \
            -srcfolder build/export/TimeTaggerMac.app \
            -ov -format UDZO dist/TimeTaggerMac-${{ github.ref_name }}.dmg
      - name: Upload to GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*.dmg
          generate_release_notes: true
```

`ExportOptions.plist` (committed to repo — no sensitive data):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>        <string>developer-id</string>
    <key>signingStyle</key>  <string>automatic</string>
</dict>
</plist>
```

> **Note:** Without an Apple Developer account, use `method = mac-application` (ad-hoc) and document in README that users must right-click → Open to bypass Gatekeeper on first launch.

### 7.3 — README Gatekeeper Note

Add a section to README explaining: since the app is not notarized, on first launch macOS shows a warning. Fix: right-click the app → Open, then click "Open" in the dialog. This is a one-time action.

### Git Checkpoint

```bash
git add .
git commit -m "feat: GitHub Actions CI and release pipeline"
git tag v0.7.0-cicd
```

---

## Phase 8 — Polish & 1.0 Release

**Goal:** Production-ready quality before public announcement.

### Checklist

- [ ] App icon (1024×1024 PNG, all required sizes in Assets.xcassets)
- [ ] Menu bar icon: template image (black, transparent bg) at 18×18 pt (@1x and @2x)
- [ ] Keyboard shortcut to open popover (configurable, default: ⌃⌥T)
- [ ] Accessibility: all buttons have `.accessibilityLabel`
- [ ] Localization ready: all user-facing strings in `Localizable.strings`
- [ ] Error messages are user-friendly (not raw API errors)
- [ ] Unit test coverage ≥ 80% on Services and ViewModels
- [ ] Memory: no retain cycles (verify with Instruments)
- [ ] README complete: installation, screenshots, API token setup guide

### Git Checkpoint

```bash
git add .
git commit -m "feat: polish and accessibility pass"
git tag v1.0.0
git push origin main --tags
```

---

## Phase 9 (Future) — Offline Mode & Sync

> Implement this only after v1.0.0 is stable and released.

**Complexity warning:** Offline sync introduces merge conflicts between local and server state. This must be a separate, well-scoped project phase.

### Planned Approach

1. **Local store:** Use a lightweight JSON file (or SQLite via GRDB) as local record cache
2. **Sync queue:** Mutations while offline are queued as operations
3. **Reachability:** Use `NWPathMonitor` to detect connectivity
4. **Sync on reconnect:** Replay queue; fetch server state; merge
5. **Conflict strategy (simple):** Last-write-wins per record key
6. **Conflict strategy (hard):** If same key modified both locally and remotely, present a "resolve conflict" UI

This phase needs its own design document before implementation.

---

## Working with This Guide

### For AI Agents

- Work exactly one phase at a time
- Confirm all tests pass (`⌘+U`) before moving to the next phase
- Do not refactor code from a previous phase unless tests are failing because of it
- After each phase's git checkpoint, announce the phase number and tag created
- If you encounter an ambiguity not covered here, choose the simpler option and note it in a `TODO:` comment

### Versioning

| Tag | Phase | Description |
|---|---|---|
| v0.1.0 | 1 | Project foundation |
| v0.2.0 | 2 | API client |
| v0.3.0 | 3 | Keychain + settings |
| v0.4.0 | 4 | Menu bar shell |
| v0.5.0 | 5 | Button matrix |
| v0.6.0 | 6 | Tag suggestions |
| v0.7.0 | 7 | CI/CD |
| v1.0.0 | 8 | Production release |

### Running Tests Locally

```bash
xcodebuild test \
  -project TimeTaggerMac/TimeTaggerMac.xcodeproj \
  -scheme TimeTaggerMac \
  -destination 'platform=macOS'
```
