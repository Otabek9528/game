# Muslim Vegukin — mobile app (Flutter)

One codebase for Android and iOS. This folder is a normal Flutter project; the
web app (Telegram Mini App) lives in the rest of the repository and is not
touched by anything here.

**What exists so far**

- First-launch language screen (Uzbek / Russian / English), remembered on the
  phone. Later it can be changed from inside the app.
- A placeholder home screen.
- Android app name, launcher icon and splash screen.

---

## 1. One-time setup on your computer

You already have Android Studio. You still need the **Flutter SDK** (the
toolkit) and the **Flutter plugin** (so Android Studio understands Flutter).

1. **Install the Flutter SDK** — follow the official guide for your system:
   <https://docs.flutter.dev/get-started/install>
   Choose *Android* as the target. Install the **latest stable** version; this
   project needs Flutter **3.47 or newer** (it was built with 3.47.7).
2. **Install the plugin**: Android Studio → *Settings* (on Mac: *Android
   Studio → Settings*) → *Plugins* → *Marketplace* → search **Flutter** →
   *Install*. It installs the Dart plugin too. Restart Android Studio.
3. **Point Android Studio at Flutter**: *Settings → Languages & Frameworks →
   Flutter → Flutter SDK path* → the folder where you unpacked Flutter.
4. **Android command-line tools**: *Settings → Languages & Frameworks →
   Android SDK → SDK Tools* tab → tick **Android SDK Command-line Tools** →
   *Apply*.
5. Open a terminal (Android Studio has one at the bottom: *Terminal*) and run:

   ```
   flutter doctor --android-licenses
   flutter doctor
   ```

   Answer `y` to the licences. `flutter doctor` should show a green tick next
   to **Flutter** and **Android toolchain**. Xcode/Chrome crosses are fine for
   now — they are for iOS and web.

## 2. Get the code

- With git: `git clone https://github.com/Otabek9528/game.git`
- Or on GitHub: *Code → Download ZIP*, then unzip.

## 3. Open and run

1. Android Studio → *File → Open* → choose the **`mobile`** folder (not the
   repository root).
2. If a banner says *"Pub get has not been run"*, click **Get dependencies**.
3. **Create a virtual phone**: *Tools → Device Manager → `+` → Create Virtual
   Device* → pick **Pixel 7** → pick the newest system image (download it if
   asked) → *Finish*. Start it with the ▶ next to it.
   A real phone works too: enable *Developer options → USB debugging* on it
   and plug it in.
4. In the toolbar, the device dropdown should show your phone; the config
   dropdown next to it shows **main.dart**. Press the green **▶ Run**.

   The first build takes several minutes (it downloads Gradle and Android
   libraries). Later runs take seconds.

5. While it runs, edit a file in `lib/` and press **⚡ Hot Reload** (or save)
   — the phone updates in about a second without restarting.

**To see the language screen again**: it only appears on the first launch.
Long-press the app icon → *App info* → *Storage* → *Clear storage*, or
uninstall the app, then run it again.

## 4. Where things are

```
mobile/
├── lib/                        ← all the app's code (Dart)
│   ├── main.dart               ← starts the app
│   ├── app.dart                ← theme, languages, first screen
│   ├── core/
│   │   ├── app_language.dart   ← the three languages + phone-language guess
│   │   ├── locale_controller.dart ← remembers the chosen language
│   │   ├── theme.dart          ← colours and fonts (from the web app)
│   │   └── widgets/khatam.dart ← the eight-pointed star mark and patterns
│   ├── features/
│   │   ├── onboarding/language_screen.dart
│   │   └── home/home_screen.dart
│   └── l10n/                   ← translations
│       ├── app_uz.arb          ← Uzbek (main file, with notes for translators)
│       ├── app_ru.arb
│       └── app_en.arb
├── assets/fonts/               ← Playfair Display, Amiri (+ their licence)
├── test/                       ← automatic tests
├── android/                    ← Android-only settings (icon, splash, name)
└── ios/                        ← iOS-only settings (later)
```

**Adding or changing text**: edit the three `.arb` files (same key in each),
then run the app — Flutter regenerates `lib/l10n/app_localizations*.dart` by
itself. Use it in code as `AppLocalizations.of(context).yourKey`.

**Uzbek apostrophes**: write `o‘` and `g‘` with **‘** (U+2018), and the
tutuq belgisi with **’** (U+2019). Android's Roboto font has no `ʻ`
(U+02BB), which would render in a mismatched fallback font.

## 5. Everyday commands

Run these in the terminal from the `mobile` folder:

| Command | What it does |
|---|---|
| `flutter pub get` | Download the packages listed in `pubspec.yaml` |
| `flutter run` | Build and start the app on the connected phone/emulator |
| `flutter test` | Run the automatic tests in `test/` |
| `flutter analyze` | Check the code for mistakes and style problems |
| `flutter build apk --release` | Build an installable APK (needs a signing key first — not set up yet) |

## Before the first Play Store upload

- **Application ID** — `com.vegukin.muslim_vegukin` in
  `android/app/build.gradle.kts`. It can never change once the app is
  published, so settle it before then.
- **Release signing key** — not set up yet; release builds currently use the
  debug key. Never commit the key file.
