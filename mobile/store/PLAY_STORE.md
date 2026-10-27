# Publishing Muslim Vegukin on Google Play

Everything Play Console asks for, in the order it asks. Files referred to are in this folder (`mobile/store/`).
Building and signing the `.aab`: `../RELEASE.md`.

## 0. Before you start (once)

1. **Publish the privacy policy.** Copy `privacy.html` to the root of the web app's repository (the one served at
   `https://vegukin-twa.pages.dev/`) and deploy. Check that both open:
   - `https://vegukin-twa.pages.dev/privacy.html` — the privacy policy (the app's Account page links here)
   - `https://vegukin-twa.pages.dev/privacy.html#delete` — the account-deletion section
2. **Developer account:** <https://play.google.com/console/signup>, US$25 once. Choose *Personal* (yourself) or
   *Organization* (needs a D-U-N-S number). Google verifies your identity (passport/ID, sometimes a phone and
   address check); this can take a few days.
   - **Personal accounts must run a closed test with at least 12 testers for 14 days in a row before they can
     publish to everyone** (step 6). Start recruiting testers now: your Telegram group is the obvious place.
3. **Build the bundle:** `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
   → `build/app/outputs/bundle/release/app-release.aab`. Raise `version:` in `pubspec.yaml` (the number after
   `+`) for every upload.
4. **Screenshots:** take them on a real phone (Power + Volume down), in Uzbek for the Uzbek listing, English for
   the English one. 4–8 portrait screenshots, no status-bar clutter. Suggested set: home screen, prayer times,
   Qibla, a mosque or restaurant page with the map, HiKorea, Notifications, ingredient check result, account.

## 1. Create the app

Play Console → **Create app**:

| Field | Answer |
|---|---|
| App name | `Muslim Vegukin` |
| Default language | `Uzbek – uz` (or English; the others are added as translations) |
| App or game | App |
| Free or paid | Free (permanent: a free app can never become paid) |
| Declarations | tick both (Developer Program Policies, US export laws) |

## 2. Set up your app (Dashboard → "Set up your app")

Each item opens a short form.

**App access** → *All or some functionality is restricted* → Add instructions:
> Most of the app works without signing in. Posting reviews needs sign-in: on the Account page tap
> "Sign in" → "Continue with Google" and use any Google account. Posting car, housing and job listings requires the
> user's own Telegram account, because those listings are published to Telegram groups; no test account can be
> provided for it.

**Ads** → No, my app does not contain ads.

**Content rating** → Start questionnaire. Email: yours. Category: *All other app types*. Answer **No** to violence,
fear, sexuality, language, drugs, gambling, crude humour. **Yes** to "Does the app allow users to interact or exchange
content?" (reviews and listings are public). **No** to sharing location with other users and to digital purchases.
Expected result: rated for everyone (3+ / Everyone) with "Users Interact".

**Target audience** → **18 and over** only. (Choosing younger ages brings the Families policy and extra reviews.)
"Could your app unintentionally appeal to children?" → No.

**News app** → No. **COVID-19** → not a COVID app. **Government app** → No. **Financial features** → none.
**Health** → none.

**Advertising ID** → *No* (the app doesn't use it; the manifest removes the permission).

**Data safety** → answer as below. Privacy policy URL: `https://vegukin-twa.pages.dev/privacy.html`.

- Does your app collect or share any of the required user data types? **Yes**
- Is all of the user data collected by your app encrypted in transit? **Yes**
- Which ways can users request that their data is deleted? **In the app** and **a URL**:
  `https://vegukin-twa.pages.dev/privacy.html#delete`

| Data type | Collected | Shared | Optional? | Purposes |
|---|---|---|---|---|
| Location → Approximate location | Yes | Yes¹ | Optional | App functionality |
| Location → Precise location | Yes | Yes¹ | Optional | App functionality |
| Personal info → Name | Yes | No | Optional | App functionality, Account management |
| Personal info → Email address | Yes | No | Optional | Account management |
| Personal info → User IDs | Yes | No | Required | App functionality, Account management, Analytics |
| Personal info → Phone number | Yes | No | Optional | Account management |
| Photos and videos → Photos | Yes | No | Optional | App functionality |
| Photos and videos → Videos | Yes | No | Optional | App functionality |
| App activity → App interactions | Yes | No | Required | Analytics |
| App activity → Other user-generated content | Yes | No | Optional | App functionality |
| Device or other IDs | Yes | No | Required | App functionality, Analytics |

¹ Coordinates go to AlAdhan (prayer times) and OpenStreetMap Nominatim (the city's name). Declaring this as
"shared" is the safe answer: Play penalises declaring less than the app does, not more.

Everything else (financial info, health, messages, contacts, calendar, audio, files, web history, crash logs): **No**.

## 3. Store listing (Grow → Store presence → Main store listing)

Upload: **App icon** `play_icon_512.png`; **Feature graphic** `feature_graphic.png`; **Phone screenshots** (yours).
Category: **Lifestyle**. Tags: Religion, Maps & Navigation (or the closest offered). Contact email: required and
public; website: `https://vegukin-twa.pages.dev/`.

Then **Manage translations → Add your own translations** for English and Russian, and paste each language's texts.

The Russian and English listings mention only what those languages show in the app: cars, housing, jobs, parcels,
links, the business directory and Q&A are offered in Uzbek only.

### Uzbek (uz)

**Short description** (≤ 80):
```
Namoz vaqtlari, qibla, halol joylar, HiKorea navbatlari — Koreyadagilar uchun
```
**Full description:**
```
Muslim Vegukin — Koreyada yashovchi musulmonlar uchun bitta ilovada hamma kerakli narsa.

🕌 NAMOZ VAQTLARI
• Shahringiz uchun aniq namoz vaqtlari, imsak va tunning oxirgi uchdan biri
• Har bir namoz uchun eslatma: ovoz, tebranish yoki jim
• Bosh ekran uchun ikki xil vidjet: keyingi namoz va qolgan vaqt

🧭 QIBLA
• Kompas va kamera orqali qibla yo‘nalishi
• Quyosh bo‘yicha kompasni tekshirish va aniqlik ko‘rsatkichi

📍 MASJIDLAR, HALOL RESTORANLAR VA DO‘KONLAR
• Yaqiningizdagi joylar, xarita, ish vaqtlari va izohlar
• Yangi joy taklif qilish va joy haqida xabar olish

🔔 BILDIRISHNOMALAR
• Tanlagan hududingizda yangi masjid yoki restoran ochilsa — xabar
• Kuzatayotgan joylaringizdagi o‘zgarishlar

🛂 HIKOREA NAVBATLARI
• Immigratsiya ofislarida bo‘sh kunlarni kuzatish va ochilganda darhol xabar olish

🔍 TARKIB TEKSHIRUVI
• Mahsulot shtrix-kodini skanerlang — halol yoki yo‘qligini bilib oling

🚗 AVTOMOBIL, 🏠 UY-JOY, 💼 ISH, 📦 POSILKA
• E’lonlarni ko‘rish, saqlash va o‘z e’loningizni joylash
• Telegram guruhlari, biznes katalogi va savol-javoblar

Ilova o‘zbek, rus va ingliz tillarida, kunduzgi va tungi rejimda ishlaydi. Reklama yo‘q.
Kirish ixtiyoriy: Telegram, WhatsApp yoki Google orqali.
```

### English (en-US)

**Short description:**
```
Prayer times, qibla, halal places and HiKorea alerts for Muslims in Korea
```
**Full description:**
```
Muslim Vegukin brings what Muslims living in Korea need into one app.

🕌 PRAYER TIMES
• Accurate prayer times for your city, with imsak and the last third of the night
• A reminder for each prayer: sound, vibration or silent
• Two home-screen widgets: the next prayer and the time left

🧭 QIBLA
• The qibla direction with the compass and the camera
• Check the compass against the sun, with an accuracy indicator

📍 MOSQUES, HALAL RESTAURANTS AND SHOPS
• Places near you with a map, opening hours and reviews
• Suggest a new place, and follow places you care about

🔔 NOTIFICATIONS
• Hear when a new mosque or restaurant opens in an area you choose
• Updates about the places you follow

🛂 HIKOREA APPOINTMENTS
• Watch immigration offices for free days and get notified the moment one opens

🔍 INGREDIENT CHECK
• Scan a product's barcode to see whether it is halal

Available in English, Russian and Uzbek, in light and dark mode. No ads.
Signing in is optional: with Telegram, WhatsApp or Google.
```

### Russian (ru-RU)

**Short description:**
```
Время намаза, кибла, халяль-места и HiKorea для мусульман в Корее
```
**Full description:**
```
Muslim Vegukin — всё, что нужно мусульманам в Корее, в одном приложении.

🕌 ВРЕМЯ НАМАЗА
• Точное время намаза для вашего города, имсак и последняя треть ночи
• Напоминание о каждом намазе: звук, вибрация или без звука
• Два виджета для главного экрана: следующий намаз и оставшееся время

🧭 КИБЛА
• Направление киблы по компасу и через камеру
• Проверка компаса по солнцу и индикатор точности

📍 МЕЧЕТИ, ХАЛЯЛЬ-РЕСТОРАНЫ И МАГАЗИНЫ
• Места рядом с вами: карта, часы работы и отзывы
• Предложите новое место и следите за изменениями

🔔 УВЕДОМЛЕНИЯ
• Узнайте, когда в выбранном районе открывается новая мечеть или ресторан
• Новости мест, за которыми вы следите

🛂 ОЧЕРЕДЬ В HIKOREA
• Отслеживайте свободные дни в иммиграционных офисах и получайте уведомление, как только они появятся

🔍 ПРОВЕРКА СОСТАВА
• Отсканируйте штрихкод товара и узнайте, халяль ли он

Приложение на русском, английском и узбекском, со светлой и тёмной темой. Без рекламы.
Вход необязателен: через Telegram, WhatsApp или Google.
```

## 4. Countries

Production → Countries/regions → add **South Korea** (and, if you like, Uzbekistan, Kazakhstan, Kyrgyzstan,
Tajikistan, Russia — people keep Play accounts from home), or simply all countries.

## 5. Internal testing (minutes, for yourself)

Testing → **Internal testing** → Testers: create a list with your own Gmail → Create release:
1. Play App Signing: **accept** (Google keeps the final signing key; your `.jks` becomes the *upload* key).
2. Upload `app-release.aab`, release name e.g. `1.0.0 (1)`, release notes (uz/en/ru: "First version").
3. Save → Review → **Start rollout**. Open the "Copy link" invitation on your phone, accept, install from Play.
4. **Google sign-in:** Test and release → App integrity → App signing → copy the **SHA-1 of the app-signing key**
   and add it in Firebase (Project settings → Android app → Add fingerprint), as you did for the upload key.
   Without it, Google sign-in fails in every copy installed from Play.

## 6. Closed testing (personal accounts: 12 testers × 14 days)

Testing → **Closed testing** → create a track (e.g. "Beta"):
1. Testers: a Google Group, or an email list of at least **12** people (their Play Store Gmail addresses).
2. Create release → reuse the same `.aab` (or a newer one) → rollout.
3. Share the opt-in link; each tester must **join and install**, and stay opted in for **14 continuous days**.
4. Ask them to really use it: Google asks afterwards how testing went and what changed.

## 7. Production

Dashboard → **Apply for production** (appears after step 6) → answer the questions about the test → Production →
Create release → the `.aab` → Review → Start rollout. A staged rollout (e.g. 20%) is fine. First review: usually
1–7 days; later updates are faster.

## Each update afterwards

Raise `version` in `pubspec.yaml` (`1.0.1+2`), build the `.aab`, Production → Create release → upload → rollout.
Keep `build/symbols` of each release: Play Console → App bundle explorer → upload the symbols there turns
obfuscated crash reports readable.

## Common rejections, and how this app avoids them

| Reason | Here |
|---|---|
| No privacy policy / not reachable | step 0; also linked in the app (Account → Privacy policy) |
| No way to delete the account | in-app (Account → Delete account) and the `#delete` link |
| Data safety doesn't match the app | the table above is taken from the code |
| Login wall without instructions | App access text in step 2 |
| Exact alarms | `SCHEDULE_EXACT_ALARM` (user-granted) needs no declaration; the app doesn't use `USE_EXACT_ALARM` |
