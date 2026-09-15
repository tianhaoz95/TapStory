# TapStory

An iPhone that behaves like a screen-free storytelling appliance for
toddlers: the screen is locked and ignores touches, and the only way to
"drive" it is by tapping an NFC tag stuck to a toy or card against the
phone. Tapping a stuffed monkey plays a story about a magic monkey; tapping
a letter card plays that letter's sound and a matching word. Parents can
record their own stories/words in-app and write them onto cheap NFC
stickers, turning literally any toy into a "magic" one.

**By default, the screen doesn't change at all, even while something is
playing.** Tapping a tag plays audio only -- the resting idle screen (a
static grey icon on black) stays exactly as it is, "as if it were not a
screen device." An optional **Screen Display** toggle in Settings turns on
showing the story page, word, or song on screen while it plays, for
whoever wants that -- but audio-only is the default and the whole point.
See **Screen Display: audio-only by default** below.

A companion **Apple Watch app** lets a parent toggle Screen Display, stop
playback, or start a saved story from their wrist -- so acting on any of
that never means picking up the phone a toddler is holding. See **Watch
companion app** below.

This repo is a working Xcode project (SwiftUI + CoreNFC), not just a
concept doc. It builds and its unit tests pass; see **Status** below for
exactly what has and hasn't been verified on real hardware.

## Screenshots

<p>
  <img src="docs/screenshots/framed/iphone-17-pro-max/idle.png" width="200" alt="Locked idle screen -- also what's on screen by default while any content is playing">
  <img src="docs/screenshots/framed/iphone-17-pro-max/story-magic-monkey.png" width="200" alt="A story playing, with Screen Display turned on">
  <img src="docs/screenshots/framed/iphone-17-pro-max/vocab-letter-m.png" width="200" alt="A vocabulary card, with Screen Display turned on">
  <img src="docs/screenshots/framed/iphone-17-pro-max/music-lullaby.png" width="200" alt="A lullaby playing, with Screen Display turned on">
</p>

These are captured automatically -- see **Screenshot automation** below --
not mocked up. **The first image is what's actually on screen by default
while any of these is playing** -- the other three show the *optional*
Screen Display mode turned on. More sizes/scenes are under
`docs/screenshots/`.

## Screen Display: audio-only by default

The single most important behavioral decision in this app: tapping a tag
plays audio, full stop. Whether anything is ever *shown* on screen is a
separate, off-by-default choice (`AppSettings.isScreenDisplayEnabled`,
toggled in Dashboard -> Settings -> Screen Display).

- **Off (default):** the idle screen (`IdleTapPromptView`) never changes,
  regardless of what's playing. A `ContentActor`'s view is still mounted
  in the hierarchy -- its `AVAudioPlayer`/`AVSpeechSynthesizer` timing and
  page-auto-advance logic run exactly as normal -- but at `opacity(0)` and
  `allowsHitTesting(false)`, so nothing is visible or tappable. Error
  states (an orphaned tag, a corrupted record) are suppressed the same
  way rather than flashing briefly, and are cleared immediately rather
  than lingering unseen (see `ChildLockedShellView.clearErrorImmediatelyIfHidden()`).
- **On:** the exact same actor views render normally -- this is the mode
  the non-idle screenshots above were captured in.

This was a deliberate correction partway through building this app: an
earlier version always showed story pages/vocab cards/song art on screen,
which was correctly flagged as working against the whole "screen-free"
premise. Keeping both modes on one code path (rather than forking audio
logic away from a separate "visual" path) means the two modes can never
drift out of sync with each other.

## Watch companion app

`TapStoryWatch` is a small Apple Watch app whose entire purpose is to let
a parent act on the phone *without touching it* -- reaching for the phone
itself would add exactly the screen time this app exists to avoid. It's
a modern single-target watchOS app (no separate WatchKit Extension
target needed), embedded into `TapStory` and built from the same
`TapStory.xcodeproj` / `project.yml`.

**What it does**, all via `WatchConnectivity` (`WCSession`) -- a local
link between paired devices over Bluetooth/local WiFi, no internet or
account involved, same as everything else in this app:

- **Toggle Screen Display** on/off remotely.
- **Stop playback** -- a "that's enough for now" button that returns the
  phone to idle.
- **See what's currently playing** -- a passive "Now Playing" readout.
- **Start a saved story/song from the wrist** -- pick anything from "My
  Tags" and play it on the phone, exactly as if its tag had been tapped,
  with no physical tag involved at all
  (`PlaybackCoordinator.remotePlay(entryID:)`).

**How the two sides stay in sync:** `Shared/WatchConnectivity/WatchMessage.swift`
defines the entire wire protocol (`WatchCommand` sent Watch -> iPhone,
`PhoneStatus` pushed iPhone -> Watch) and is compiled into *both* targets
rather than hand-copied, so they can never drift apart. `PhoneWatchConnectivityService`
(iOS, `App/TapStory/Watch/`) pushes a fresh `PhoneStatus` via
`updateApplicationContext` on every relevant `AppSettings`/`PlaybackCoordinator`/`TagLibraryStore`
change; `WatchConnectivityService` (watchOS) sends commands and applies
them to its local `status` optimistically (the toggle flips the instant
you tap it) before the phone's next real push corrects it if needed, and
falls back to queued delivery (`transferUserInfo`) if the phone isn't
immediately reachable rather than dropping the command.

**A real `xcodebuild` gotcha this surfaced:** never pass an explicit
`-sdk` (e.g. `-sdk iphonesimulator`) when building/testing the `TapStory`
scheme. Doing so forces that SDK onto the *entire* target graph,
including the embedded `TapStoryWatch` dependency -- it still compiles
(the resulting error is invisible until install), but produces an
embedded watch app built for the wrong platform, which fails at install
time with `"...does not have a WKWatchKitApp or WKApplication key..."`
or `"...UIDeviceFamily key does not specify...device family 4"` --
neither of which points at the real cause. Plain `-destination` resolves
each target to its own declared platform correctly. All commands in this
README and in `Scripts/*.sh` already avoid `-sdk` for this reason.

**Verified:** both targets build correctly for their own platform
(`xcodebuild -scheme TapStory` and `-scheme TapStoryWatch` independently,
each with the correct `SDKROOT`/`MinimumOSVersion`/`UIDeviceFamily` in
their built `Info.plist`s), the combined app+embedded-watch install and
launch correctly on a Simulator, and the Watch app's own UI renders
correctly standalone. **Not verified:** an actual paired Watch<->iPhone
message round-trip -- Simulator-to-Simulator `WCSession` pairing is a
known-unreliable substitute for real hardware (same caveat as CoreNFC),
and this repo's two iPhone/Watch Simulators were already at their
pairing limits when this was built. This needs a real Watch + iPhone
pair to fully confirm.

## Landing page & App Store pages

`docs/` is a small static site (landing page, Privacy Policy, Terms of
Use, Support/FAQ) meant to satisfy the URLs App Store Connect requires at
submission time, and to eventually be the App's marketing page. It has no
build step and no external dependencies (no CDN fonts, no analytics --
matching the app's own no-tracking stance), so it's just plain HTML/CSS
under `docs/`:

```
docs/
  index.html      # Landing page (includes the screenshot gallery)
  privacy.html    # Privacy Policy (App Store Connect requires this URL)
  terms.html      # Terms of Use / EULA
  support.html    # Support page + FAQ (App Store Connect requires this URL too)
  screenshots/    # Raw output of Scripts/capture_screenshots.sh
    framed/       # Device-framed copies (Scripts/frame_screenshots.py) -- what's actually displayed
  assets/style.css
```

`.github/workflows/deploy-pages.yml` publishes `docs/` to GitHub Pages
automatically on every push to `main` that touches `docs/`. Once GitHub
Pages is enabled for this repo (Settings -> Pages -> Source: GitHub
Actions), the site is live at
`https://tianhaoz95.github.io/TapStory/`.

**Before submitting to the App Store:** all store listing copy, keywords, review notes, and exact screenshot mappings are prepared for easy copy-pasting in [APP_STORE_METADATA.md](APP_STORE_METADATA.md). The Privacy Policy and Terms of
Use are accurate drafts (they describe this codebase's actual behavior --
no network calls, no third-party SDKs, local-only storage) but are not a
substitute for legal review. Replace the placeholder `support@tapstory.app`
contact address, and have both pages reviewed by a lawyer before treating
them as final.

## Screenshot automation

`Scripts/capture_screenshots.sh` produces every image under
`docs/screenshots/` with no manual interaction and no XCUITest gesture
scripting:

```sh
./Scripts/capture_screenshots.sh
```

It builds the app, boots one simulator per required App Store screenshot
size class (currently "iPhone 17 Pro Max" for 6.9" and "iPhone 11 Pro Max"
for 6.5" -- adjust the list at the top of the script if Apple's
requirements change), and for each of a handful of "scenes" (idle screen,
a story, a vocab card, a lullaby, the parent dashboard) launches the app
with an environment variable that a `#if DEBUG`-only hook
(`ScreenshotAutomation.swift`) reads on launch to jump straight into that
state -- reusing the same debug mechanism as `DebugSimulateTapButton`,
since CoreNFC can't be exercised in the Simulator at all. This is
dramatically more reliable than scripting actual taps, and, being
`#if DEBUG`-gated, has zero footprint in a Release build.

Since Screen Display defaults to off, a content scene also force-enables
it (only on the simulator taking the screenshot, never on a real device)
so the capture actually shows the optional visual mode instead of an
idle screen that looks identical to the "idle" scene's own screenshot.

**Device frames** (the bezel/shadow around each screenshot on the landing
page and in this README) are baked directly into a separate copy of each
image, not drawn with CSS:

```sh
python3 Scripts/frame_screenshots.py
```

Raw screenshots from `capture_screenshots.sh` are left untouched under
`docs/screenshots/<device>/` (they need to stay pixel-accurate to real
device dimensions in case they're ever reused for an actual App Store
Connect screenshot upload); framed copies go to
`docs/screenshots/framed/<device>/`. Baking the frame into the image
itself, rather than styling it with CSS like `docs/index.html` otherwise
does everywhere else, is a deliberate exception: GitHub strips
`<style>` blocks and most inline styling when rendering `README.md`, so a
CSS-only frame (fine for the landing page on its own) would just
disappear there. Re-run this after any change to
`capture_screenshots.sh`'s scenes or devices.

Run both scripts in sequence any time bundled content, a screen's layout,
or the device/scene list changes:

```sh
./Scripts/capture_screenshots.sh && python3 Scripts/frame_screenshots.py
```

## Why this shape

- **No accounts, no network, no analytics.** Everything -- bundled sample
  content, custom recordings, the parent's tag library -- lives in local
  app storage. There is nothing to leak and nothing that requires an
  internet connection to work in a car or at a grandparent's house.
- **The screen lock is app-level, not OS-level.** TapStory cannot turn on
  Guided Access itself (no app can -- see below); it locks itself by
  simply not putting anything tappable in front of the child except an
  invisible parent-gate hotspot. Guided Access is what removes the Home
  gesture / App Switcher / other apps on top of that.
- **The schema is deliberately open**, not hardcoded to "story" and
  "vocab card": every piece of content is `{ "type": "...", "payload":
  {...} }`, and an `ActorRegistry` dispatches `type` to whichever
  `ContentActor` claims it. Adding a brand-new kind of activity later is a
  new actor conformance, not a rewrite. See **Schema & extensibility**.
- **A physical tag stores only a small id, never the content.** The
  content itself (a story's pages, a vocab word's audio, all of it) lives
  in the phone's local library, addressed by that id. This means tag
  capacity is a complete non-issue -- even the cheapest NFC sticker fits a
  UUID -- at the deliberate cost of a tag only meaning something on the
  phone that wrote it. See **Design tradeoff: tags point at your phone's
  library**.

## Status (what's real vs. what needs a physical device)

| Area | Status |
|---|---|
| Project builds (`xcodebuild ... build`) | ✅ Verified, iOS Simulator SDK |
| Unit tests (`xcodebuild ... test`) | ✅ 38/38 passing |
| Idle/locked shell renders correctly | ✅ Verified via Simulator screenshot |
| Screen Display off (default) truly shows no visual change while content plays | ✅ Verified via Simulator screenshot -- see **Screen Display: audio-only by default** |
| On-device speech synthesis (`AVSpeechSynthesizer`) | ✅ Works in Simulator too (unlike CoreNFC) -- this is the default authoring path |
| NFC read/write | ⚠️ **Cannot be exercised on the Simulator** -- CoreNFC requires a physical iPhone 7 or later. Code compiles against the real API; behavior needs to be verified on-device. |
| Guided Access flow | ⚠️ Requires a physical device (Guided Access isn't meaningful in Simulator) |
| Parent-gate long-press, full create-tag flow, audio recording | ⚠️ Built and code-reviewed, but not exercised end-to-end by an automated UI test (long-press + multi-step flows are impractical to script against the Simulator without XCUITest, which wasn't set up in this pass) |
| Bundled lullaby audio | ⚠️ Placeholder text-to-speech (macOS `say`), not real music -- see **Bundled sample content** |
| Watch app builds, embeds, installs, and launches | ✅ Verified via Simulator (both platforms independently, and the combined app+embed) -- see **Watch companion app** |
| Watch<->iPhone `WatchConnectivity` message round-trip | ⚠️ **Not verified end-to-end** -- Simulator-to-Simulator `WCSession` pairing is unreliable (same caveat as CoreNFC); needs a real Watch + iPhone pair |

**Bottom line:** the architecture, schema, NFC read/write code, and every
screen are implemented and compiling/passing tests, but this has not yet
been run on a real iPhone with real tags. That's the next step before
handing this to an actual toddler.

## Project layout

```
project.yml                     # xcodegen spec -- TapStory.xcodeproj is generated, not committed
App/TapStory/
  TapStoryApp.swift              # @main entry point
  Core/                          # Schema, actor registry, NFC-agnostic business logic
    JSONValue.swift               # Open JSON payload type
    ContentRecord.swift            # { schemaVersion, type, payload } -- the real content
    TagReference.swift             # { schemaVersion, id } -- the tiny id actually written to a tag
    ContentActor.swift             # Protocol every activity type conforms to
    ActorRegistry.swift            # type string -> ContentActor dispatch table
    MediaRef.swift / MediaResolver.swift   # bundled/recording/on-device-speech indirection
    RecordingStore.swift           # On-device storage for parent voice recordings
    TagLibraryStore.swift          # Parent's "My Tags" library -- what every tag id resolves against
    BundledLibrary.swift           # Loads the sample stories/cards/song for the picker UI
    AudioPlaybackController.swift  # Plays a MediaRef via AVAudioPlayer or AVSpeechSynthesizer
    PlaybackCoordinator.swift      # Resolves NFC tag ids -> content -> whatever the shell shows
    AppSettings.swift              # Screen Display toggle (off by default), UserDefaults-backed
  Actors/Story, Actors/Vocab, Actors/Music/   # The three built-in ContentActor conformances
  NFC/                            # CoreNFC-specific code (kept isolated from Core)
    NFCReaderService.swift          # Continuous NDEF read session for the child shell
    NFCWriterService.swift          # Writes a TagReference (just an id) to a blank/reusable tag
    TagReference+NDEF.swift         # TagReference <-> NFCNDEFPayload bridging
  Watch/
    PhoneWatchConnectivityService.swift  # iOS side of the Watch remote control (WCSession)
  UI/
    Child/            # What the toddler sees: idle prompt, locked shell, error state,
                       # ScreenshotAutomation.swift (#if DEBUG launch-argument scene driver)
    ParentGate/        # Invisible long-press hotspot + math-question challenge
    Dashboard/          # Parent's home screen: tag library, settings, Guided Access help
    CreateTag/          # Multi-step "make a new magic tag" flow (bundled or record-your-own)
    Root/               # App-wide chrome (tint, forced light appearance)
  Resources/BundledContent/   # Sample stories/vocab/music (JSON + generated placeholder audio)
App/TapStoryWatch/               # Watch companion app (embedded into TapStory, see project.yml)
  TapStoryWatchApp.swift          # @main entry point
  ContentView.swift               # The entire Watch UI: now playing, Screen Display toggle, saved tags
  WatchConnectivityService.swift  # Watch side of the remote control (WCSession)
Shared/WatchConnectivity/
  WatchMessage.swift               # WatchCommand / PhoneStatus -- compiled into BOTH app targets
TapStoryTests/            # Unit tests for the schema, NDEF bridging, and actor dispatch
Scripts/generate_sample_audio.sh   # Regenerates the placeholder narration via macOS `say`
```

## Building and running

Requires Xcode (tested with Xcode 26.6) and [xcodegen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). The `.xcodeproj` is generated, not committed --
regenerate it any time the project structure or `project.yml` changes:

```sh
xcodegen generate
open TapStory.xcodeproj
```

Or from the command line:

```sh
xcodegen generate
xcodebuild -project TapStory.xcodeproj -scheme TapStory \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build

xcodebuild -project TapStory.xcodeproj -scheme TapStory \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO test
```

**Never add an explicit `-sdk` to these** -- see **Watch companion app**
for why that silently breaks the embedded watch target.

To build/run the Watch app on its own (e.g. to iterate on its UI without
reinstalling the iPhone app), use the `TapStoryWatch` scheme against a
watchOS Simulator destination instead:

```sh
xcodebuild -project TapStory.xcodeproj -scheme TapStoryWatch \
  -destination 'generic/platform=watchOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

**To actually test NFC, Guided Access, and Watch<->iPhone communication**,
build to a physical iPhone 7 or later paired with a real Apple Watch:
open the project in Xcode, pick your phone as the run destination, set
your own Team under Signing & Capabilities **for both the `TapStory` and
`TapStoryWatch` targets** (bundle ids are currently the placeholders
`com.tapstory.TapStory` / `com.tapstory.TapStory.watchkitapp` -- change
them to something under your own Apple ID/team, keeping the `.watchkitapp`
suffix relationship intact), and run.

## Schema & extensibility

The actual content behind a tag is one JSON envelope, kept in the phone's
local library (`TagLibraryStore`) -- never on the physical tag itself
(see **Design tradeoff** below for why):

```json
{
  "schemaVersion": 1,
  "type": "story",
  "payload": { "...": "actor-specific shape" }
}
```

`type` is looked up in `ActorRegistry`, which hands the matching
`ContentActor` the whole record. The actor decodes `payload` into its own
strongly-typed struct and produces the full-screen SwiftUI view. Nothing
else in the app -- not the NFC read path, not the tag-writing flow, not the
"choose a type" authoring screen -- has a hardcoded list of types; they all
read from `ActorRegistry.shared.allActorTypes`.

**To add a new activity type** (a counting game, a "leave a voice memo for
grandma" button, anything): create a `FooPayload: Codable` struct, a
`FooActor: ContentActor` with a `typeIdentifier`/`displayName`/
`iconSystemName` and a `makeChildView`, and register it in
`ActorRegistry.registerBuiltInActors()`. It will automatically show up in
the "create a new tag" type picker and in the NFC read dispatch.

### Built-in types

| `type` | Payload shape | Behavior |
|---|---|---|
| `story` | `{ title, pages: [{ caption, symbol, audio }] }` | Auto-advances page by page as each clip finishes; no taps needed |
| `vocab_card` | `{ title, word, letter?, symbol, audio }` | Plays the word's audio twice, then returns to idle |
| `music` | `{ title, symbol, audio, loop }` | Plays once or loops until a new tag is tapped |

`audio` everywhere is a `MediaRef`: `{ "source": "bundled"|"recording"|"speech", "ref": "..." }`.
- `bundled` resolves to a file shipped in the app.
- `recording` resolves to a parent's on-device voice recording, addressed by UUID.
- `speech` holds literal text, spoken live via on-device `AVSpeechSynthesizer`
  at playback time -- nothing is pre-rendered or stored as a file. This is
  the default, easiest authoring path: type a sentence instead of
  recording audio. A **blank** `speech` ref means "speak this item's own
  caption/word/title instead" (`AudioPlaybackController.resolvingBlankSpeechRef`)
  so a story page's narration doesn't have to be typed twice when it
  matches the on-screen text -- see the bundled sample stories for this
  pattern in practice.

Recording your own voice remains fully available (`AudioSourceInput` in
the authoring UI offers both as a segmented choice) for anyone who wants a
story told in a real voice, or for singing/humming, which `speech` can't do.

## Turning a toy into a magic toy (the parent flow)

1. Long-press the invisible hotspot in the bottom-right corner of the
   locked screen for 3 seconds (see **Parental gate** below).
2. Solve the simple math question to open the parent dashboard.
3. **Create a New Magic Tag** -> pick a type (Story / Vocab Card / Music)
   -> either pick something from the bundled library, or **Record Your
   Own** (type the word/title, pick an SF Symbol illustration, then either
   type what should be said -- spoken on-device, no recording needed -- or
   record your own voice).
4. This saves the content to **My Tags** under a fresh id, then **Write
   Tag**: hold a blank or reusable NFC sticker to the top of the phone.
   Only that small id gets written -- see **Design tradeoff** below --
   so any cheap sticker works regardless of how long the story is.
5. Stick the tag to the toy or card. Done -- since the content lives in
   the library rather than on the tag, a lost or destroyed sticker is
   never a real loss: just write the same entry's id to a new one from
   "My Tags."

## Design tradeoff: tags point at your phone's library

A physical tag stores only a `TagReference`: `{ "schemaVersion": 1, "id":
"<uuid>" }`. Tapping it reads that id, and `PlaybackCoordinator` looks it
up in this phone's `TagLibraryStore` to get the actual content. This was a
deliberate redesign (an earlier version of this app wrote the full
content to the tag) because it makes physical tag capacity a complete
non-issue -- even the cheapest NTAG213 sticker fits a UUID string
comfortably, no matter how many pages a story has.

The cost: **a tag only means something on the phone whose library still
has that id.** Concretely:
- Deleting a "My Tags" entry, or using "Erase All My Tags & Recordings" in
  Settings, orphans every physical tag that pointed at it -- both places
  warn about this now, but there's no undo.
- A tag written on one phone/install won't resolve on another, since
  there's no accounts or sync (by design -- see **Why this shape**).
  Restoring the same phone from an iCloud/iTunes backup should carry the
  local library over with it, but a fresh reinstall or a different phone
  will not.
- **Test / Inspect a Tag** in the dashboard (`NFCTagInspectorView`) shows
  exactly this: scanning an orphaned tag reports "not in this phone's `My
  Tags` library" rather than silently doing nothing.

Buy **NTAG21x** stickers (widely sold for exactly this kind of DIY-tag
project) -- any capacity, NTAG213 included, is more than enough now.

## Guided Access (why it's manual, and how to set it up)

Apple does not provide any API for an app to turn on Guided Access itself
-- it's deliberately kept under the parent's direct, physical control (a
triple-click of the side button, and a separate Guided Access passcode).
TapStory can't automate this, and the in-app **Guided Access Setup**
screen (Dashboard -> Guided Access Setup) walks through the one-time setup
and the per-session ritual instead. This is a real, permanent constraint
of the platform, not a v1 gap -- see the `GuidedAccessHelpView` for the
exact steps to hand to a parent.

The one thing CoreNFC does *not* let an app suppress is its own small
system sheet ("Ready to Scan") that appears while a scan session is
active. TapStory treats this as an accepted, unavoidable part of the
experience rather than something to fight -- see `NFCReaderService.swift`
for the reasoning and how the continuous-listening session auto-restarts,
including if a toddler taps the sheet's own Cancel/Done button.

That sheet is modal and blocks touches to everything underneath it,
**including the parental gate hotspot below**. Restarting it too quickly
after a cancel would leave no way in at all -- if you ever see the "Ready
to Scan" sheet reappearing before you can reach the hotspot, tap
**Cancel** on the sheet once and you'll have about 8 seconds before it
comes back (`parentGateRestartDelay` in `NFCReaderService.swift`) --
plenty of time for the 3-second hold below. A quicker read/timeout
restarts almost immediately instead, so the "just tap it" experience for
the toddler isn't affected.

## Parental gate

A 3-second long-press on an invisible corner hotspot opens a simple
addition question (`ParentGateChallengeView`) before the dashboard is
reachable. This isn't meant to stop a determined adult -- it exists so a
toddler can't stumble into settings, tag creation, or NFC writing, which
is the standard pattern in kids' apps.

## TestFlight release automation

`.github/workflows/testflight.yml` builds, signs, and uploads a TestFlight
build on demand -- trigger it from the Actions tab ("Release to
TestFlight" -> Run workflow) or `gh workflow run testflight.yml`. It's
`workflow_dispatch`-only (no automatic trigger on push) so a release is
always a deliberate action.

**What it does:** installs a signing certificate into a throwaway
keychain scoped to that one job run, `xcodegen generate`s the project,
archives `TapStory` in Release configuration (embedding `TapStoryWatch`
automatically, same as a local archive would), then exports *and
uploads* it in one step via `xcodebuild -exportArchive` with
`destination: upload` in its `exportOptionsPlist`. (An earlier version of
this workflow used the classic `method: app-store` + separate `xcrun
altool --upload-app` recipe from countless CI tutorials -- this Xcode
version rejects `app-store` outright in favor of `app-store-connect`,
and added `destination: upload` to fold the upload into the export step,
so there's no separate altool call at all anymore.) Build number is
`$GITHUB_RUN_NUMBER` (always unique, auto-incrementing); bump
`MARKETING_VERSION` in `project.yml` by hand when you want a new version
string. Signing resolution uses an App Store Connect API key with
`-allowProvisioningUpdates`, so a runner with no cached profiles fetches
the two named App Store profiles on the fly (verified by clearing both of
Xcode's profile caches locally and re-archiving from scratch).

### Four things that will silently break this

Each of these produced an error message pointing somewhere else entirely,
so they're worth knowing before touching the release path:

**The watch target must keep `SKIP_INSTALL: YES`.** `TapStoryWatch` ships
*inside* `TapStory.app/Watch/`. If it's also installed standalone, the
archive's `Products/Applications/` ends up with two `.app` bundles, Xcode
can no longer tell which is the primary application, and it quietly omits
the `ApplicationProperties` dictionary from the archive's `Info.plist`.
Nothing complains at archive time. At export time every distribution
method rejects the archive (it has no detectable platform) and you get:

```
error: exportArchive exportOptionsPlist error for key "method" expected one {} but found app-store-connect
```

That `{}` is the *empty set of valid methods* — the message is about
there being no usable method at all, not about the string being wrong.
Chasing the `method` value is a dead end. The workflow now asserts
`ApplicationProperties` exists immediately after archiving, so this fails
loudly and points at the real cause.

**Release signs manually, not automatically.** Automatic signing's
development-vs-distribution purpose resolution is unreliable through
`xcodebuild` on the CLI — it kept resolving to *development* even with a
Distribution identity present and `DEVELOPMENT_TEAM` passed explicitly,
and then hard-conflicts if you also specify a Distribution identity
("automatically signed for development, but a conflicting code signing
identity Apple Distribution has been manually specified"). So `project.yml`
pins `CODE_SIGN_IDENTITY: "Apple Distribution"` and a
`PROVISIONING_PROFILE_SPECIFIER` per target for Release, and the export
options repeat the same mapping under `provisioningProfiles` with
`signingStyle: manual`. Don't add `CODE_SIGN_STYLE=Automatic` back to the
archive command — it undoes all of it. (Debug still signs automatically,
so day-to-day device builds are unaffected.)

**Version keys must reference the build settings.** The `info:` blocks in
`project.yml` set `CFBundleShortVersionString: "$(MARKETING_VERSION)"` and
`CFBundleVersion: "$(CURRENT_PROJECT_VERSION)"`. Without that, xcodegen
writes literal `1.0` and `1` into the generated `Info.plist`, which
silently overrides the build number CI passes as `CURRENT_PROJECT_VERSION`
— every upload would arrive as build "1" and be rejected as a duplicate.

**The NFC entitlement value must be `TAG`, not `NDEF`.** `NDEF` is a
long-deprecated value for `com.apple.developer.nfc.readersession.formats`
that current App Store Connect validation rejects outright:

```
Invalid entitlement for core nfc framework. The sdk version '26.5' and
min OS version '16.0' are not compatible for the entitlement
'com.apple.developer.nfc.readersession.formats' because 'NDEF is disallowed'.
```

(ITMS-90778, a known issue documented across Apple Developer Forum
threads going back years -- confirmed this is unrelated to deployment
target by testing both 16.0 and 17.0 against Apple's live validation
servers, same error either time.) `TAG` is the modern replacement and
fully covers `NFCNDEFReaderSession` scanning/writing -- this app never
uses `NFCTagReaderSession` directly, so it's purely an entitlement fix, no
Swift code changes. This one only surfaces during the App Store Connect
upload/validation step itself; a plain local `-exportArchive` with
`destination: export` succeeds regardless, since it never talks to
Apple's servers -- which is why it wasn't caught by local export testing
alone and needed `xcrun altool --validate-app` to reproduce outside CI.

**All 7 required secrets are configured:**

| Secret | Source |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Base64 of a `.p12` export of this machine's "Apple Distribution" signing identity (uploaded from Keychain -- required for TestFlight/App Store signing, as opposed to an "Apple Development" identity which only works for local device installs). All identities in the keychain export together as one bundle -- a `security export` limitation, not a deliberate choice; the workflow only ever uses the one Distribution identity. |
| `P12_PASSWORD` | Password protecting that `.p12` (randomly generated, never used interactively) |
| `KEYCHAIN_PASSWORD` | Password for the throwaway per-run CI keychain (randomly generated) |
| `DEVELOPMENT_TEAM` | The Apple Developer Team ID the certificate belongs to |
| `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64` | An existing App Store Connect API key, recovered from this machine's `FA_ASC_KEY_ID`/`FA_ASC_ISSUER_ID`/`FA_KEY_LOCATION` environment variables (left behind by an earlier fastlane setup) rather than freshly created |

If these ever need to be rotated (e.g. the certificate expires, or a new
machine needs to set this up from scratch), creating a fresh App Store
Connect API key requires Account Holder/Admin access to the Apple
Developer team via the App Store Connect web UI (Users and Access ->
Integrations -> App Store Connect API -> Generate API Key, **App
Manager** role or higher) -- there's no way to script that part. Apple
only lets you download the resulting `.p8` once, so run these commands
yourself right after, so the raw private key only ever touches your own
terminal:

```sh
gh secret set APP_STORE_CONNECT_API_KEY_ID --repo tianhaoz95/TapStory --body "<the Key ID shown next to your new key>"
gh secret set APP_STORE_CONNECT_API_ISSUER_ID --repo tianhaoz95/TapStory --body "<the Issuer ID shown at the top of the Keys page>"
base64 -i AuthKey_XXXXXXXXXX.p8 | gh secret set APP_STORE_CONNECT_API_KEY_BASE64 --repo tianhaoz95/TapStory
```

## App icon

Both `TapStory` and `TapStoryWatch` share one generated 1024x1024 source
image (`Scripts/generate_app_icon.py`, Pillow-based): a black background
matching `IdleTapPromptView` exactly, with a gift box in the app's own
accent orange -- literally "wrap a toy up as a magic one," the core
product idea, rather than an unrelated logo. Uses the modern single-size
`AppIcon.appiconset` format (one `universal` image per platform; Xcode
generates every smaller size and applies corner/circle masking itself --
the source image must stay a plain opaque square, never pre-rounded).
Regenerate with:

```sh
python3 Scripts/generate_app_icon.py
```

## Bundled sample content

Ships with 5 stories and 10 alphabet vocab cards so the app isn't silent
on first run (`App/TapStory/Resources/BundledContent`). Their narration
uses `MediaRef(source: .speech, ...)` -- spoken live, on-device, from the
text in their JSON -- the same mechanism a parent's own typed content
uses, so these double as a working demo of that path.

The one exception is the lullaby placeholder, which is a real (if
synthetic) `.m4a` file: `AVSpeechSynthesizer` can speak words but can't
sing or hum, so music content still needs an actual audio file. That one
file is macOS `say` text-to-speech, not real music -- regenerate it with:

```sh
./Scripts/generate_sample_audio.sh
```

Before this goes anywhere near an actual toddler, replace the lullaby with
real recorded/composed music, and consider real illustrations in place of
SF Symbols. Illustrations currently use SF Symbols rather than
artwork/photos specifically to avoid needing camera or photo-library
permissions in a kids' app -- see **Ideas for follow-up work**.

The letter-A card's icon uses the system Apple logo glyph as a stand-in
for "apple the fruit" (SF Symbols has no dedicated fruit icon) -- worth
swapping for real artwork before shipping.

## Known limitations / product risks to keep in mind

- **Guided Access requires the parent to physically start it every
  session** (triple-click + tap Start). There's no way around this on
  iOS; the app can only make the instructions as clear as possible.
- **The system NFC sheet is unhideable.** A curious toddler could tap its
  Cancel/Done button; the reader service is written to always silently
  restart listening when that happens, but it's worth watching for in
  real use.
- **NFC hardware requires iPhone 7 or later.** `NFCAvailability.isSupported`
  surfaces a friendly message if run on an unsupported device, but there's
  no fallback interaction model.
- **Deleting library content orphans physical tags.** Since tags store
  only a reference id (see **Design tradeoff**), there is no way to
  recover a tag's content after its library entry is deleted -- both
  delete confirmations warn about this, but it's a real, permanent loss
  with no undo, unlike traditional "delete" actions that only remove a
  convenience view onto data stored elsewhere.
- **On-device speech quality varies by device/OS voice.** `.speech`
  content uses whatever system voice is installed (`AVSpeechSynthesisVoice(language: "en-US")`);
  a parent can get noticeably better results by downloading an
  Enhanced/Premium voice under Settings > Accessibility > Spoken Content.
- **App Store submission** (since "eventually" was the stated goal): kids
  category apps get extra review scrutiny, particularly around anything
  that resembles restricting normal iOS navigation (TapStory doesn't
  actually do this -- it just declines to put anything else on screen --
  but be ready to explain that clearly in review notes), microphone usage
  (already justified via `NSMicrophoneUsageDescription`), and the general
  kids-category privacy requirements (no ads, no third-party analytics,
  no data collection -- this app already has none of that, which should
  make review comparatively easy).
- **Watch<->iPhone communication is unverified on real hardware.** Every
  build/install-level check has passed on Simulator, but an actual
  message round-trip needs a real paired Watch + iPhone -- see **Watch
  companion app** and the Status table.
- **The Watch app requires a companion iPhone.** `WKRunsIndependentlyOfCompanionApp`
  is `false`, matching what it actually does (it's a remote for the
  phone, not a standalone experience) -- it won't do anything useful if
  the iPhone app has never been run at least once to establish pairing.

## Ideas for follow-up work

- Sync `TagLibraryStore` via iCloud (still no third-party accounts/servers)
  so a tag survives a reinstall or works from a second family phone --
  the real fix for the **Design tradeoff** section's biggest downside.
- Real recorded/composed music to replace the lullaby TTS placeholder.
- Optional camera-captured photo illustrations (would need
  `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` and extra
  privacy review consideration -- deliberately deferred).
- A "counting game" or "shape matching" actor to prove out the schema's
  extensibility with something genuinely interactive rather than
  linear-playback.
- XCUITest coverage of the parent-gate long-press and create-tag flow,
  which today are verified by build + manual reasoning but not automated
  end-to-end.
- On-device (physical iPhone) verification pass for NFC read/write and
  Guided Access, since none of that is exercisable in the Simulator.
- On-device (real Watch + iPhone pair) verification of the Watch app's
  `WatchConnectivity` round-trip, for the same reason.
- A Watch complication or Smart Stack widget for one-glance "Now Playing" /
  Screen Display status without even opening the Watch app.
