# Fastlane setup for iTea

This Fastlane configuration manages App Store Connect **metadata and screenshots** for iTea on both iOS and Mac (Catalyst).

Out of scope (do these via Xcode for now): building binaries, code signing, TestFlight uploads, review submission.

---

## 1. Install Fastlane via Bundler

From the repo root:

```bash
bundle install
```

Then prefix every Fastlane command with `bundle exec`:

```bash
bundle exec fastlane ios upload_metadata
```

This uses the version pinned in `Gemfile`, not whatever you have via Homebrew. Reproducible across machines.

---

## 2. Share the Xcode scheme

Fastlane requires a **shared** scheme.

1. Open `iTea.xcodeproj` in Xcode
2. **Product → Scheme → Manage Schemes…**
3. Tick the **Shared** checkbox next to `iTea`
4. Commit the resulting `iTea.xcodeproj/xcshareddata/xcschemes/iTea.xcscheme`

(The previous `.gitignore` excluded shared schemes. This setup removed that exclusion.)

---

## 3. Create the App Store Connect API key

1. Sign in at https://appstoreconnect.apple.com
2. **Users and Access → Integrations → App Store Connect API → Team Keys**
3. Click **+** to generate a key
4. Name: e.g. `Fastlane local`
5. Access: **App Manager** (sufficient for metadata; use **Admin** if you also want `produce` to create new apps)
6. Download `AuthKey_XXXXXXXX.p8` — you can only download it once
7. Note the **Key ID** (10 chars) and **Issuer ID** (UUID) shown on the page

Drop the `.p8` file into `fastlane/.private/` keeping its original `AuthKey_<KEY_ID>.p8` filename:

```bash
mv ~/Downloads/AuthKey_ABCDEFGHIJ.p8 fastlane/.private/
```

The Fastfile parses the Key ID out of the filename automatically — no env var needed for that.

Copy the env template and paste in the Issuer ID:

```bash
cp fastlane/.env.example fastlane/.env
# edit fastlane/.env and set ASC_API_ISSUER_ID
```

Both `fastlane/.private/` and `fastlane/.env` are gitignored.

---

## 4. Set up screenshot automation

The Swift sources for the UI tests already exist at `iTeaUITests/iTeaUITests.swift`. To make Xcode actually compile and run them, you need three Xcode-UI steps plus one helper file.

### 4a. Add the UI test target

1. Open `iTea.xcodeproj` in Xcode
2. **File → New → Target… → iOS → UI Testing Bundle**
3. Product Name: `iTeaUITests` — Target to be Tested: `iTea`
4. Xcode creates a default `iTeaUITestsLaunchTests.swift` (or similar) inside the new group. **Delete** that auto-generated file
5. If the pre-written `iTeaUITests/iTeaUITests.swift` doesn't appear in the project navigator, right-click the `iTeaUITests` group → **Add Files to "iTea"…** → select it and tick the `iTeaUITests` target

### 4b. Add SnapshotHelper.swift

From repo root:

```bash
bundle exec fastlane snapshot init
```

This drops `SnapshotHelper.swift` into the current directory. Move it into `iTeaUITests/`:

```bash
mv SnapshotHelper.swift iTeaUITests/
```

In Xcode: right-click the `iTeaUITests` group → **Add Files to "iTea"…** → select `SnapshotHelper.swift` → ensure **Target Membership** is `iTeaUITests` only.

### 4c. Share the UI test scheme

**Product → Scheme → Manage Schemes…** → tick **Shared** next to `iTeaUITests`. Commit the resulting `iTea.xcodeproj/xcshareddata/xcschemes/iTeaUITests.xcscheme`.

### 4d. Provide demo Gitea credentials

The UI test auto-logs the app in via launch arguments — no manual login on every run. Credentials come from env vars that fastlane loads from `fastlane/.env.snapshot`:

```bash
cp fastlane/.env.snapshot.example fastlane/.env.snapshot
# edit fastlane/.env.snapshot with your demo Gitea URL + PAT
```

For a screenshot run the token only needs read scopes: `read:user`, `read:repository`, `read:issue`, `read:notification`.

`fastlane/.env.snapshot` is gitignored; the `.example` file is committed.

### 4e. Run

```bash
bundle exec fastlane --env snapshot ios screenshots
```

`snapshot` boots iPhone 17 Pro Max + iPad Pro 13" simulators in parallel, runs `iTeaUITests.test_appScreenshots`, and writes PNGs to `fastlane/screenshots/en-US/`.

### How the auto-login works

`AuthenticationManager.loadStoredCredentials()` checks for `-UITestingServerURL` and `-UITestingToken` launch arguments before reading the Keychain. The UI test reads `UITESTING_SERVER_URL` / `UITESTING_TOKEN` from the environment and forwards them to the app as launch args. Nothing is persisted to the Keychain during screenshot runs.

To screenshot the **login screen instead**, leave `UITESTING_SERVER_URL` empty and the app boots in its normal unauthenticated state.

### Mac screenshots

`snapshot` only targets iOS Simulator. For Mac Catalyst:

- Run the app on your Mac, take screenshots manually (⇧⌘4 or Screenshot.app)
- Save to `fastlane/screenshots_mac/en-US/` at one of: **1280×800**, **1440×900**, **2560×1600**, or **2880×1800**

---

## 5. Create the App Store Connect listing (once, if not already done)

Skip if you already created the iTea app in App Store Connect.

```bash
bundle exec fastlane ios create_app
```

This calls `produce` to register the bundle ID and create the app entry on both platforms.

---

## 6. Fill in metadata

Edit the `.txt` files in:

- `fastlane/metadata/en-US/` and `fastlane/metadata/` — iOS
- `fastlane/metadata_mac/en-US/` and `fastlane/metadata_mac/` — Mac

Apple's character limits (in parentheses):

| File                          | Field                         | Limit       |
| ----------------------------- | ----------------------------- | ----------- |
| `name.txt`                    | App name                      | 30          |
| `subtitle.txt`                | Subtitle                      | 30          |
| `description.txt`             | Description                   | 4000        |
| `keywords.txt`                | Keywords (comma-separated)    | 100         |
| `release_notes.txt`           | What's New                    | 4000        |
| `promotional_text.txt`        | Promotional text              | 170         |
| `support_url.txt`             | Support URL                   | URL         |
| `marketing_url.txt`           | Marketing URL                 | URL         |
| `copyright.txt`               | Copyright                     | -           |
| `primary_category.txt`        | Primary category              | enum (\*)   |
| `secondary_category.txt`      | Secondary category (optional) | enum        |
| `review_information/*.txt`    | Reviewer contact + demo creds | -           |

(\*) Valid category values are upper-snake-case, e.g. `DEVELOPER_TOOLS`, `PRODUCTIVITY`. Full list in [fastlane source](https://github.com/fastlane/fastlane/blob/master/deliver/lib/deliver/app_screenshot.rb) or the App Store Connect UI.

Don't forget `review_information/notes.txt` — that's where you tell the App Review reviewer how to test against your demo Gitea instance.

---

## 7. Dry-run

```bash
bundle exec fastlane ios verify_metadata
```

`precheck` catches obvious problems (trademark mentions, broken URLs, character overflow) before you upload.

---

## 8. Upload

```bash
bundle exec fastlane ios upload_metadata
bundle exec fastlane mac upload_metadata
```

These push metadata + screenshots into the corresponding platform of your App Store Connect listing. They do **not** upload a binary and do **not** submit for review.

When you're ready to ship, archive in Xcode → upload to App Store Connect → click "Submit for Review" in the ASC web UI.
