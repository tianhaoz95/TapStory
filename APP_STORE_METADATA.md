# App Store Connect Listing & Metadata: TapStory

This document contains all metadata, store copy, questionnaire responses, review notes, and screenshot specifications required to submit **TapStory** to App Store Connect. Every text field is pre-calculated to fit Apple's character limits so you can copy and paste directly into each form field.

---

## 1. App Information (General)

| App Store Connect Field | Value / Content | Notes / Limits |
|---|---|---|
| **App Name** | `TapStory: Screen-Free Audio` | 27 / 30 chars (Alternative: `TapStory`) |
| **Subtitle** | `Audio Stories for Toddlers` | 26 / 30 chars (Alternative: `Screen-Free Stories for Kids`) |
| **Primary Language** | `English (U.S.)` | |
| **Bundle ID** | `com.tapstory.TapStory` | Configured in `project.yml` |
| **Apple Watch Bundle ID** | `com.tapstory.TapStory.watchkitapp` | Companion app embedded |
| **SKU** | `TAPSTORY-IOS-01` | Unique internal identifier (or your custom SKU) |
| **Primary Category** | `Education` | |
| **Secondary Category** | `Entertainment` (or `Lifestyle`) | |
| **Content Rights** | `Does not contain, show, or access third-party content` | |
| **Age Rating** | `4+` | All questionnaire categories set to "None" |
| **Made for Kids** | `Yes` (Ages 5 and under) | |
| **License Agreement (EULA)** | Standard Apple EULA *(or custom link: `https://tianhaoz95.github.io/TapStory/terms.html`)* | |
| **Privacy Policy URL** | `https://tianhaoz95.github.io/TapStory/privacy.html` | Deployed via GitHub Pages |
| **User Privacy Choices URL** | *(Leave blank or same as Privacy Policy)* | |

---

## 2. Version Information (iOS & watchOS)

### Version & Build
- **Version Number**: `0.1.1` *(or `1.0.0` when releasing v1; check `MARKETING_VERSION` in `project.yml`)*
- **Copyright**: `2026 HEJI TECHNOLOGY LLC` *(from Apple Distribution signing identity)*

### URLs
- **Support URL**: `https://tianhaoz95.github.io/TapStory/support.html`
- **Marketing URL**: `https://tianhaoz95.github.io/TapStory/`

### Promotional Text *(Max 170 characters — can be updated without a new app binary)*
```text
Turn any toy into a screen-free storytelling magic box. Tap a toy or card to hear stories, songs, and words. No accounts, no ads, and 100% offline.
```
*(Character count: 147 / 170)*

---

### Description *(Max 4,000 characters)*

```text
TapStory turns your iPhone into a screen-free storytelling box for toddlers. Stick an inexpensive NFC tag onto any toy, plushie, or flashcard, and tapping it against your phone instantly plays a story, vocabulary card, or song.

AUDIO-ONLY BY DEFAULT
Most toddlers don't need another glowing screen. By default, TapStory plays audio only: the screen stays completely still while the story plays, feeling more like a tactile music box or appliance than a phone. An optional "Screen Display" toggle is available if you prefer showing illustrations and captions.

HOW IT WORKS
1. Stick a standard NFC sticker (e.g., NTAG213/215) on the bottom of any toy, book, or flashcard.
2. Open the Parent Dashboard and assign content: choose from bundled stories or create your own.
3. Type the words for instant on-device narration, or record your own voice.
4. Turn on iOS Guided Access to lock the screen.
5. Hand it to your toddler: tapping the toy starts the story!

KEY FEATURES

• Screen-Free & Touch-Locked: The playback screen ignores taps and gestures so curious hands can't accidentally exit or switch apps.
• Works with Any Toy: Turn beloved stuffed animals, wooden blocks, and flashcards into interactive learning tools.
• Type or Record: Type any sentence and TapStory speaks it aloud using on-device synthesis, or record your own voice for bedtime stories.
• Apple Watch Remote: Control playback, stop stories, or toggle Screen Display directly from your wrist without touching the phone your child is holding.
• Bundled Starter Content: Comes preloaded with 5 complete stories, 10 alphabet vocabulary flashcards, and lullaby music.
• Built-In Parent Gate: A hidden long-press hotspot and math challenge keep settings and tag-writing safely out of reach of little hands.
• 100% Private & Offline: No accounts, no sign-up, no ads, and no tracking. TapStory works completely offline without Wi-Fi or cellular data. All recordings and custom tags stay private on your device.

HARDWARE REQUIREMENTS
• Compatible with iPhone 7 and later running iOS 16.0 or newer.
• Standard NTAG213, NTAG215, or NTAG216 adhesive stickers (widely available for DIY crafts).
• Optional: Apple Watch running watchOS 10.0 or newer for remote parental controls.
```
*(Character count: 2,237 / 4,000)*

---

### Keywords *(Max 100 characters, comma-separated, no spaces after commas to save room)*

```text
screen free,toddler,audio,story,nfc,montessori,audiobook,flashcards,kids books,read aloud
```
*(Character count: 89 / 100)*

---

### What's New in This Version *(Release notes for v0.1.1 / initial release)*

```text
Welcome to TapStory! Turn your iPhone into a screen-free audio storytelling box for toddlers using NFC tags on toys and cards. Includes built-in sample stories, vocabulary flashcards, lullabies, voice recording, and Apple Watch remote controls.
```

---

## 3. App Review Information

Apple App Store Reviewers often test on simulators or devices without physical NFC tags, and heavily scrutinize apps in the Kids category. Providing clear notes ensures smooth approval on the first pass.

### Sign-In Required
- **Checkbox**: `Unchecked (No sign-in required)`

### Contact Information
- **First Name**: `Tianhao`
- **Last Name**: `Zhou`
- **Email**: `support@tapstory.app` *(or your primary developer email)*
- **Phone Number**: *(Your phone number including country code, e.g., +1...)*

### Notes for Reviewer
```text
Dear App Review Team,

TapStory is an audio-first educational app designed for toddlers and their parents. It turns an iPhone into a screen-free storytelling appliance where tapping physical NFC tags (stuck to toys or cards) plays stories, vocabulary words, and music.

IMPORTANT TESTING INFORMATION:

1. HOW TO ACCESS PARENT DASHBOARD / SETTINGS:
To protect toddlers from reaching settings or tag-writing tools, the app has a hidden parental gate:
- On the resting screen ("Tap a toy or card to begin"), long-press the BOTTOM-RIGHT corner of the screen for 3 seconds.
- A math question challenge will appear. Enter the correct answer to open the Parent Dashboard.

2. TESTING WITHOUT PHYSICAL NFC TAGS:
If testing on hardware or in an environment without physical NFC tags:
- From the resting screen, a debug ladybug button is available in test builds to simulate tag taps.
- In the Parent Dashboard, tap "My Tags" -> select any story or card -> tap "Play" to test audio playback immediately.
- If testing with a paired Apple Watch, open TapStory on the Apple Watch and select any story under "My Tags" to start remote playback.

3. "AUDIO-ONLY BY DEFAULT" DESIGN EXPLANATION:
By default, tapping a tag plays audio while the screen stays resting and dark. This is the deliberate product design: preventing screen addiction by keeping the device behaving like a screen-free audio player.
To test on-screen visual presentation (illustrations & text):
- Open Parent Dashboard (via the 3-second long press on bottom right).
- Go to Settings -> toggle "Screen Display" ON.
- Playing any story will now display full-screen page artwork and text.

4. PERMISSIONS EXPLANATION:
- NFC: Required to read the tag reference ID on toys and write IDs to blank NFC stickers.
- Microphone: Used exclusively for parents to record their own voice narration for custom stories/words. All audio recordings are stored strictly in local app storage and are never transmitted anywhere.

5. PRIVACY & COPPA COMPLIANCE:
The app collects NO personal data, contains no analytics SDKs, serves no ads, and operates 100% offline without any third-party network connections.

Thank you for your review!
```

---

## 4. App Privacy Questionnaire (Nutrition Labels)

When completing the **App Privacy** section in App Store Connect:

1. **Data Collection Question**:
   - Select: **"No, we do not collect data from this app."**
2. **Third-Party Data / SDKs**:
   - None. No analytics, no advertising, no crash reporting SDKs.
3. **Tracking**:
   - The app does not track users across other apps or websites owned by other companies.
4. **Privacy Policy Link**:
   - `https://tianhaoz95.github.io/TapStory/privacy.html`

---

## 5. Age Rating & Kids Category Questionnaire

| Questionnaire Item | Selection |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature / Suggestive Themes | None |
| Horror / Fear Themes | None |
| Medical / Treatment Information | None |
| Alcohol, Tobacco, or Drug Use | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Unrestricted Web Access | No |
| Gambling | No |
| **Resulting Age Rating** | **4+** |
| **Made for Kids** | **Yes — Ages 5 and Under** |

---

## 6. Screenshots Guide & File Manifest

Screenshots are separated into dedicated, upload-ready directories under [`docs/screenshots/`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/):

```
docs/screenshots/
  phone/     # iPhone 6.5" / 1242 x 2688 px (drag-and-drop into iPhone tab)
  ipad/      # iPad 13" / 2064 x 2752 px (drag-and-drop into iPad 12.9" or 13" tab)
  watch/     # Apple Watch / 416 x 496 px (drag-and-drop into Apple Watch tab)
```

---

### Folder 1: Phone (`docs/screenshots/phone/`)
- **App Store Connect Requirement**: `1242 × 2688px, 2688 × 1242px, 1284 × 2778px or 2778 × 1284px`
- **Output Resolution**: `1242 × 2688 pixels` (Matches requirement verbatim)

| Order | File Name | Screen / Scene | Marketing Purpose |
|:---:|---|---|---|
| **1** | [`idle.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/phone/idle.png) | Idle / Waiting for Tap | Screen-free appliance resting state ("Tap a toy or card to begin") |
| **2** | [`story-magic-monkey.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/phone/story-magic-monkey.png) | Story Player | Story page with illustration & narration |
| **3** | [`vocab-letter-m.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/phone/vocab-letter-m.png) | Vocabulary Card | Alphabet flashcard ("M is for Monkey") |
| **4** | [`music-lullaby.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/phone/music-lullaby.png) | Music Player | Bedtime lullaby player |
| **5** | [`dashboard.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/phone/dashboard.png) | Parent Dashboard | Parent controls, custom voice recording & tag library |

*(Note: 6.9" display screenshots at `1320 x 2868 px` are also available in `docs/screenshots/iphone-17-pro-max/` if prompted for 6.9" screens).*

---

### Folder 2: iPad (`docs/screenshots/ipad/`)
- **App Store Connect Requirement**: `2064 × 2752px, 2752 × 2064px, 2048 × 2732px or 2732 × 2048px` (iPad 12.9" or 13" Displays)
- **Output Resolution**: `2064 × 2752 pixels` (Matches iPad Pro 13-inch M4/M5 requirement verbatim)

| Order | File Name | Screen / Scene | Marketing Purpose |
|:---:|---|---|---|
| **1** | [`idle.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/ipad/idle.png) | Idle / Waiting for Tap | Large screen-free resting state |
| **2** | [`story-magic-monkey.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/ipad/story-magic-monkey.png) | Story Player | Full-bleed story illustration & narration |
| **3** | [`vocab-letter-m.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/ipad/vocab-letter-m.png) | Vocabulary Card | High-res alphabet flashcard |
| **4** | [`music-lullaby.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/ipad/music-lullaby.png) | Music Player | Bedtime lullaby screen |
| **5** | [`dashboard.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/ipad/dashboard.png) | Parent Dashboard | Full-screen parent dashboard & tag management |

---

### Folder 3: Apple Watch (`docs/screenshots/watch/`)
- **App Store Connect Requirement**: Apple Watch 45mm / 46mm / Ultra Displays
- **Output Resolution**: `416 × 496 pixels`

| Order | File Name | Screen / Scene | Marketing Purpose |
|:---:|---|---|---|
| **1** | [`overview.png`](file:///Users/tianhaoz/GitHub/magic-box/docs/screenshots/watch/overview.png) | Apple Watch Companion UI | Remote control: Now Playing, Screen Display toggle, and saved tags |

---

### Regenerating Screenshots

To regenerate all raw device captures and automatically update the `phone/`, `ipad/`, and `watch/` folders, run:

```sh
./Scripts/capture_screenshots.sh
```

---

## 7. App Icon Specification

- **File**: `App/TapStory/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
- **Dimensions**: `1024 x 1024 pixels` (RGB, square, opaque, no pre-rounded corners)
- **Design**: Minimalist black background matching the resting screen with a warm gift box icon in TapStory orange.
- **Regenerate Script**: `python3 Scripts/generate_app_icon.py`
