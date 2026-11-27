# Sending a new version to Google Play

Muslim Vegukin is public. This is how each new version reaches everyone. The
first release is in `play-launch-guide.html`. About 20 minutes of your time,
then Google's review.

The route: build → **Internal testing** (you alone, no review, minutes) → check
it on your phone → **promote the same release to Production** (everyone; Google
reviews it first, usually within hours, sometimes a few days). Managed
publishing is off, so it goes live by itself once approved.

This update: **1.2.0**, mosque prayer times. The server and the web pages for
them are live already; the app only shows and edits them.

## 1. Find the next version code

Every upload needs a version code higher than any Google has seen from this
app, test builds included.

Play Console → your app → **Test and release → Latest releases and bundles**
(older consoles: App bundle explorer). Note the highest **version code** in the
list. Yours is that number plus 1. Below it is written `N` (6, if the last one
was 1.1.0 = 5).

The version name is what people see. Production has `5 (1.1.0)`; for this
update: `1.2.0`.

## 2. Build

PowerShell, one line at a time. Replace `N` in the last line.

```powershell
cd E:\dev\game
git checkout -- mobile/pubspec.yaml
git pull origin claude/intelligent-clarke-88a75i
cd mobile
flutter clean
flutter pub get
flutter test
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --build-name=1.2.0 --build-number=N
```

- The `git checkout` line drops a version you may have typed into
  `pubspec.yaml` before, which is what stopped `git pull` last time. The version
  comes from `--build-name` and `--build-number`; nothing in `pubspec.yaml`
  needs editing.
- `flutter test` must end with `All tests passed!` (435 tests). If it doesn't,
  stop and send me the last 30 lines.
- Don't run `flutter upgrade` for this update.
- `android\key.properties` must be in place, as for the first release. Without
  it the bundle is signed with the debug key and Google refuses it.

The file to upload: `E:\dev\game\mobile\build\app\outputs\bundle\release\app-release.aab`.

Copy the folder `build\symbols` somewhere safe as `symbols-1.2.0+N`: it makes
crash reports readable.

## 3. Upload to Internal testing

Play Console → **Test and release → Testing → Internal testing → Create new
release**.

1. **App bundles → Upload** → `app-release.aab`. Wait until it shows
   `N (1.2.0)`.
2. Release name: leave what Google fills in.
3. Release notes, pasted whole (drop the `<uz>` block if your listing has no
   Uzbek):

```
<en-US>
Mosque prayer times: congregation, Jumu'ah and Eid prayer times on each mosque's page. Signed-in users can add or correct them, and you can be told when they change.
</en-US>
<ru-RU>
Время намаза в мечетях: коллективный намаз, джума и праздничные намазы на странице каждой мечети. Войдя в аккаунт, можно добавить или исправить время, а об изменениях придёт уведомление.
</ru-RU>
<uz>
Masjid namoz vaqtlari: har bir masjid sahifasida jamoat namozi, juma va hayit namozi vaqtlari. Akkauntga kirgan har kim ularni qo‘shishi yoki tuzatishi mumkin, o‘zgarsa xabar keladi.
</uz>
```

4. **Next**. Yellow warnings are fine, red errors are not (see the end).
5. **Save → Start rollout to Internal testing**.

## 4. Check it on your own phone

Your phone has 1.1.0 from Google Play, so this time **the app itself offers
the update**: the first real run of the in-app update.

1. Wait 15–60 minutes after the rollout. Open Muslim Vegukin's page in the
   Play Store once (Play then knows about the new version), close it, and open
   the app.
2. **Play's own dialog**, "Update available" → **Update**.
3. **Home**: a card "Yangilanish · Yuklanmoqda…" with a moving bar. The app
   works as usual meanwhile.
4. "Yangilanish · Yangi versiya tayyor" → **O‘rnatish**. The app closes and
   opens again in a few seconds.
5. Account page, at the bottom: `Versiya 1.2.0 (N)`.

If no dialog comes after an hour, update it the usual way (Play Store → your
profile picture → **Manage apps and device → Updates available**) and tell me:
the in-app update then needs a look. Don't install an APK you built yourself
over it: its signature differs from Google's.

What to look at, 5–10 minutes:

| Where | What should be true |
|-------|---------------------|
| Masjidlar → a mosque with times | No map. After "Aloqa": "Jamoat namozi" with the times, the next prayer marked "keyingi", "Oxirgi yangilanish: …"; below a gold line "Hayit namozi" with Ramazon hayiti and Qurbon hayiti. The same times as the web page. |
| A mosque without times | "Vaqtlar hali qo‘shilmagan" and "Qo‘shish"; both Eids "qo‘shilmagan". |
| "Tahrirlash" (or "Qo‘shish") | Asks to sign in if you aren't. Six tiles; a tap shows the wheel under them; the tiles don't move. **Saqlash** → "Saqlandi"; the web page shows the same. |
| The pencil next to "Hayit namozi" | Both Eids; "+ Qo‘shish" adds a prayer; the bin removes the picked one. |
| Bildirishnomalar (with a watched place) | Under the watched places: the switch "Masjid namoz vaqtlari o‘zgarsa". |
| An oshxona or a do‘kon | Its map is still there. |
| Phone settings → largest font size, then a place page | The top (type, Kuzatish, stars) and the Naver/Kakao/Google buttons are whole, not cut. |

Editing a real mosque is live for everyone at once, and once
`TIMETABLE_NOTIFY` is `"on"` its watchers get a message. To try it without
telling anyone: change a time and put it back within 10 minutes; nothing goes
out then (Timetables → Messages shows "Not sent: changed back").

## 5. Release it to everyone

Play Console → **Test and release → Testing → Internal testing → Releases** tab
→ on the release you just made: **Promote release → Production**.

The notes carry over. Rollout **100 %** → **Next → Save → Start rollout to
Production**. Publishing overview shows "Changes in review"; don't press
"Remove changes". Once Google approves, it goes live by itself. People on 1.1.0
get the in-app offer; older ones the ordinary Play update.

A message for your group, once it is live:

> Assalomu alaykum! Yangi versiya (1.2.0): masjid sahifasida endi jamoat
> namozi, juma va hayit namozi vaqtlari bor. Vaqt noto‘g‘ri bo‘lsa, akkauntga
> kirib o‘zingiz tuzating — hamma darhol ko‘radi. Ilova o‘zi yangilanishni taklif
> qiladi; bo‘lmasa Play Store → Muslim Vegukin → «Yangilash».

## If something goes wrong

| Message | What to do |
|---------|-----------|
| "Version code N has already been used" | Build again with a higher `--build-number`. |
| "Your Android App Bundle is signed with the wrong key" | `android\key.properties` is missing or points at another keystore: see `RELEASE.md`, section 1. |
| "You need to add release notes" or a language error | The tags must be languages your listing has. Remove the block Google names. |
| `git pull` says local changes would be overwritten | Run `git checkout -- mobile/pubspec.yaml` and pull again. |
| The update doesn't appear on a phone | Wait an hour; Play Store → Settings → About → tap "Update Play Store"; for a test build, check the phone's Google account is on the testers list. |
| No update dialog in the app | Only an app installed from Google Play gets one. Open the app's Play Store page once and reopen the app. A version you declined is offered again after three days, or at once from Akkaunt → Ilova → Yangilanish. |
| No "Jamoat namozi" on any mosque | The server's prayer-time update isn't running there: the app hides the section on a server without it. |
| A problem found after rollout | A release can't be taken back. Fix, build with the next version code, upload again: testers get the newer one. |

## iPhone

Codemagic → workflow **iOS to TestFlight** → Start new build on branch
`claude/intelligent-clarke-88a75i`. Codemagic numbers the build itself.

The in-app update is Android only; the App Store updates apps by itself.

Worth trying in the TestFlight build, as it could only be checked in tests:

1. **A mosque → Tahrirlash → a tile**: the two wheels turn smoothly and the
   tile's time follows.
2. **The largest text size** (Settings → Accessibility → Display & Text Size →
   Larger Text), then a place page: the top and the navigator buttons are whole.
