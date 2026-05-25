#!/usr/bin/env bash
# Capture App Store screenshots from the Mac Catalyst build of iTea.
#
# Builds the app, launches it with -UITesting* launch args (so it auto-logs in
# against the demo Gitea), positions the window at 1440×900, and uses
# screencapture + a Swift CGEvent helper (scripts/click.swift) to grab a PNG
# per screen.
#
# Output: fastlane/screenshots_mac/en-US/0{1..4}_*.png
#
# Requirements:
#   • Accessibility permission for the parent process (Terminal/cmux/etc.)
#   • Screen Recording permission for the parent process
#   • fastlane/.env.snapshot populated with UITESTING_SERVER_URL + _TOKEN

set -euo pipefail
cd "$(dirname "$0")/.."

# Load credentials
set -a
# shellcheck disable=SC1091
source fastlane/.env.snapshot
set +a

OUT="$PWD/fastlane/screenshots_mac/en-US"
mkdir -p "$OUT"

# Window geometry — Apple accepts 1440×900 (and its 2x retina capture 2880×1800)
WIN_X=100
WIN_Y=60
WIN_W=1440
WIN_H=900

# Screen coordinates of sidebar items (measured from a 01_repositories screenshot)
SB_X=255
SB_Y_REPOS=135
SB_Y_NOTIF=182
SB_Y_SEARCH=227
SB_Y_SETTINGS=273

click_at() {
  swift "$PWD/scripts/click.swift" "$1" "$2"
}

capture() {
  local name="$1"
  echo "==> Capturing ${name}"
  screencapture -R "${WIN_X},${WIN_Y},${WIN_W},${WIN_H}" "$OUT/${name}.png"
}

echo "==> Building Mac Catalyst..."
xcodebuild build \
  -project iTea.xcodeproj \
  -scheme iTea \
  -destination "platform=macOS,variant=Mac Catalyst" \
  -configuration Debug \
  -derivedDataPath /tmp/itea-mac \
  > /tmp/itea-mac-build.log 2>&1

APP="/tmp/itea-mac/Build/Products/Debug-maccatalyst/iTea.app"
if [ ! -d "$APP" ]; then
  echo "Build output missing at $APP" >&2
  tail -20 /tmp/itea-mac-build.log >&2
  exit 1
fi

echo "==> Launching iTea with auto-login launch args..."
killall iTea 2>/dev/null || true
sleep 1
open -na "$APP" --args \
  -UITestingServerURL "$UITESTING_SERVER_URL" \
  -UITestingToken "$UITESTING_TOKEN"

sleep 6  # let auto-login complete

echo "==> Positioning window at ${WIN_X},${WIN_Y} size ${WIN_W}×${WIN_H}..."
osascript <<APPSC
tell application "System Events"
  tell process "iTea"
    set frontmost to true
    repeat until (exists window 1)
      delay 0.5
    end repeat
    set position of window 1 to {${WIN_X}, ${WIN_Y}}
    set size of window 1 to {${WIN_W}, ${WIN_H}}
  end tell
end tell
APPSC

sleep 2

# 01 — Repositories (default selected after launch)
capture "01_repositories"

# 02 — Notifications
click_at "$SB_X" "$SB_Y_NOTIF"
sleep 2
capture "02_notifications"

# 03 — Search
click_at "$SB_X" "$SB_Y_SEARCH"
sleep 2
capture "03_search"

# 04 — Settings
# (Mac Catalyst NavigationSplitView doesn't reliably push from a cell tap
# into a detail view, so we showcase Settings instead of repo detail.)
click_at "$SB_X" "$SB_Y_SETTINGS"
sleep 2
capture "04_settings"

killall iTea 2>/dev/null || true

echo
echo "Done. Files:"
ls -la "$OUT"
