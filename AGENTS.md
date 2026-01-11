# AGENTS.md

Instructions for AI coding agents working on the iTea project.

## Project Overview

iTea is a native iOS/macOS client for Gitea (self-hosted Git service). Built with SwiftUI, targeting iOS 26.0+ and macOS via Mac Catalyst.

## Build Commands

```bash
# Build for iOS Simulator (preferred for quick iteration)
xcodebuild -project "iTea.xcodeproj" \
  -scheme "iTea" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  build

# Build for Mac Catalyst
xcodebuild -project "iTea.xcodeproj" \
  -scheme "iTea" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  build

# Clean build folder
xcodebuild -project "iTea.xcodeproj" -scheme "iTea" clean
```

## Testing

No test suite exists yet. When adding tests:
- Create `iTeaTests` target in Xcode
- Place tests in `iTeaTests/` directory
- Run with: `xcodebuild test -project "iTea.xcodeproj" -scheme "iTea" -destination "platform=iOS Simulator,name=iPhone 17 Pro"`

## Linting/Formatting

No SwiftLint or SwiftFormat configured. Follow the code style patterns established in existing files.

## Project Structure

```
iTea/
├── GiteaApp.swift              # @main App entry point
├── Core/
│   ├── Authentication/         # AuthenticationManager, TokenStorage
│   ├── Configuration/          # AppConfiguration constants
│   ├── Design/                 # GlassDesignSystem
│   ├── Navigation/             # DeepLinkHandler (@Observable)
│   └── Networking/             # APIClient, APIEndpoint, APIError
├── Models/                     # Data models (14 files)
├── Services/                   # API service wrappers (6 files)
├── Utilities/                  # Helpers (Keychain, URL parsing)
└── Views/
    ├── App/                    # ContentView, MainTabView
    ├── Authentication/         # LoginView
    ├── Components/             # Reusable UI (8 components)
    ├── Issues/                 # Issue views (5 files)
    ├── Notifications/          # NotificationListView
    ├── PullRequests/           # PR views (5 files)
    ├── Repositories/           # Repository views (3 files)
    ├── Search/                 # SearchView
    └── Settings/               # SettingsView
```

## Code Style Guidelines

### Imports
- Import only what you need: `Foundation` for non-UI, `SwiftUI` for views
- One import per line, alphabetically sorted

### Types and Protocols

- **Models**: Conform to `Codable, Identifiable, Hashable, Sendable`. Use optionals for missing API fields.
- **Services**: `final class` with `Sendable`, wrapping `APIClient`.
- **View Models**: `@MainActor final class` with `ObservableObject`, or `@Observable` for newer patterns.

### SwiftUI Views

Structure views in this order:
1. Dependencies (passed in via `let`)
2. State properties (`@State private var`)
3. Nested types (enums for local state)
4. Body
5. Extracted view properties (`private var someView: some View`)
6. Private methods

**Platform-Specific Code:**
```swift
#if targetEnvironment(macCatalyst)
macOSLayout
#else
iOSLayout
#endif
```

**Mac Catalyst Notes:**
- Uses UIKit, NOT AppKit: `Color(uiColor: .separator)` not `nsColor`
- Sheets need `.presentationSizing(.fitted)` for proper sizing
- Use `.keyboardShortcut(.cancelAction)` for Cancel buttons
- Use `.keyboardShortcut(.defaultAction)` for primary actions

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Views | `*View.swift` | `IssueListView.swift` |
| Row views | `*RowView.swift` | `IssueRowView.swift` |
| Services | `*Service.swift` | `IssueService.swift` |
| Models | Singular noun | `Issue.swift`, `PullRequest.swift` |
| Sheets | `*Sheet.swift` | `EditIssueSheet.swift` |

### Error Handling

Use typed errors conforming to `Error, LocalizedError` with `errorDescription`. Handle errors in views with user feedback via `@State private var errorMessage: String?`

### Async/Await Patterns

Use `Task` for async work in views:
```swift
.task { await loadData() }
.refreshable { await loadData() }
.onChange(of: selectedState) { _, _ in Task { await loadData() } }
```

### API Endpoints

Add new endpoints to `Core/Networking/APIEndpoint.swift` as static functions. Request body structs go at the bottom of the file with `Encodable, Sendable` conformance.

### Comments and Documentation

- Use `///` doc comments for public APIs
- Use `// MARK: -` to organize sections
- Keep inline comments minimal; code should be self-documenting

## Adding New Features

### New API Endpoint
1. Add endpoint case to `Core/Networking/APIEndpoint.swift`
2. Add method to appropriate Service in `Services/`
3. Call from View using `async/await`

### New View
1. Create in appropriate `Views/` subdirectory
2. For modals, create `macOSLayout` and `iOSLayout` computed properties
3. Use `.presentationSizing(.fitted)` on sheets for macOS

### New Model
1. Create in `Models/`
2. Conform to `Codable, Identifiable, Hashable, Sendable`
3. Use `CodingKeys` if API field names differ (decoder uses `convertFromSnakeCase`)

## Dependencies

- **MarkdownUI** (`swift-markdown-ui` >= 2.4.1) - Markdown rendering

## API Reference

Gitea API docs: https://docs.gitea.com/api/1.24/

## Git Notes

- GPG signing may fail - use `--no-gpg-sign` if needed
- Repository: https://github.com/philippgerard/itea
