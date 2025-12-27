# Privacy Policy for iTea

**Last updated:** December 27, 2024

## Overview

iTea ("the App") is a client for self-hosted Gitea instances, available for iOS and macOS. We are committed to protecting your privacy and being transparent about how the App handles your data.

## Data Collection

**We do not collect any data.** The App:

- Does not use analytics or tracking
- Does not contain advertising
- Does not transmit any data to us
- Does not use third-party services that collect data

## Data Storage

The App stores the following information **locally on your device only**:

| Data | Purpose | Storage Location |
|------|---------|------------------|
| Server URL | Connect to your Gitea instance | iOS Keychain (encrypted) |
| Access Token | Authenticate with your Gitea instance | iOS Keychain (encrypted) |

This data is:
- Encrypted using iOS Keychain security
- Never transmitted to any party other than your specified Gitea server
- Completely deleted when you sign out

## Network Communication

The App communicates **only** with the Gitea server URL you provide. All communication:

- Uses your access token for authentication
- Is encrypted via HTTPS when your server supports it
- Contains only API requests necessary for app functionality

We have no access to your Gitea server, repositories, issues, or any other data.

## Data Deletion

To delete all data stored by the App:

1. Open the App
2. Go to Settings
3. Tap "Sign Out"

This immediately removes your server URL and access token from the device.

Alternatively, uninstalling the App will remove all stored data.

## Third-Party Services

The App does not integrate with any third-party analytics, advertising, or data collection services.

## Open Source

This App is open source. You can review the source code to verify these privacy practices.

## Children's Privacy

The App does not knowingly collect information from children under 13 years of age.

## Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in the "Last updated" date above.

## Contact

If you have questions about this Privacy Policy, please open an issue on the project repository.

---

*This app is not affiliated with or endorsed by Gitea.*
