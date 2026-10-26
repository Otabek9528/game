# Release: signed APK, AAB, Google Play

All commands run from the `mobile` folder, one line each (they work in
PowerShell and in bash).

## 1. Signing key (once; keep it forever)

Windows (PowerShell):

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\muslim-vegukin-upload.jks" -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

macOS/Linux: the same with `-keystore ~/muslim-vegukin-upload.jks`.

It asks for a password (twice), then name/organization/city (any answers),
then `yes`. Keep the key outside the project folder.

Create `android/key.properties` (git-ignored, never share it). Forward slashes,
even on Windows (a backslash is an escape character in this file):

```properties
storeFile=C:/Users/YOU/muslim-vegukin-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

`keyPassword` is the same as `storePassword` unless you chose a different one.
Without this file, release builds are signed with the debug key: they install,
but Google Play refuses them. Back up the `.jks` and the password somewhere
safe; losing them means asking Google for an upload-key reset.

## 2. Version

`pubspec.yaml` → `version: 1.0.0+1` (name + code). Raise the number after `+`
for every upload; Play rejects a code it has seen.

## 3. Build

```sh
flutter clean
flutter pub get
flutter analyze
flutter test

# APKs to share directly (one per CPU type; most phones: arm64-v8a)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols

# One APK for any phone (bigger)
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# For Google Play
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Outputs: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (etc.) and
`build/app/outputs/bundle/release/app-release.aab`. Keep `build/symbols` for
each release: it turns obfuscated crash reports back into readable ones.

Check the signature: `keytool -printcert -jarfile build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

## 4. Install and test on a phone

```sh
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Or send the APK file (Telegram, Drive); the phone asks to allow "Install unknown
apps" once. Check on a real phone, release build: first launch and language,
location prompt and prayer times, a reminder firing, home-screen widget, Qibla
(compass + camera), barcode scan, Google and Telegram sign-in, a push
notification, a Notifications area, cars/housing photo upload.

## 5. Google sign-in in release (must do, or sign-in fails)

Google Cloud console → the project of `googleServerClientId` → Credentials →
add an **Android** OAuth client for `com.vegukin.muslim_vegukin` with the SHA-1
of **both**:

- your upload key: `keytool -list -v -keystore "$env:USERPROFILE\muslim-vegukin-upload.jks" -alias upload`
- Play's app-signing key: Play Console → Test and release → App integrity →
  App signing (available after the first AAB upload).

## 6. Google Play

1. Play Console → Create app (name, language, free, app).
2. App content: privacy policy URL (required: location, account, push), Data
   safety (location: approximate/precise, app functionality, not shared;
   name/email/photo with Google sign-in; device id for push), ads: none,
   content rating questionnaire, target audience 18+ or general.
3. Store listing: short and full description, 512×512 icon, 1024×500 feature
   graphic, at least 2 phone screenshots.
4. Testing → Internal testing → Create release → upload `app-release.aab` →
   add testers → roll out. New personal accounts must run a closed test
   (12 testers, 14 days) before production.
5. Production → Create release → same AAB (or a newer one) → review → roll out.

Exact alarms (prayer reminders) use `SCHEDULE_EXACT_ALARM`, which the user
grants; it needs no Play declaration.
