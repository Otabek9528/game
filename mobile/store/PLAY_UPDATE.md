# Sending an update to your testers on Google Play

For a version after the first. The first release is in `play-launch-guide.html`.
About 20 minutes of your time, then Google's review.

The route: build → **Internal testing** (you alone, no review, minutes) → check
it on your phone → **promote the same release to Closed testing** (your
testers; Google reviews it first, usually within hours, sometimes a few days).
Updating does not restart the 14 days of the closed test, as long as 12 testers
stay in.

## 1. Find the next version code

Every upload needs a version code higher than any Google has seen from this
app, the old web build's included.

Play Console → your app → **Test and release → Latest releases and bundles**
(older consoles: App bundle explorer). Note the highest **version code** in the
list. Yours is that number plus 1. Below it is written `N`.

The version name is what people see. For this update: `1.1.0`.

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
Easier to read: nothing is cut off with larger text or in Russian, touch areas are bigger, dark mode has better contrast. HiKorea: your watches now always load, or say why not and offer to try again. Pages no longer keep loading forever on a weak connection.
</en-US>
<ru-RU>
Стало удобнее читать: текст больше не обрезается при крупном шрифте и на русском, кнопки стали крупнее, в тёмной теме выше контраст. HiKorea: ваши слежения теперь всегда загружаются или сообщают причину и предлагают повторить. Страницы больше не зависают на загрузке при слабой связи.
</ru-RU>
<uz>
O‘qish qulayroq: katta shrift bilan ham matn kesilmaydi, tugmalar kattaroq, tungi rejimda matn aniqroq. HiKorea: kuzatuvlaringiz endi doim yuklanadi yoki sababini aytib, qayta urinishni taklif qiladi. Internet sust bo‘lganda sahifalar yuklanishda qotib qolmaydi.
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

What to look at, 10 minutes:

| Where | What should be true |
|-------|---------------------|
| HiKorea home | "Kuzatuvlaringiz" ends within 20 seconds as one of three: your watches with their dates, "Hali kuzatuv yo‘q" with how to add one, or "couldn’t load" with **Qayta urinish**. A watch on a counter HiKorea removed says so instead of loading. |
| HiKorea, in airplane mode | An error with one retry button; after turning the network back on, the retry loads the page. |
| Phone settings → Display → Font size → largest | Cars: every card shows price, year, mileage, gearbox, fuel, date. Home: the six prayer names are whole. Nothing with a striped yellow-black edge. |
| A business card | The whole phone number is readable. |
| HiKorea calendar | The green button reads "HiKorea’da bron qilish" in full; days are easy to hit. |
| Dark mode | Button labels and grey secondary text are comfortable to read. |
| Cars → Qidirish → Android back | Returns to the first tab, then leaves (as before). |
| Sign in (Account → Kirish) with the largest font | The sheet's handle is below the status bar. |

## 5. Send it to your testers

Play Console → **Internal testing → Releases** tab → on the release you just
made: **Promote release → Closed testing** → your track (Alpha).

The notes carry over. **Next → Save → Send for review** (or **Start rollout
to Closed testing**).

Google reviews it. Publishing overview shows "In review", then "Available".
Testers then get it as an ordinary update, automatically within a day or at
once from the Play Store.

A message for your group, to send when it shows "Available":

> Assalomu alaykum! Ilovaning yangi versiyasi (1.1.0) chiqdi. Play Store’ni
> oching → profil rasmi → «Ilovalar va qurilmani boshqarish» → «Yangilanishlar»
> → Muslim Vegukin → «Yangilash». Katta shriftda ham hammasi o‘qiladigan
> bo‘ldi, HiKorea kuzatuvlari tuzatildi. Xato yoki taklif bo‘lsa, shu yerga
> yozing. Rahmat!

## If something goes wrong

| Message | What to do |
|---------|-----------|
| "Version code N has already been used" | Build again with a higher `--build-number`. |
| "Your Android App Bundle is signed with the wrong key" | `android\key.properties` is missing or points at another keystore: see `RELEASE.md`, section 1. |
| "You need to add release notes" or a language error | The tags must be languages your listing has. Remove the block Google names. |
| The update doesn't appear on a phone | Wait an hour; Play Store → Settings → About → tap "Update Play Store"; check the phone's Google account is on the testers list. |
| A problem found after rollout | A release can't be taken back. Fix, build with the next version code, upload again: testers get the newer one. |

## iPhone

Codemagic → workflow **iOS to TestFlight** → Start new build on branch
`claude/intelligent-clarke-88a75i`. Codemagic numbers the build itself.

Two things in this update could only be checked in tests, not on a real
iPhone. Please try them in the TestFlight build:

1. **Cars → Search tab, and Housing → My posts tab: swipe back from the left
   edge.** It should leave the section. (Before, the swipe did nothing there.)
2. **Account → Sign in, with a large text size** (Settings → Display &
   Brightness → Text Size, or Accessibility → Larger Text): the sheet's handle
   should be under the Dynamic Island, not behind it.
