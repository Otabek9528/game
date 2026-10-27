# Muslim Vegukin on iPhone

## What is ready, and what isn't

Written for iOS and in the project, but **never built or run**: there was no Mac. The Swift files pass a syntax
check; type errors and runtime behaviour can only show up on a Mac. Expect one round of fixes on first build.

| Part | State |
|---|---|
| The app itself (all Flutter screens) | Shared with Android; nothing to do |
| Native side (`Runner/VegukinPlugin.swift` and friends): Qibla compass and camera, prayer reminders, share sheet, test notification, bank apps, device info | Written, mirrors the Android code |
| Push notifications | Code ready; needs the Firebase iOS app + APNs key (step 2) |
| Google sign-in | Code ready; hidden on iPhone until its client id is filled in (step 2) |
| Telegram and WhatsApp sign-in | Work as on Android (they open the bots) |
| Home-screen widget (`PrayerWidget/PrayerWidget.swift`) | Source ready; the widget **target** must be added once in Xcode on a Mac (step 5). The app works without it |
| App icon, launch screen, permission texts (uz/ru/en), iPhone-only, portrait | Done |

Differences from Android, by necessity:
- Reminders set to "vibrate" come as standard iOS notifications (iOS has no vibration-only notification: they
  vibrate when the ring switch is on silent).
- The donation page shows only Toss, KakaoBank and KB Star: iPhones reveal installed apps only by URL scheme, and
  only those three schemes are certain. Others can be added in `VegukinPlugin.swift` (`bankSchemes`) and
  `Info.plist` (`LSApplicationQueriesSchemes`).
- No "Alarms & reminders" permission prompt: iOS needs none.

## 1. Accounts (once)

- **Apple Developer Program**: <https://developer.apple.com/programs/> — US$99 a year. Enroll as an individual
  (your name shows as the seller) or an organization (needs a D-U-N-S number).
- In <https://developer.apple.com/account> → Certificates, Identifiers & Profiles → **Identifiers** → `+` → App IDs →
  Bundle ID `com.vegukin.muslimVegukin`, capabilities **Push Notifications** and **App Groups**. Then Identifiers →
  App Groups → `+` → `group.com.vegukin.muslimVegukin`, and assign it to the App ID.
  (Xcode's automatic signing can do this itself; doing it here avoids surprises.)

## 2. Firebase and Google (once)

1. Firebase console → project **muslim-vegukin** → Project settings → **Add app → iOS**. Bundle ID
   `com.vegukin.muslimVegukin`. Download `GoogleService-Info.plist` (you don't add the file to Xcode; copy four values
   from it):
   - `API_KEY` → `firebaseIosApiKey` in `lib/core/push.dart`
   - `GOOGLE_APP_ID` → `firebaseIosAppId` in `lib/core/push.dart`
   - `CLIENT_ID` → `googleIosClientId` in `lib/core/google_auth.dart`
   - `REVERSED_CLIENT_ID` → in `ios/Runner/Info.plist`, replace
     `com.googleusercontent.apps.REPLACE_WITH_IOS_CLIENT_ID_PREFIX` with it

   If the plist has no `CLIENT_ID`: Google Cloud console → APIs & Services → Credentials → Create OAuth client ID →
   iOS → bundle ID `com.vegukin.muslimVegukin`; it shows the client ID and its reversed form ("iOS URL scheme").
2. **APNs key** (lets Firebase reach iPhones): Apple Developer → **Keys** → `+` → enable *Apple Push Notifications
   service (APNs)* → download the `.p8` (only once!) and note the Key ID. Firebase → Project settings → **Cloud
   Messaging** → Apple app configuration → APNs Authentication Key → upload it with the Key ID and your Team ID.
3. **Server:** add the iOS `CLIENT_ID` to `APP_GOOGLE_CLIENT_IDS` in the API's `.env` (comma-separated after the web
   one) and restart `vegukin.service`. iPhone Google tokens are issued for the iOS client, and the server only
   accepts the ids listed there.

Commit the three Dart/Info.plist values; none of them is secret (every copy of the app carries them).

## 3. Building: with a Mac, or without one

**A. With a Mac** (yours, borrowed, or rented by the hour, e.g. MacinCloud): install Xcode from the App Store and
Flutter (<https://docs.flutter.dev/get-started/install/macos>), then:

```sh
git clone <the repo> && cd game/mobile
git checkout claude/intelligent-clarke-88a75i
flutter pub get
open ios/Runner.xcworkspace
```

In Xcode: Runner target → **Signing & Capabilities** → Team: yours, *Automatically manage signing*. The
capabilities Push Notifications, App Groups and Background Modes (Remote notifications) appear by themselves (the
project carries `Runner/Runner.entitlements`).

Run on an iPhone (cable, *Trust this computer*): `flutter run --release`. The first time, the iPhone asks you to
trust the developer: Settings → General → VPN & Device Management.

**B. Without a Mac**: Codemagic (<https://codemagic.io>, free tier ~500 build minutes a month) builds iOS apps on
its Macs from GitHub and uploads them to TestFlight. Connect the repository, pick the Flutter workflow, branch
`claude/intelligent-clarke-88a75i`, project path `mobile`, build for iOS, and under *iOS code signing* add an
**App Store Connect API key** (App Store Connect → Users and Access → Integrations → Keys) with automatic signing.
Everything except the widget works this way; the widget target needs Xcode once (step 5), so ship v1 without it if
there's no Mac.

## 4. First run: what to check

First launch and language; location prompt (texts in the app's language) and prayer times; a prayer reminder
firing (set one a minute ahead); the Qibla compass (lying flat, then the camera view standing up: the Kaaba marker
should sit where the compass points); a barcode scan; Telegram and WhatsApp sign-in; Google sign-in; Account →
**Send a test** → "Arrived on this phone" and a banner; sharing the app; a car listing with photos.

If something fails to compile, send me the error lines from Xcode's Issue navigator.

## 5. The home-screen widget (Mac, once)

1. Xcode → File → New → Target → **Widget Extension** → Product Name `PrayerWidget`, uncheck *Include Live
   Activity* and *Include Configuration App Intent* → Finish → *Don't activate* the new scheme.
2. Delete the Swift files Xcode generated in the new `PrayerWidget` group (*Move to Trash*), then drag
   `ios/PrayerWidget/PrayerWidget.swift` into that group, with only the **PrayerWidget** target ticked.
3. PrayerWidget target → General → Minimum Deployments **iOS 16.0**; Bundle Identifier
   `com.vegukin.muslimVegukin.PrayerWidget`.
4. PrayerWidget target → Signing & Capabilities → `+ Capability` → **App Groups** → tick
   `group.com.vegukin.muslimVegukin` (the same one the app has).
5. If the build stops with *"Cycle inside Runner"*: Runner target → Build Phases → drag **Embed Foundation
   Extensions** up, right under *Copy Bundle Resources* (above *Thin Binary*).

The widget then shows the next prayer with a countdown (small), the day's six times (medium) and the next prayer
on the lock screen; it fills in after the app has been opened once.

## 6. TestFlight and the App Store

1. App Store Connect (<https://appstoreconnect.apple.com>) → Apps → `+` → New App: iOS, name `Muslim Vegukin`,
   primary language, bundle ID `com.vegukin.muslimVegukin`, SKU e.g. `muslim-vegukin`.
2. Build and upload: `flutter build ipa --release --obfuscate --split-debug-info=build/symbols`, then open
   `build/ios/ipa/*.ipa` in Apple's **Transporter** app and Deliver (or Xcode → Product → Archive → Distribute).
   Raise `version:` in `pubspec.yaml` for each upload, as for Android.
3. **TestFlight**: the build appears after processing (~15 min). Internal testers (up to 100, your team) need no
   review; external testers (a public link) need a short beta review.
4. **App Store listing**: the descriptions in `../store/PLAY_STORE.md` fit; subtitle (30 chars) e.g. "Prayer times,
   qibla, HiKorea". Screenshots: 6.9-inch (1320 × 2868) are required; take them on a big iPhone or the simulator.
   Privacy policy URL: `https://vegukin-twa.pages.dev/privacy.html`. Category: Lifestyle. Age rating questionnaire:
   all "None"; user-generated content: yes.
5. **App Privacy** ("nutrition label"): the same data as Play's Data safety table in `../store/PLAY_STORE.md`
   (location, name, email, phone number, user ID, photos/videos, other user content, product interaction, device
   ID), none used for tracking, linked to the user.
6. **Review notes**: "Signing in is optional. Most features work without it. Sign-in through Telegram or WhatsApp
   needs the reviewer's own account; Google sign-in works with any Google account."

## Review risks to settle before submitting

- **Sign in with Apple (guideline 4.8).** Apps whose sign-in uses Google (or other third-party logins) must also
  offer Sign in with Apple or an equivalent private login. Ours offers Google, Telegram and WhatsApp, so a rejection
  is likely. Adding it means an Apple button in the sign-in sheet and a server endpoint that checks Apple's token —
  a contained piece of work; best done before the first submission.
- **Donations (guideline 3.1.1 / 3.2.2).** Asking for donations to the developer outside Apple's in-app purchase
  is usually rejected for apps that aren't registered charities. Safest: hide the donation page on iPhone, or link
  to it on the web.
