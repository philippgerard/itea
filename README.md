# iTea

A native iOS and macOS client for self-hosted [Gitea](https://gitea.io) instances.

## Features

- **Repositories** - Browse your repositories, view files, and manage subscriptions
- **Issues** - Create, view, and comment on issues
- **Pull Requests** - Create, review, and comment on pull requests
- **Notifications** - Stay up to date with your Gitea notifications
- **Deep Links** - Open Gitea URLs directly in the app (PR creation links, issues, etc.)
- **Dark Mode** - Full support for light, dark, and tinted app icons

## Requirements

- iOS 18.0+ / macOS 15.0+ (Mac Catalyst)
- A self-hosted Gitea instance
- A personal access token with appropriate scopes

## Getting Started

1. Open your Gitea instance in a browser
2. Navigate to **Settings → Applications**
3. Create a new access token with these scopes:
   - `read:user`
   - `read:repository`
   - `read:issue`, `write:issue`
   - `read:notification`, `write:notification`
4. Launch iTea and enter your server URL and token

## Building

Open `Gitea for iOS.xcodeproj` in Xcode 16+ and build for your target device.

### Dependencies

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) - Markdown rendering

## Privacy

iTea does not collect any data. Your credentials are stored securely in the iOS/macOS Keychain and are only used to communicate with your specified Gitea server.

See [Privacy Policy](PRIVACY.md) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Gitea](https://gitea.io) - The self-hosted Git service this app connects to
- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) - Markdown rendering

---

*iTea is not affiliated with or endorsed by the Gitea project.*
