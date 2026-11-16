# UX audit and plan (November 2026)

What was checked, what was found, what is proposed. The last section says what
was done in this update and what was left.

## How it was measured

Every screen was rendered in a test harness at 360 × 760 dp (the narrowest
common Android phone) in Uzbek, Russian and English, at text sizes 100 %,
130 % and 200 %, in light and dark: about 540 renders of 50 screens, sheets and
tabs.
For each one the harness recorded:

- layout overflows (content pushed out of its box and clipped);
- text cut with "…" or clipped;
- tap targets smaller than 48 dp (Android) and 44 pt (iOS);
- text contrast below WCAG AA (4.5 : 1);
- buttons a screen reader can't name.

Every data screen was also rendered with all servers failing, to see its error
state. Screenshots were read for hierarchy and consistency.

Not measured here: a real iPhone, real photos, real server data, animation
feel. iOS-specific points below come from reading the code.

## Verdict first

The visual design does not need redoing. Colour, spacing, cards and hierarchy
are consistent across sections, dark mode is complete, and every data screen
already has a loading, an empty and an error state with a retry. Restyling it
would cost a re-test of 50 screens for no gain a user would name.

What is wrong is narrower: the layout assumes short words at the default text
size. It breaks with Russian, with long Uzbek labels, and with the larger text
many people set on their phones.

## Findings, by impact on the user

### A. Content is lost (fix first)

| # | Where | What happens |
|---|-------|--------------|
| A1 | Cars: every listing card, on all five tabs | From 130 % text the card overflows: mileage, gearbox, fuel and "posted" are clipped off. At 200 % the price is cut ("5 500 00…"). All languages. |
| A2 | Business card | At 100 %, Uzbek: the phone number itself is cut ("010-1234-…"), and so are "Qo‘ng‘iroq qili…", "@baraka_h…", "Telegramda y…". |
| A3 | HiKorea calendar | The main button is cut at 100 %: "HiKorea’da bron …", "Записатьс…". |
| A4 | HiKorea home, your watches | The line that says how many days are free in your dates is cut at 100 %: "Sanalaringizda 8 ta bo‘sh kun …". |
| A5 | Parcel, Housing | The contact button is cut at 100 %: "Telegramda yo…", "Telegram orqali…". Parcel's destination country: "O‘zbekis…". |
| A6 | Home | At 130 % the app's name breaks mid-word ("Musli / m Ve…") and prayer names are cut ("Фад…", "Восх…", "Магр…"; Uzbek "Bomdod", "Quyosh" too). At 100 % one tile is cut: "Mahsulot tarkibini teks…". |
| A7 | Screen titles | Cut at 100 %: "Immigratsiya xizmatl…", "Иммиграционные…"; at 130 % also Notifications, Qibla, Q&A, Privacy (ru). |
| A8 | Cars | After a failed load the header keeps saying "Yuklanmoqda…" (loading) above the error. |
| A9 | Q&A answer, Links, Account, Community | Cut at 100 %: "Manbaga o‘t…", the "Koreya h…" tab, "Hozircha xabar y…", the bottom line of Community. |

### B. Things that don't respond as the platform does

| # | Where | What happens |
|---|-------|--------------|
| B1 | Cars, Housing (any tab but the first), Jobs while editing a post | **iOS:** the swipe-back gesture does nothing. The code holds the page to return to the first tab, which is Android's back-button habit; an iPhone has no back button, so the swipe is simply dead. |
| B2 | Places, Cars, Housing, Jobs, Account: 7 requests | The time limit covers only the start of the server's answer. If the connection stalls mid-answer the request never ends: the same fault that kept the HiKorea watches loading, waiting to happen elsewhere. |
| B3 | 11 bottom sheets (review, sign-in, reminder, prayer settings, business, Qibla, notifications, barcode code entry, community, widget offer) | They may grow to the full screen without keeping clear of the status bar. With large text or the keyboard up, the top of the sheet (its handle and title) can sit under the notch / Dynamic Island. |

### C. Accessibility

| # | What | Numbers |
|---|------|---------|
| C1 | Tap targets under 48 dp | About 90 found, 30 of them calendar days; about 75 are also under iOS's 44 pt. Home header's three icons (40 × 40), prayer reminder bells (46 wide), prayers settings (40), parcel save and swap (40, 46), business card copy and map buttons (30 high), notification filter chips (26 high), "Batafsil" on place cards (40 high), calendar days (40 × 40). |
| C2 | Contrast | Secondary grey text is 4.49 : 1 in light and 4.17 in dark (needs 4.5): it is on every screen. The main button in dark mode is 3.77 (white on light emerald). Single labels far below: "2 ta e’lon" 1.49, "HALOL MARKET" 2.04, "SAVOL" 2.19, HiKorea's legend 2.36, parcel "Qayerdan / Qayerga" 3.1–3.5, "Tushundim" 3.19. |
| C3 | Large text | At 200 %: 18 places overflow (3 of them already at 130 %) and most screens cut 3–30 labels. iOS's largest accessibility sizes go to 310 %, where nothing would hold. |
| C4 | Screen reader | 5 buttons without a name (car page 2, answer page 2, account 1). |

### D. Consistency (matters to whoever maintains it, barely to users)

| # | What | Numbers |
|---|------|---------|
| D1 | "Couldn't load" and "nothing here" | 12 separate widgets, 6 different looks (icon style, button width, wording) for the same two states. |
| D2 | One-off values | 36 font sizes (11.5, 12, 12.5, 13, 13.5 …), 22 corner radii, 160 colours written into screens instead of the theme; 781 text styles written inline against 9 taken from the theme. No spacing, radius or type tokens exist. |
| D3 | Headers | Two families: emerald (prayers, places, HiKorea, parcel, links, Q&A, business) and plain (cars, housing, jobs, account). Looks deliberate: landing pages against listings. Left alone. |

## Proposal, in order

**[B]** marks a change in behaviour, not only in looks: review these on their
own. **[iOS]** marks something that should be looked at on an iPhone.

1. Car cards grow with their text instead of clipping (A1). *The most content lost, on the most rows.*
2. Buttons and labels that are cut at 100 % wrap or shrink to fit (A2–A5, A9). *A phone number that can't be read is a broken feature.*
3. Home header and prayer row hold at 130 % (A6). *The first screen everyone sees.*
4. Screen titles shrink to fit instead of being cut (A7). *One shared rule, every screen.*
5. Cars: the header says what happened, not "loading" (A8).
6. **[B] [iOS]** Swipe back leaves Cars, Housing and Jobs from any tab on iPhone; Android's back button keeps returning to the first tab first (B1). *Navigation unchanged on Android.*
7. **[B]** The time limit covers the whole answer in the 7 requests (B2). *A spinner must be able to end.*
8. **[B]** Text size is capped at 160 % app-wide, and at 130 % inside tight chrome (titles, bottom bars, chips, calendar cells) (C3). *Past that the layout loses content, which is worse than slightly smaller letters. iOS's own bars do the same.*
9. Contrast: darker secondary grey, darker button green in dark mode, and the single labels (C2). *Two token changes fix every screen.*
10. Tap targets to 48 dp where the layout allows; the visible size stays (C1).
11. **[iOS]** Sheets keep clear of the status bar (B3).
12. Names for the 5 unnamed buttons (C4).
13. One shared "couldn't load / nothing here" component behind the existing ones (D1).
14. Tokens for spacing, radii and text sizes, used by the shared parts and by everything touched above (D2). *Not a rewrite of 781 styles: that changes nothing a user sees and risks every screen.*

Not proposed: new navigation, new screens, new decoration, a restyle.
