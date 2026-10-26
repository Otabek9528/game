# Muslim Vegukin — mobile app (Flutter)

One codebase for Android and iOS. This folder is a normal Flutter project; the
web app (Telegram Mini App) lives in the rest of the repository and is not
touched by anything here.

**What exists so far**

- First-launch language screen (Uzbek / Russian / English), remembered on the
  phone. Later it can be changed from the home screen.
- Home screen, same layout as the web app: prayer card (date, Hijri date,
  city, countdown, the day's six times), business directory band, and every
  section as a tile.
- Sections open their **web pages inside the app** until each one is rebuilt
  natively. The app stands in for Telegram, so the pages' back button, links,
  pop-ups and vibration work. Anything that signs the user in (posting,
  reviews, watches, notifications) still needs Telegram for now.
- Sections that exist only in Uzbek are shown to everyone, tagged **UZ**.
- Android app name, launcher icon and splash screen.

The web pages are loaded from the address in `lib/core/config.dart`
(`webBase`, this repository's GitHub Pages site). Change it there if the bot
serves them from somewhere else.

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
├── lib/                          ← all the app's code (Dart)
│   ├── main.dart                 ← starts the app, creates the services
│   ├── app.dart                  ← theme, languages, first screen
│   ├── app_services.dart         ← what every screen can use
│   ├── core/
│   │   ├── config.dart           ← web app and API addresses
│   │   ├── app_language.dart     ← the three languages + phone-language guess
│   │   ├── locale_controller.dart← remembers the chosen language
│   │   ├── key_value_store.dart  ← small saved values (location, times)
│   │   ├── theme.dart            ← colours and fonts (from the web app)
│   │   └── widgets/khatam.dart   ← the eight-pointed star mark and patterns
│   ├── features/
│   │   ├── onboarding/language_screen.dart
│   │   ├── home/                 ← home screen, prayer card, list of sections
│   │   ├── prayer/               ← location, prayer times, countdown logic
│   │   ├── prayers/              ← the prayer times page (from pages/prayers.html)
│   │   ├── qibla/                ← Qibla compass and camera view (from pages/qibla/)
│   │   ├── reminders/            ← per-prayer reminders: choices, sheet, schedule
│   │   ├── widget/               ← hands data to the home-screen widgets
│   │   └── web/web_feature_screen.dart ← shows a web page, plays Telegram's part
│   └── l10n/                     ← translations
│       ├── app_uz.arb            ← Uzbek (main file, with notes for translators)
│       ├── app_ru.arb
│       └── app_en.arb
├── assets/fonts/                 ← Playfair Display, Amiri (+ their licence)
├── test/                         ← automatic tests
├── android/                      ← Android-only settings (icon, splash, permissions),
│                                   home-screen widgets and reminder notifications
├── tool/                         ← scripts that made the widget wordmark and the chime
└── ios/                          ← iOS-only settings (later)
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
| `flutter build apk --release` | Build an installable APK (signing, AAB and Google Play: see `RELEASE.md`) |

## Before the first Play Store upload

- **Application ID** — `com.vegukin.muslim_vegukin` in
  `android/app/build.gradle.kts`. It can never change once the app is
  published, so settle it before then.
- **Release signing, building and publishing** — `RELEASE.md`.
