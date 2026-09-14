#!/bin/bash
# Captures App Store / landing-page screenshots without any UI automation:
# each "scene" is driven entirely by an environment variable the DEBUG
# build reads on launch (see ScreenshotAutomation.swift) via simctl's
# SIMCTL_CHILD_ prefix, so there's no fragile tap/gesture scripting and
# no dependency on CoreNFC (which doesn't work in the Simulator at all).
#
# Usage: ./Scripts/capture_screenshots.sh [output-dir]
#   Defaults to docs/screenshots relative to the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID="com.tapstory.TapStory"
OUT_ROOT="${1:-docs/screenshots}"

# One device per required App Store screenshot size class. Apple's exact
# required sizes change over time -- double-check current requirements in
# App Store Connect before a real submission; these two cover the two
# most commonly required classes as of this writing (6.9" and 6.5").
DEVICE_TYPES=(
  "iPhone 17 Pro Max"
  "iPhone 11 Pro Max"
)

# "<content-type>:<bundled-file-stem>" scenes reuse the app's own bundled
# sample content (see App/TapStory/Resources/BundledContent) so this script
# has no content of its own to keep in sync. "idle" and "dashboard" are
# special-cased in ScreenshotAutomation.swift.
declare -a SCENES=(
  "idle:idle"
  "story:magic_monkey:story-magic-monkey"
  "vocab_card:letter_m:vocab-letter-m"
  "music:lullaby_01:music-lullaby"
  "dashboard:dashboard"
)

echo "== Building TapStory (Debug, Simulator) =="
xcodegen generate >/dev/null
# No explicit -sdk flag: since TapStory embeds the TapStoryWatch
# companion target, `-sdk iphonesimulator` would force that platform onto
# the entire target graph (including the watch target), silently
# producing an invalid embedded watch app that fails to install. Plain
# `-destination` resolves each target to its own declared platform.
xcodebuild -project TapStory.xcodeproj -scheme TapStory \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build \
  | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" || true

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/TapStory-*/Build/Products/Debug-iphonesimulator -maxdepth 1 -name "TapStory.app" | head -1)
if [ -z "$APP_PATH" ]; then
  echo "Could not find built TapStory.app -- build failed?" >&2
  exit 1
fi
echo "App: $APP_PATH"

slugify() {
  echo "$1" | tr '[:upper:] ' '[:lower:]-'
}

for DEVICE_TYPE in "${DEVICE_TYPES[@]}"; do
  DEVICE_SLUG=$(slugify "$DEVICE_TYPE")
  SIM_NAME="TapStory-Screenshots-$DEVICE_SLUG"
  OUT_DIR="$OUT_ROOT/$DEVICE_SLUG"
  mkdir -p "$OUT_DIR"

  echo ""
  echo "== $DEVICE_TYPE -> $OUT_DIR =="

  DEVICE_ID=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for devices in data['devices'].values():
    for d in devices:
        if d['name'] == '$SIM_NAME':
            print(d['udid']); sys.exit()
")

  if [ -z "$DEVICE_ID" ]; then
    RUNTIME=$(xcrun simctl list runtimes -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
runtimes = [r for r in data['runtimes'] if r['name'].startswith('iOS') and r['isAvailable']]
print(runtimes[-1]['identifier'])
")
    echo "Creating simulator '$SIM_NAME'..."
    DEVICE_ID=$(xcrun simctl create "$SIM_NAME" "com.apple.CoreSimulator.SimDeviceType.$(echo "$DEVICE_TYPE" | sed 's/ /-/g')" "$RUNTIME")
  fi

  # `simctl bootstatus -b` was observed hanging indefinitely even after
  # the device was already fully "Booted" per `simctl list` -- polling
  # state directly is slower to write but doesn't have that failure mode.
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
  for _ in $(seq 1 30); do
    STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for devices in data['devices'].values():
    for d in devices:
        if d['udid'] == '$DEVICE_ID':
            print(d['state']); sys.exit()
")
    [ "$STATE" = "Booted" ] && break
    sleep 1
  done
  sleep 3
  xcrun simctl install "$DEVICE_ID" "$APP_PATH"

  for SCENE_SPEC in "${SCENES[@]}"; do
    # Everything before the last ':' is the scene value the app reads;
    # everything after is this script's own output filename.
    SCENE_VALUE="${SCENE_SPEC%:*}"
    SCENE_SLUG="${SCENE_SPEC##*:}"
    OUT_FILE="$OUT_DIR/$SCENE_SLUG.png"

    # --terminate-running-process makes simctl kill any already-running
    # instance and launch fresh in one atomic call. Without it, a plain
    # `terminate` followed by a separate `launch` races: if the old
    # process hasn't fully died yet, `launch` just re-foregrounds it
    # instead of starting a new process, silently dropping the new
    # environment variable (and the scene along with it).
    # Always set the env var, even for "idle" (a recognized no-op scene) --
    # its mere presence also tells the app screenshot mode is active, so
    # debug-only chrome (the ladybug button) hides itself. See
    # ScreenshotAutomation.swift.
    env "SIMCTL_CHILD_TAPSTORY_SCREENSHOT_SCENE=$SCENE_VALUE" \
      xcrun simctl launch --terminate-running-process "$DEVICE_ID" "$BUNDLE_ID" >/dev/null

    sleep 3
    xcrun simctl io "$DEVICE_ID" screenshot "$OUT_FILE" >/dev/null
    echo "  - $SCENE_SLUG -> $OUT_FILE"
  done

  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl shutdown "$DEVICE_ID" >/dev/null 2>&1 || true
done

echo ""
echo "Done. Screenshots are in $OUT_ROOT/"
