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

### The Play Console entry already has an upload key

The app's Play Console entry was first used by the web app's build (TWA), which
fixed its ID (`com.muslimVegukin.myapp`) and its **upload key**. Play accepts a
new `.aab` only if it is signed with that same key.

- Play Console → Protected with Play → Play Store protection → Protect app
  signing key (older consoles: Test and release → App integrity → App signing) →
  **Upload key certificate**: note its SHA-1.
- Your key's SHA-1: `keytool -list -v -keystore "$env:USERPROFILE\muslim-vegukin-upload.jks" -alias upload`.
- The same: nothing to do. Different: either point `key.properties` at the web
  app build's keystore (PWABuilder's download has `signing.keystore` and its
  passwords in `signing-key-info.txt`; Bubblewrap's is `android.keystore`), or on
  that same page **Request upload key reset** with the certificate of your key
  (`keytool -export -rfc -keystore "$env:USERPROFILE\muslim-vegukin-upload.jks" -alias upload -file upload_certificate.pem`)
  and wait for Google's email (a few days).

## 2. Version

`pubspec.yaml` → `version: 1.0.0+1` (name + code). Raise the number after `+`
for every upload; Play rejects a code it has seen, including the web app
build's (Play Console → Test and release → App bundle explorer lists them).

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

Check the signature (`keytool -printcert` can't: with minSdk 24 the APK has
only the v2/v3 signature, so it says "Not a signed jar file"). Windows, from
`mobile` (the SDK's location is read from `android/local.properties`):

```powershell
$sdk = (Select-String -Path android\local.properties -Pattern '^sdk\.dir=(.*)').Matches[0].Groups[1].Value -replace '\\:',':' -replace '\\\\','\'
$apksigner = (Get-ChildItem "$sdk\build-tools\*\apksigner.bat" | Select-Object -Last 1).FullName
& $apksigner verify --print-certs build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

`Signer #1 certificate DN` must be your name, not `CN=Android Debug`; its
SHA-1 must match `keytool -list` on your `.jks`.

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
add an **Android** OAuth client for `com.muslimVegukin.myapp` with the SHA-1
of **both**:

- your upload key: `keytool -list -v -keystore "$env:USERPROFILE\muslim-vegukin-upload.jks" -alias upload`
- Play's app-signing key: Play Console → Protected with Play → Play Store
  protection → Protect app signing key → *App signing key certificate*
  (older consoles: Test and release → App integrity → App signing).

## 6. Google Play

Step by step, with the listing texts in three languages, the Data safety answers and the store graphics:
[`store/PLAY_STORE.md`](store/PLAY_STORE.md). Publish `store/privacy.html` on the web app first.
