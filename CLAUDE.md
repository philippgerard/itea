# CLAUDE.md

This file provides context for Claude Code when working on the iTea project.

## Project Overview

iTea is a native iOS/macOS client for self-hosted Gitea instances. It's built with SwiftUI and uses Mac Catalyst to run on macOS from a single codebase.

## Architecture

```
iTea/
├── GiteaApp.swift              # App entry point
├── Core/
│   ├── Authentication/         # Auth state & secure storage
│   ├── Configuration/          # App constants
│   ├── Navigation/             # Deep link handling
│   └── Networking/             # API client & endpoints
├── Models/                     # Data models (Codable, Sendable)
├── Services/                   # API wrappers by domain
├── Utilities/                  # Helpers (Keychain, URL parsing)
└── Views/
    ├── App/                    # Root views (ContentView, MainTabView)
    ├── Authentication/         # Login flow
    ├── Components/             # Reusable UI components
    ├── Issues/                 # Issue list, detail, create
    ├── Notifications/          # Notification list
    ├── PullRequests/           # PR list, detail, create
    ├── Repositories/           # Repository list, detail
    └── Settings/               # Settings, licenses
```

## Key Patterns

### Platform-Specific Code
Use conditional compilation for iOS vs macOS differences:
```swift
#if targetEnvironment(macCatalyst)
macOSLayout
#else
iOSLayout
#endif
```

### Mac Catalyst Gotchas
- Uses **UIKit**, not AppKit: `Color(uiColor: .separator)` not `Color(nsColor:)`
- NavigationStack toolbar buttons get cramped - use custom VStack layouts for modals
- Sheets need `.presentationSizing(.fitted)` to respect custom frame sizes
- Keyboard shortcuts: `.keyboardShortcut(.cancelAction)` for Cancel, `.keyboardShortcut(.defaultAction)` for primary action

### State Management
- `@StateObject` / `@EnvironmentObject` for `AuthenticationManager`
- `@Observable` for newer patterns like `DeepLinkHandler`
- `Actor` for thread-safe storage (`TokenStorage`)

### Services Pattern
Each domain has a Service that wraps `APIClient`:
```swift
struct IssueService {
    let apiClient: APIClient

    func getIssues(...) async throws -> [Issue] {
        try await apiClient.request(.listIssues(...))
    }
}
```

### Models
All models conform to: `Codable, Identifiable, Hashable, Sendable`

## Build Commands

```bash
# Build for Mac Catalyst
xcodebuild -project "iTea.xcodeproj" \
  -scheme "iTea" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  build

# Build for iOS Simulator
xcodebuild -project "iTea.xcodeproj" \
  -scheme "iTea" \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  build
```

## Git Notes

- GitHub: `https://github.com/philippgerard/itea`
- GPG signing may fail - use `--no-gpg-sign` if needed

## Adding New Features

### New API Endpoint
1. Add endpoint case to `Core/Networking/APIEndpoint.swift`
2. Add method to appropriate Service in `Services/`
3. Call from View using `async/await`

### New View
1. Create in appropriate `Views/` subdirectory
2. For modals on macOS, create separate `macOSLayout` and `iOSLayout` computed properties
3. Use `.presentationSizing(.fitted)` on sheets for macOS

### New Model
1. Create in `Models/`
2. Conform to `Codable, Identifiable, Hashable, Sendable`
3. Use `CodingKeys` if API field names differ

## Dependencies

- **MarkdownUI** (`swift-markdown-ui`) - Markdown rendering in issues/PRs/comments

## File Naming

- Views: `*View.swift` (e.g., `IssueListView.swift`, `CreateIssueView.swift`)
- Row views: `*RowView.swift` (e.g., `IssueRowView.swift`)
- Services: `*Service.swift`
- Models: Singular noun (e.g., `Issue.swift`, `PullRequest.swift`)

## Testing the App

Requires:
- A Gitea server URL
- A personal access token with scopes: `read:user`, `read:repository`, `read:issue`, `write:issue`, `read:notification`, `write:notification`

## App Store Submission

Key files for submission:
- `PrivacyInfo.xcprivacy` - Privacy manifest (required iOS 17+)
- `PRIVACY.md` - Privacy policy (hosted on GitHub)
- `Info.plist` - Includes `ITSAppUsesNonExemptEncryption: false` and `NSAllowsArbitraryLoads: true`

Display name: **iTea** (set in project build settings, not Info.plist)
