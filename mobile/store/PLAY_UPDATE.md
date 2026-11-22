# Sending a new version to Google Play

Muslim Vegukin is public. This is how each new version reaches everyone. The
first release is in `play-launch-guide.html`. About 20 minutes of your time,
then Google's review.

The route: build → **Internal testing** (you alone, no review, minutes) → check
it on your phone → **promote the same release to Production** (everyone; Google
reviews it first, usually within hours, sometimes a few days). Managed
publishing is off, so it goes live by itself once approved.

## 1. Find the next version code

Every upload needs a version code higher than any Google has seen from this
app, the old web build's included.

Play Console → your app → **Test and release → Latest releases and bundles**
(older consoles: App bundle explorer). Note the highest **version code** in the
list. Yours is that number plus 1. Below it is written `N`.

The version name is what people see. Production has `4 (1.0.0)`; for this
update: `1.1.0`.

## 2. Build

PowerShell, one line at a time. Replace `N` in the last line.

```powershell
cd E:\dev\game
git pull origin claude/intelligent-clarke-88a75i
cd mobile
flutter clean
flutter pub get
flutter test
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --build-name=1.1.0 --build-number=N
```

- `flutter test` must end with `All tests passed!`. If it doesn't, stop and
  send me the last 30 lines.
- `flutter --version` shows which Flutter builds the app. The iPhone app is
  built on 3.47.9 (`codemagic.yaml`). On a 3.47 version or on 3.50 the tests
  pass and the build works; 3.50 only adds 108 "deprecated" notices to
  `flutter analyze`. For this update, don't run `flutter upgrade`.
- `--build-name` and `--build-number` set the version for this build. Nothing
  in `pubspec.yaml` needs editing.
- `android\key.properties` must be in place, as for the first release. Without
  it the bundle is signed with the debug key and Google refuses it.

The file to upload: `E:\dev\game\mobile\build\app\outputs\bundle\release\app-release.aab`.

Copy the folder `build\symbols` somewhere safe as `symbols-1.1.0+N`: it makes
crash reports readable.

## 3. Upload to Internal testing

Play Console → **Test and release → Testing → Internal testing → Create new
release**.

1. **App bundles → Upload** → `app-release.aab`. Wait until it shows
   `N (1.1.0)`.
2. Release name: leave what Google fills in.
3. Release notes, pasted whole (drop the `<uz>` block if your listing has no
   Uzbek):

```
<en-US>
Other platforms: tap the Muslim Vegukin logo on the home screen for our Telegram bot, web app, WhatsApp bot and group. Updates now install from inside the app.
</en-US>
<ru-RU>
Другие платформы: нажмите на логотип Muslim Vegukin на главном экране — Telegram-бот, веб-приложение, WhatsApp-бот и группа. Обновления теперь устанавливаются прямо из приложения.
</ru-RU>
<uz>
Boshqa platformalar: bosh sahifadagi Muslim Vegukin logotipini bosing — Telegram bot, veb-ilova, WhatsApp bot va guruh. Yangilanishlar endi ilovaning o‘zida o‘rnatiladi.
</uz>
```

4. **Next**. Yellow warnings are fine, red errors are not (see the end).
5. **Save → Start rollout to Internal testing**.

## 4. Check it on your own phone

Play Store → your profile picture → **Manage apps and device → Updates
available** → Muslim Vegukin → **Update**. It can take up to an hour to appear.
Don't install an APK you built yourself over it: its signature differs from
Google's, so the phone would make you uninstall first and you would lose the
app's settings.

Account page, at the bottom: it should read `Versiya 1.1.0 (N)`.

What to look at, 5 minutes:

| Where | What should be true |
|-------|---------------------|
| Home: tap the logo or the name "Muslim Vegukin" | "Boshqa platformalar" opens from the bottom. |
| Its three cards | Telegram bot opens the bot in Telegram; WhatsApp bot opens WhatsApp with "start" typed in; Telegram guruh opens the group. |
| "Ulashish" | The share menu opens with one message: the Play link, the bot, WhatsApp, the group. |
| Akkaunt → Ilova → "Boshqa platformalar" | The same sheet. |
| Home, Prayers, a reminder, HiKorea | As before. |

The update offer itself can only be seen with a version newer than this one:
see "Trying the in-app update" below.

## 5. Release it to everyone

Play Console → **Test and release → Testing → Internal testing → Releases** tab
→ on the release you just made: **Promote release → Production**.

The notes carry over. Rollout **100 %** → **Next → Save → Start rollout to
Production**. Publishing overview shows "Changes in review"; don't press
"Remove changes". Once Google approves, it goes live by itself. People get it
as an ordinary Play update, automatically within a day or at once from the Play
Store. Your closed-test testers get it too: Play gives everyone the highest
version they can have.

A message for your group, once it is live:

> Assalomu alaykum! Yangi versiya (1.1.0): Play Store → Muslim Vegukin →
> «Yangilash». Yangilik: bosh sahifadagi logotipni bosing — Telegram, WhatsApp
> va guruhimiz bir joyda. Keyingi yangilanishlar ilovaning o‘zida keladi.

## Trying the in-app update

The offer is part of the app's code, so it works from the version after the one
that has it. People on 1.0.0 (4) get 1.1.0 the usual Play way; from 1.1.0 on,
each new version is offered inside the app.

To see it yourself before your users do:

1. Have 1.1.0 (`N`) on your phone **from Google Play** (section 4). An APK you
   built yourself never gets an offer.
2. Build the same code again with the next number:
   `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --build-name=1.1.1 --build-number=N+1`
   (write the number, e.g. `--build-number=6`).
3. Upload it to **Internal testing** only (section 3); notes: "Test build".
4. Wait 15–60 minutes. Open the app's page in the Play Store once (Play then
   knows about the new version), close it, and open the app.
5. What should happen:
   - **Play's own dialog**, "Update available" → **Update**.
   - **Home**: a card "Yangilanish · Yuklanmoqda…" with a moving bar. Use the
     app meanwhile: it works as usual.
   - Then "Yangilanish · Yangi versiya tayyor" → **O‘rnatish**. The app closes
     and opens again in a few seconds; the Account page reads
     `Versiya 1.1.1 (N+1)`.
6. Also worth trying, with a version after that:
   - **"No thanks"** in Play's dialog: it isn't offered again for three days.
     Akkaunt → Ilova shows "Yangilanish · Yangi versiya bor" meanwhile; a tap
     offers it again.
   - **Don't press O‘rnatish**: leave the app from its home screen (the phone's
     Home button). The next time you open it, it is the new version.

1.1.1 is the same app as 1.1.0, so it can go to Production later too.

## If something goes wrong

| Message | What to do |
|---------|-----------|
| "Version code N has already been used" | Build again with a higher `--build-number`. |
| "Your Android App Bundle is signed with the wrong key" | `android\key.properties` is missing or points at another keystore: see `RELEASE.md`, section 1. |
| "You need to add release notes" or a language error | The tags must be languages your listing has. Remove the block Google names. |
| The update doesn't appear on a phone | Wait an hour; Play Store → Settings → About → tap "Update Play Store"; for a test build, check the phone's Google account is on the testers list. |
| No update dialog in the app | Only an app installed from Google Play gets one. Open the app's Play Store page once and reopen the app. A version you declined is offered again after three days, or at once from Akkaunt → Ilova → Yangilanish. |
| A problem found after rollout | A release can't be taken back. Fix, build with the next version code, upload again: testers get the newer one. |

## iPhone

Codemagic → workflow **iOS to TestFlight** → Start new build on branch
`claude/intelligent-clarke-88a75i`. Codemagic numbers the build itself.

The in-app update is Android only: an iPhone has no such feature, and the App
Store updates apps by itself. The platforms sheet works on both.

Three things could only be checked in tests, not on a real iPhone. Please try
them in the TestFlight build:

1. **Cars → Search tab, and Housing → My posts tab: swipe back from the left
   edge.** It should leave the section. (Before, the swipe did nothing there.)
2. **Account → Sign in, with a large text size** (Settings → Display &
   Brightness → Text Size, or Accessibility → Larger Text): the sheet's handle
   should be under the Dynamic Island, not behind it.
3. **Home: tap the logo.** The platforms sheet opens; each card opens Telegram
   or WhatsApp.
