import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// One-line description under the app name on the welcome screen.
  ///
  /// In uz, this message translates to:
  /// **'Koreyadagi musulmonlar uchun'**
  String get tagline;

  /// What screen readers say for the Arabic greeting السلام عليكم.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum'**
  String get greetingLabel;

  /// Title above the language list.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi tilda davom etamiz?'**
  String get languageQuestion;

  /// Shown under THIS language's own tile, always in this language, so a speaker knows what they get before choosing. Uzbek has every section; the others say which sections are Uzbek-only.
  ///
  /// In uz, this message translates to:
  /// **'Barcha bo‘limlar mavjud'**
  String get languageNote;

  /// Confirms the language on first launch.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueAction;

  /// Confirms the language when changing it later.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get saveAction;

  /// Reassurance under the first-launch button.
  ///
  /// In uz, this message translates to:
  /// **'Tilni keyinroq sozlamalardan o‘zgartirish mumkin'**
  String get changeLaterHint;

  /// Opens the language picker from inside the app.
  ///
  /// In uz, this message translates to:
  /// **'Tilni o‘zgartirish'**
  String get changeLanguage;

  /// Short prayer name, fits a sixth of the screen width.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod'**
  String get prayerFajr;

  /// Sunrise: the end of Fajr, not a prayer. Short form.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In uz, this message translates to:
  /// **'Peshin'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In uz, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In uz, this message translates to:
  /// **'Shom'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In uz, this message translates to:
  /// **'Xufton'**
  String get prayerIsha;

  /// Label above the countdown to the next prayer.
  ///
  /// In uz, this message translates to:
  /// **'Bomdodgacha'**
  String get untilFajr;

  /// Countdown label between Fajr and sunrise: time left for Fajr.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod tugashiga'**
  String get untilFajrEnds;

  /// No description provided for @untilDhuhr.
  ///
  /// In uz, this message translates to:
  /// **'Peshingacha'**
  String get untilDhuhr;

  /// No description provided for @untilAsr.
  ///
  /// In uz, this message translates to:
  /// **'Asrgacha'**
  String get untilAsr;

  /// No description provided for @untilMaghrib.
  ///
  /// In uz, this message translates to:
  /// **'Shomgacha'**
  String get untilMaghrib;

  /// No description provided for @untilIsha.
  ///
  /// In uz, this message translates to:
  /// **'Xuftongacha'**
  String get untilIsha;

  /// Shown instead of a city name before the first location fix.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv'**
  String get locationPlaceholder;

  /// No description provided for @locating.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlanmoqda…'**
  String get locating;

  /// How old the saved location is: under a minute.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgina'**
  String get locationJustNow;

  /// No description provided for @locationMinutesAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} daqiqa oldin'**
  String locationMinutesAgo(int count);

  /// No description provided for @locationHoursAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} soat oldin'**
  String locationHoursAgo(int count);

  /// No description provided for @locationDaysAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} kun oldin'**
  String locationDaysAgo(int count);

  /// No description provided for @locationFailedShort.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlab bo‘lmadi'**
  String get locationFailedShort;

  /// Screen-reader label of the city chip.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni yangilash'**
  String get refreshLocation;

  /// No description provided for @locationNeededTitle.
  ///
  /// In uz, this message translates to:
  /// **'Namoz vaqtlari uchun joylashuv kerak'**
  String get locationNeededTitle;

  /// No description provided for @locationNeededBody.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtlar shahringiz bo‘yicha hisoblanadi. Joylashuv faqat shu uchun ishlatiladi.'**
  String get locationNeededBody;

  /// No description provided for @useMyLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni aniqlash'**
  String get useMyLocation;

  /// No description provided for @locationDeniedBody.
  ///
  /// In uz, this message translates to:
  /// **'Ilovaga joylashuvga ruxsat berilmagan. Uni ilova sozlamalarida yoqing.'**
  String get locationDeniedBody;

  /// No description provided for @openSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalarni ochish'**
  String get openSettings;

  /// No description provided for @locationOffBody.
  ///
  /// In uz, this message translates to:
  /// **'Telefonda joylashuv (GPS) o‘chirilgan.'**
  String get locationOffBody;

  /// No description provided for @turnOnLocation.
  ///
  /// In uz, this message translates to:
  /// **'Yoqish'**
  String get turnOnLocation;

  /// No description provided for @locationFailedBody.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni aniqlab bo‘lmadi.'**
  String get locationFailedBody;

  /// No description provided for @timesFailedBody.
  ///
  /// In uz, this message translates to:
  /// **'Namoz vaqtlarini yuklab bo‘lmadi. Internetni tekshiring.'**
  String get timesFailedBody;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// Small tag on new sections. Keep it one short word.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get newBadge;

  /// Screen-reader text of the UZ tag on Uzbek-only sections.
  ///
  /// In uz, this message translates to:
  /// **'Faqat o‘zbek tilida'**
  String get uzOnlyHint;

  /// No description provided for @featurePrayers.
  ///
  /// In uz, this message translates to:
  /// **'Namoz vaqtlari'**
  String get featurePrayers;

  /// No description provided for @featureMosques.
  ///
  /// In uz, this message translates to:
  /// **'Masjidlar'**
  String get featureMosques;

  /// No description provided for @featureRestaurants.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonalar'**
  String get featureRestaurants;

  /// No description provided for @featureShops.
  ///
  /// In uz, this message translates to:
  /// **'Do‘konlar'**
  String get featureShops;

  /// No description provided for @featureNotifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get featureNotifications;

  /// No description provided for @featureQibla.
  ///
  /// In uz, this message translates to:
  /// **'Qibla'**
  String get featureQibla;

  /// No description provided for @featureQna.
  ///
  /// In uz, this message translates to:
  /// **'Zikr ahlidan so‘rang'**
  String get featureQna;

  /// No description provided for @featureBarcode.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot tarkibini tekshirish'**
  String get featureBarcode;

  /// No description provided for @featureHousing.
  ///
  /// In uz, this message translates to:
  /// **'Uy-joy e’lonlari'**
  String get featureHousing;

  /// No description provided for @featureCars.
  ///
  /// In uz, this message translates to:
  /// **'Vegukin Cars'**
  String get featureCars;

  /// No description provided for @featureHikorea.
  ///
  /// In uz, this message translates to:
  /// **'Immigratsiya xizmatlari'**
  String get featureHikorea;

  /// No description provided for @featureJobs.
  ///
  /// In uz, this message translates to:
  /// **'Ish e’lonlari'**
  String get featureJobs;

  /// No description provided for @featureParcel.
  ///
  /// In uz, this message translates to:
  /// **'Pochta'**
  String get featureParcel;

  /// No description provided for @featureLinks.
  ///
  /// In uz, this message translates to:
  /// **'Foydali linklar'**
  String get featureLinks;

  /// No description provided for @featureDonation.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘llab-quvvatlash'**
  String get featureDonation;

  /// No description provided for @featureCommunity.
  ///
  /// In uz, this message translates to:
  /// **'Jamoa'**
  String get featureCommunity;

  /// No description provided for @featureBusiness.
  ///
  /// In uz, this message translates to:
  /// **'Biznes Katalogi'**
  String get featureBusiness;

  /// Under the business directory title until the live count loads.
  ///
  /// In uz, this message translates to:
  /// **'Koreyadagi o‘zbek bizneslari'**
  String get businessTagline;

  /// No description provided for @businessCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta biznes'**
  String businessCount(int count);

  /// No description provided for @categoryCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta yo‘nalish'**
  String categoryCount(int count);

  /// No description provided for @webLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Sahifani ochib bo‘lmadi. Internetni tekshiring.'**
  String get webLoadFailed;

  /// No description provided for @webReload.
  ///
  /// In uz, this message translates to:
  /// **'Yangilash'**
  String get webReload;

  /// No description provided for @webOpenInBrowser.
  ///
  /// In uz, this message translates to:
  /// **'Brauzerda ochish'**
  String get webOpenInBrowser;

  /// Shown when a page needs the camera and the user did not allow it at first launch; the action opens the app settings.
  ///
  /// In uz, this message translates to:
  /// **'Kameraga ruxsat berilmagan'**
  String get cameraDenied;

  /// Home-screen widget, before the app has a location and prayer times.
  ///
  /// In uz, this message translates to:
  /// **'Namoz vaqtlari uchun ilovani oching'**
  String get widgetOpenApp;

  /// No description provided for @exactAlarmsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Aniq vaqt uchun ruxsat'**
  String get exactAlarmsTitle;

  /// Asked once at first launch, after location and camera, when Android 14+ keeps the exact-alarm permission off.
  ///
  /// In uz, this message translates to:
  /// **'Namoz eslatmalari va bosh ekrandagi vidjet aynan o‘z vaqtida ishlashi uchun keyingi sahifada «Signal va eslatmalar»ni yoqing.'**
  String get exactAlarmsBody;

  /// No description provided for @exactAlarmsAllow.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get exactAlarmsAllow;

  /// No description provided for @exactAlarmsLater.
  ///
  /// In uz, this message translates to:
  /// **'Keyinroq'**
  String get exactAlarmsLater;

  /// No description provided for @prayersTitle.
  ///
  /// In uz, this message translates to:
  /// **'Namoz vaqtlari'**
  String get prayersTitle;

  /// No description provided for @nextPrayer.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi namoz'**
  String get nextPrayer;

  /// No description provided for @remaining.
  ///
  /// In uz, this message translates to:
  /// **'qoldi'**
  String get remaining;

  /// No description provided for @suhoorLabel.
  ///
  /// In uz, this message translates to:
  /// **'Saharlik (oxiri)'**
  String get suhoorLabel;

  /// No description provided for @iftarLabel.
  ///
  /// In uz, this message translates to:
  /// **'Iftorlik'**
  String get iftarLabel;

  /// No description provided for @chipNow.
  ///
  /// In uz, this message translates to:
  /// **'hozir'**
  String get chipNow;

  /// No description provided for @chipNext.
  ///
  /// In uz, this message translates to:
  /// **'keyingi'**
  String get chipNext;

  /// No description provided for @fastWindow.
  ///
  /// In uz, this message translates to:
  /// **'Ro‘za vaqti · Saharlikdan Iftorlikkacha'**
  String get fastWindow;

  /// No description provided for @dayToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In uz, this message translates to:
  /// **'Ertaga'**
  String get dayTomorrow;

  /// No description provided for @dayYesterday.
  ///
  /// In uz, this message translates to:
  /// **'Kecha'**
  String get dayYesterday;

  /// No description provided for @previousDay.
  ///
  /// In uz, this message translates to:
  /// **'Oldingi kun'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi kun'**
  String get nextDay;

  /// No description provided for @backToToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugunga qaytish'**
  String get backToToday;

  /// No description provided for @dayLoading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda...'**
  String get dayLoading;

  /// No description provided for @dayLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab bo‘lmadi'**
  String get dayLoadFailed;

  /// No description provided for @commentFajr.
  ///
  /// In uz, this message translates to:
  /// **'Xufton vaqti tugaydi'**
  String get commentFajr;

  /// No description provided for @commentSunrise.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod vaqti tugaydi'**
  String get commentSunrise;

  /// No description provided for @commentAsr.
  ///
  /// In uz, this message translates to:
  /// **'Peshin vaqti tugaydi'**
  String get commentAsr;

  /// No description provided for @commentMaghrib.
  ///
  /// In uz, this message translates to:
  /// **'Asr vaqti tugaydi'**
  String get commentMaghrib;

  /// No description provided for @commentIsha.
  ///
  /// In uz, this message translates to:
  /// **'Shom vaqti tugaydi'**
  String get commentIsha;

  /// No description provided for @settingsShort.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsShort;

  /// No description provided for @settingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Namoz sozlamalari'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisoblash usuli va mazhabingizni tanlang'**
  String get settingsSubtitle;

  /// No description provided for @methodLabel.
  ///
  /// In uz, this message translates to:
  /// **'Hisoblash usuli'**
  String get methodLabel;

  /// No description provided for @madhabLabel.
  ///
  /// In uz, this message translates to:
  /// **'Mazhab (Asr vaqti uchun)'**
  String get madhabLabel;

  /// No description provided for @schoolHanafi.
  ///
  /// In uz, this message translates to:
  /// **'Hanafiy'**
  String get schoolHanafi;

  /// No description provided for @schoolShafii.
  ///
  /// In uz, this message translates to:
  /// **'Shofe’iy / Molikiy / Hanbaliy'**
  String get schoolShafii;

  /// No description provided for @schoolShafiiShort.
  ///
  /// In uz, this message translates to:
  /// **'Shofe’iy'**
  String get schoolShafiiShort;

  /// No description provided for @hanafiNote.
  ///
  /// In uz, this message translates to:
  /// **'Soya = 2x uzunlik'**
  String get hanafiNote;

  /// No description provided for @shafiiNote.
  ///
  /// In uz, this message translates to:
  /// **'Soya = 1x uzunlik'**
  String get shafiiNote;

  /// No description provided for @methodMwl.
  ///
  /// In uz, this message translates to:
  /// **'Muslim World League'**
  String get methodMwl;

  /// No description provided for @methodKarachi.
  ///
  /// In uz, this message translates to:
  /// **'Karachi'**
  String get methodKarachi;

  /// No description provided for @methodMakkah.
  ///
  /// In uz, this message translates to:
  /// **'Makka'**
  String get methodMakkah;

  /// No description provided for @methodEgypt.
  ///
  /// In uz, this message translates to:
  /// **'Misr'**
  String get methodEgypt;

  /// No description provided for @methodIsna.
  ///
  /// In uz, this message translates to:
  /// **'ISNA'**
  String get methodIsna;

  /// No description provided for @methodMwlHint.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod 18°, Xufton 17°'**
  String get methodMwlHint;

  /// No description provided for @methodKarachiHint.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod 18°, Xufton 18°'**
  String get methodKarachiHint;

  /// No description provided for @methodMakkahHint.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod 18.5°, Xufton - Shomdan 90 daqiqa keyin'**
  String get methodMakkahHint;

  /// No description provided for @methodEgyptHint.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod 19.5°, Xufton 17.5°'**
  String get methodEgyptHint;

  /// No description provided for @methodIsnaHint.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod 15°, Xufton 15°'**
  String get methodIsnaHint;

  /// No description provided for @naflTitle.
  ///
  /// In uz, this message translates to:
  /// **'Nafl namoz vaqtlari'**
  String get naflTitle;

  /// No description provided for @tahajjudName.
  ///
  /// In uz, this message translates to:
  /// **'Tahajjud namozi'**
  String get tahajjudName;

  /// No description provided for @tahajjudText.
  ///
  /// In uz, this message translates to:
  /// **'Xuftondan keyin, uyqudan so‘ng o‘qiladigan nafl namoz. Ozi 2 rakat, ko‘pi 8 rakat. Eng afzal vaqti - kechaning oxirgi uchdan biri. Duolar qabul bo‘ladigan vaqt.'**
  String get tahajjudText;

  /// No description provided for @tahajjudQuote.
  ///
  /// In uz, this message translates to:
  /// **'U Robbingizga qurbatdir, yomonliklarga kafforotdir, gunohlarni qaytaruvchidir.'**
  String get tahajjudQuote;

  /// No description provided for @tahajjudSource.
  ///
  /// In uz, this message translates to:
  /// **'Manba: Termiziy - Abu Umoma (r.a.)'**
  String get tahajjudSource;

  /// No description provided for @ishraqName.
  ///
  /// In uz, this message translates to:
  /// **'Shuruq (Ishroq) namozi'**
  String get ishraqName;

  /// No description provided for @ishraqQuote.
  ///
  /// In uz, this message translates to:
  /// **'Kim bomdodni jamoat bilan o‘qisa, so‘ngra quyosh chiqquncha Allohni zikr qilib o‘tirsa, keyin ikki rakat namoz o‘qisa, uning uchun haj va umraning ajridek bo‘lur.'**
  String get ishraqQuote;

  /// No description provided for @ishraqSource.
  ///
  /// In uz, this message translates to:
  /// **'Manba: Termiziy - Muoz ibn Anas al-Juhaniy (r.a.)'**
  String get ishraqSource;

  /// No description provided for @duhaName.
  ///
  /// In uz, this message translates to:
  /// **'Zuho (Choshgoh) namozi'**
  String get duhaName;

  /// No description provided for @duhaText.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh bir nayza bo‘yi ko‘tarilganda kirib, zavolga bir soat qolguncha davom etadi. Afzali 4 rakat o‘qish. Eng afzal vaqti - nahorning to‘rtdan biri o‘tgandan keyin.'**
  String get duhaText;

  /// No description provided for @duhaQuote.
  ///
  /// In uz, this message translates to:
  /// **'Kim choshgoh namozini bardavom o‘qisa, uning gunohlari dengiz ko‘pigicha bo‘lsa ham mag‘firat qilinadi.'**
  String get duhaQuote;

  /// No description provided for @duhaSource.
  ///
  /// In uz, this message translates to:
  /// **'Manba: Termiziy - Abu Hurayra (r.a.)'**
  String get duhaSource;

  /// No description provided for @statusNow.
  ///
  /// In uz, this message translates to:
  /// **'Ayni vaqti'**
  String get statusNow;

  /// No description provided for @statusUpcoming.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get statusUpcoming;

  /// No description provided for @statusPassed.
  ///
  /// In uz, this message translates to:
  /// **'Vaqti o‘tdi'**
  String get statusPassed;

  /// No description provided for @statusOtherDay.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa kun'**
  String get statusOtherDay;

  /// No description provided for @reminderHint.
  ///
  /// In uz, this message translates to:
  /// **'Har bir namoz uchun eslatmani qo‘ng‘iroqcha orqali sozlang'**
  String get reminderHint;

  /// No description provided for @reminderFor.
  ///
  /// In uz, this message translates to:
  /// **'{name}: eslatma'**
  String reminderFor(String name);

  /// No description provided for @reminderToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugun: {range}'**
  String reminderToday(String range);

  /// No description provided for @reminderHow.
  ///
  /// In uz, this message translates to:
  /// **'Qanday eslatilsin'**
  String get reminderHow;

  /// No description provided for @reminderWhen.
  ///
  /// In uz, this message translates to:
  /// **'Qachon'**
  String get reminderWhen;

  /// No description provided for @reminderOff.
  ///
  /// In uz, this message translates to:
  /// **'O‘chiq'**
  String get reminderOff;

  /// No description provided for @reminderOffHint.
  ///
  /// In uz, this message translates to:
  /// **'Eslatmasin'**
  String get reminderOffHint;

  /// No description provided for @reminderSilent.
  ///
  /// In uz, this message translates to:
  /// **'Jim'**
  String get reminderSilent;

  /// No description provided for @reminderSilentHint.
  ///
  /// In uz, this message translates to:
  /// **'Faqat bildirishnoma'**
  String get reminderSilentHint;

  /// No description provided for @reminderVibrate.
  ///
  /// In uz, this message translates to:
  /// **'Tebranish'**
  String get reminderVibrate;

  /// No description provided for @reminderVibrateHint.
  ///
  /// In uz, this message translates to:
  /// **'Ovozsiz, tebranadi'**
  String get reminderVibrateHint;

  /// No description provided for @reminderSound.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz'**
  String get reminderSound;

  /// No description provided for @reminderSoundHint.
  ///
  /// In uz, this message translates to:
  /// **'Qisqa, yoqimli ohang'**
  String get reminderSoundHint;

  /// No description provided for @reminderPlay.
  ///
  /// In uz, this message translates to:
  /// **'Eshitib ko‘rish'**
  String get reminderPlay;

  /// No description provided for @reminderAt.
  ///
  /// In uz, this message translates to:
  /// **'Eslatma vaqti'**
  String get reminderAt;

  /// No description provided for @reminderDone.
  ///
  /// In uz, this message translates to:
  /// **'Tayyor'**
  String get reminderDone;

  /// No description provided for @offsetOnTime.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtida'**
  String get offsetOnTime;

  /// No description provided for @offsetBefore.
  ///
  /// In uz, this message translates to:
  /// **'{duration} oldin'**
  String offsetBefore(String duration);

  /// No description provided for @offsetAfter.
  ///
  /// In uz, this message translates to:
  /// **'{duration} keyin'**
  String offsetAfter(String duration);

  /// No description provided for @durationMinutes.
  ///
  /// In uz, this message translates to:
  /// **'{minutes} daq'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In uz, this message translates to:
  /// **'{hours} soat'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In uz, this message translates to:
  /// **'{hours} soat {minutes} daq'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @notificationsOff.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar o‘chiq — eslatmalar kelmaydi'**
  String get notificationsOff;

  /// No description provided for @notificationsTurnOn.
  ///
  /// In uz, this message translates to:
  /// **'Yoqish'**
  String get notificationsTurnOn;

  /// No description provided for @notifyAt.
  ///
  /// In uz, this message translates to:
  /// **'{name} vaqti kirdi'**
  String notifyAt(String name);

  /// No description provided for @notifyBefore.
  ///
  /// In uz, this message translates to:
  /// **'{name} vaqtiga {duration} qoldi'**
  String notifyBefore(String name, String duration);

  /// No description provided for @notifyAfter.
  ///
  /// In uz, this message translates to:
  /// **'{name} vaqti kirganiga {duration} bo‘ldi'**
  String notifyAfter(String name, String duration);

  /// No description provided for @notifySunriseAt.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh chiqdi — Bomdod vaqti tugadi'**
  String get notifySunriseAt;

  /// No description provided for @notifySunriseBefore.
  ///
  /// In uz, this message translates to:
  /// **'Bomdod vaqti tugashiga {duration} qoldi'**
  String notifySunriseBefore(String duration);

  /// No description provided for @notifySunriseAfter.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh chiqqaniga {duration} bo‘ldi'**
  String notifySunriseAfter(String duration);

  /// No description provided for @notifyImsakAt.
  ///
  /// In uz, this message translates to:
  /// **'Saharlik vaqti tugadi'**
  String get notifyImsakAt;

  /// No description provided for @notifyImsakBefore.
  ///
  /// In uz, this message translates to:
  /// **'Saharlik tugashiga {duration} qoldi'**
  String notifyImsakBefore(String duration);

  /// No description provided for @notifyImsakAfter.
  ///
  /// In uz, this message translates to:
  /// **'Saharlik tugaganiga {duration} bo‘ldi'**
  String notifyImsakAfter(String duration);

  /// No description provided for @notifyBody.
  ///
  /// In uz, this message translates to:
  /// **'{name}: {start} – {end} · {city}'**
  String notifyBody(String name, String start, String end, String city);

  /// No description provided for @suhoorShort.
  ///
  /// In uz, this message translates to:
  /// **'Saharlik'**
  String get suhoorShort;

  /// No description provided for @qiblaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qibla yo‘nalishi'**
  String get qiblaTitle;

  /// No description provided for @qiblaPreparing.
  ///
  /// In uz, this message translates to:
  /// **'Kompas tayyorlanmoqda...'**
  String get qiblaPreparing;

  /// No description provided for @qiblaHoldFlat.
  ///
  /// In uz, this message translates to:
  /// **'Qurilmangizni tekis ushlang'**
  String get qiblaHoldFlat;

  /// No description provided for @qiblaHoldFlatShort.
  ///
  /// In uz, this message translates to:
  /// **'Telefonni tekis ushlang'**
  String get qiblaHoldFlatShort;

  /// No description provided for @qiblaNoLocation.
  ///
  /// In uz, this message translates to:
  /// **'Qibla yo‘nalishini hisoblash uchun joylashuvingiz kerak.'**
  String get qiblaNoLocation;

  /// No description provided for @qiblaNoCompassTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kompas topilmadi'**
  String get qiblaNoCompassTitle;

  /// No description provided for @qiblaNoCompass.
  ///
  /// In uz, this message translates to:
  /// **'Bu qurilmada kompas sensori mavjud emas.'**
  String get qiblaNoCompass;

  /// No description provided for @qiblaNorth.
  ///
  /// In uz, this message translates to:
  /// **'Shimol'**
  String get qiblaNorth;

  /// No description provided for @qiblaEast.
  ///
  /// In uz, this message translates to:
  /// **'Sharq'**
  String get qiblaEast;

  /// No description provided for @qiblaSouth.
  ///
  /// In uz, this message translates to:
  /// **'Janub'**
  String get qiblaSouth;

  /// No description provided for @qiblaWest.
  ///
  /// In uz, this message translates to:
  /// **'G‘arb'**
  String get qiblaWest;

  /// No description provided for @qiblaDirection.
  ///
  /// In uz, this message translates to:
  /// **'Yo‘nalish'**
  String get qiblaDirection;

  /// No description provided for @qiblaAngle.
  ///
  /// In uz, this message translates to:
  /// **'Qibla burchagi'**
  String get qiblaAngle;

  /// No description provided for @qiblaLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv'**
  String get qiblaLocation;

  /// No description provided for @qiblaToMakkah.
  ///
  /// In uz, this message translates to:
  /// **'Makkagacha'**
  String get qiblaToMakkah;

  /// No description provided for @qiblaSignal.
  ///
  /// In uz, this message translates to:
  /// **'Kompas signali'**
  String get qiblaSignal;

  /// No description provided for @qiblaQualityExcellent.
  ///
  /// In uz, this message translates to:
  /// **'A’lo'**
  String get qiblaQualityExcellent;

  /// No description provided for @qiblaQualityGood.
  ///
  /// In uz, this message translates to:
  /// **'Yaxshi'**
  String get qiblaQualityGood;

  /// No description provided for @qiblaQualityMedium.
  ///
  /// In uz, this message translates to:
  /// **'O‘rtacha'**
  String get qiblaQualityMedium;

  /// No description provided for @qiblaQualityPoor.
  ///
  /// In uz, this message translates to:
  /// **'Yomon'**
  String get qiblaQualityPoor;

  /// No description provided for @qiblaNeedsCalibration.
  ///
  /// In uz, this message translates to:
  /// **'Kalibratsiya kerak'**
  String get qiblaNeedsCalibration;

  /// No description provided for @qiblaInterference.
  ///
  /// In uz, this message translates to:
  /// **'Yaqinda metall yoki elektronika bor'**
  String get qiblaInterference;

  /// No description provided for @qiblaAccuracy.
  ///
  /// In uz, this message translates to:
  /// **'±{degrees}°'**
  String qiblaAccuracy(int degrees);

  /// No description provided for @qiblaDeclination.
  ///
  /// In uz, this message translates to:
  /// **'Magnit og‘ishi {degrees}° hisobga olingan'**
  String qiblaDeclination(String degrees);

  /// No description provided for @qiblaTipsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Aniqroq natija uchun'**
  String get qiblaTipsTitle;

  /// No description provided for @qiblaTip1.
  ///
  /// In uz, this message translates to:
  /// **'Telefonni gorizontal (tekis) ushlang'**
  String get qiblaTip1;

  /// No description provided for @qiblaTip2.
  ///
  /// In uz, this message translates to:
  /// **'Metall buyumlardan uzoqroq turing'**
  String get qiblaTip2;

  /// No description provided for @qiblaTip3.
  ///
  /// In uz, this message translates to:
  /// **'Elektron qurilmalardan uzoqlashing'**
  String get qiblaTip3;

  /// No description provided for @qiblaTip4.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq maydonlarda ishlating'**
  String get qiblaTip4;

  /// No description provided for @qiblaTip5.
  ///
  /// In uz, this message translates to:
  /// **'Kamera rejimida telefonni tik ushlang va Ka’ba belgisini markazga keltiring'**
  String get qiblaTip5;

  /// No description provided for @qiblaAligned.
  ///
  /// In uz, this message translates to:
  /// **'Qiblaga to‘g‘ri yuzlangansiz!'**
  String get qiblaAligned;

  /// No description provided for @qiblaSlightlyRight.
  ///
  /// In uz, this message translates to:
  /// **'Biroz o‘ngga buriling'**
  String get qiblaSlightlyRight;

  /// No description provided for @qiblaSlightlyLeft.
  ///
  /// In uz, this message translates to:
  /// **'Biroz chapga buriling'**
  String get qiblaSlightlyLeft;

  /// No description provided for @qiblaTurnRight.
  ///
  /// In uz, this message translates to:
  /// **'O‘ngga buriling'**
  String get qiblaTurnRight;

  /// No description provided for @qiblaTurnLeft.
  ///
  /// In uz, this message translates to:
  /// **'Chapga buriling'**
  String get qiblaTurnLeft;

  /// No description provided for @qiblaModeCompass.
  ///
  /// In uz, this message translates to:
  /// **'Kompas'**
  String get qiblaModeCompass;

  /// No description provided for @qiblaModeCamera.
  ///
  /// In uz, this message translates to:
  /// **'Kamera'**
  String get qiblaModeCamera;

  /// No description provided for @qiblaHoldUpright.
  ///
  /// In uz, this message translates to:
  /// **'Telefonni tik ushlang'**
  String get qiblaHoldUpright;

  /// No description provided for @qiblaCameraFailed.
  ///
  /// In uz, this message translates to:
  /// **'Kamerani ochib bo‘lmadi'**
  String get qiblaCameraFailed;

  /// No description provided for @qiblaSunTitle.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh bo‘yicha tekshirish'**
  String get qiblaSunTitle;

  /// No description provided for @qiblaSunRight.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh hozir {sun}° da. Quyoshga yuzlanib, {angle}° o‘ngga burilsangiz — Qibla.'**
  String qiblaSunRight(int sun, int angle);

  /// No description provided for @qiblaSunLeft.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh hozir {sun}° da. Quyoshga yuzlanib, {angle}° chapga burilsangiz — Qibla.'**
  String qiblaSunLeft(int sun, int angle);

  /// No description provided for @qiblaSunAhead.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh hozir {sun}° da — aynan Qibla tomonda.'**
  String qiblaSunAhead(int sun);

  /// No description provided for @qiblaSunDown.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh ufqdan pastda. Kunduzi Qiblani quyosh bo‘yicha ham tekshirish mumkin — magnitlar unga ta’sir qilmaydi.'**
  String get qiblaSunDown;

  /// No description provided for @qiblaSunOverKaaba.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh Ka’ba ustida bo‘ladi: {when}. O‘sha daqiqada soyalar Qibladan teskari tomonga tushadi.'**
  String qiblaSunOverKaaba(String when);

  /// No description provided for @qiblaPhaseMove.
  ///
  /// In uz, this message translates to:
  /// **'Harakat'**
  String get qiblaPhaseMove;

  /// No description provided for @qiblaPhaseHold.
  ///
  /// In uz, this message translates to:
  /// **'Barqarorlik'**
  String get qiblaPhaseHold;

  /// No description provided for @qiblaCalibrateTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kompasni kalibratsiya qiling'**
  String get qiblaCalibrateTitle;

  /// No description provided for @qiblaCalibrateMove.
  ///
  /// In uz, this message translates to:
  /// **'Telefonni bilakni burab ∞ shaklida aylantiring — faqat surmang.'**
  String get qiblaCalibrateMove;

  /// No description provided for @qiblaCalibrateHold.
  ///
  /// In uz, this message translates to:
  /// **'Pufakchani markazda ushlab, qimirlamay turing.'**
  String get qiblaCalibrateHold;

  /// No description provided for @qiblaMovements.
  ///
  /// In uz, this message translates to:
  /// **'{count}/{total} harakat'**
  String qiblaMovements(int count, int total);

  /// No description provided for @qiblaCalMoving.
  ///
  /// In uz, this message translates to:
  /// **'Telefonni ∞ shaklida harakatlantiring...'**
  String get qiblaCalMoving;

  /// No description provided for @qiblaCalGood.
  ///
  /// In uz, this message translates to:
  /// **'Yaxshi! Davom eting...'**
  String get qiblaCalGood;

  /// No description provided for @qiblaCalHoldStill.
  ///
  /// In uz, this message translates to:
  /// **'Endi telefonni tekis ushlab, qimirlatmang...'**
  String get qiblaCalHoldStill;

  /// No description provided for @qiblaCalChecking.
  ///
  /// In uz, this message translates to:
  /// **'Barqarorlik tekshirilmoqda...'**
  String get qiblaCalChecking;

  /// No description provided for @qiblaCalDone.
  ///
  /// In uz, this message translates to:
  /// **'✓ Kalibratsiya tayyor!'**
  String get qiblaCalDone;

  /// No description provided for @qiblaCalibrateShort.
  ///
  /// In uz, this message translates to:
  /// **'Kalibrlash'**
  String get qiblaCalibrateShort;

  /// No description provided for @qiblaSkip.
  ///
  /// In uz, this message translates to:
  /// **'O‘tkazib yuborish'**
  String get qiblaSkip;

  /// No description provided for @qiblaUndo.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get qiblaUndo;

  /// No description provided for @qiblaSunMarker.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh'**
  String get qiblaSunMarker;

  /// No description provided for @qiblaSunTapHint.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh doirada emasmi? Haqiqiy quyoshga bosing'**
  String get qiblaSunTapHint;

  /// No description provided for @qiblaSunNotThere.
  ///
  /// In uz, this message translates to:
  /// **'Quyoshning o‘ziga bosing: u punktir chiziqda turadi'**
  String get qiblaSunNotThere;

  /// No description provided for @qiblaSunCorrected.
  ///
  /// In uz, this message translates to:
  /// **'Quyosh bo‘yicha tuzatildi: {degrees}°'**
  String qiblaSunCorrected(String degrees);

  /// No description provided for @qiblaSunCheckCamera.
  ///
  /// In uz, this message translates to:
  /// **'Kamerada tekshirish'**
  String get qiblaSunCheckCamera;

  /// No description provided for @parcelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Pochta yuborish'**
  String get parcelTitle;

  /// No description provided for @parcelTagline.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer topib, pochtangizni yetkazing'**
  String get parcelTagline;

  /// No description provided for @parcelFrom.
  ///
  /// In uz, this message translates to:
  /// **'Qayerdan'**
  String get parcelFrom;

  /// No description provided for @parcelTo.
  ///
  /// In uz, this message translates to:
  /// **'Qayerga'**
  String get parcelTo;

  /// No description provided for @parcelSwap.
  ///
  /// In uz, this message translates to:
  /// **'Yo‘nalishni almashtirish'**
  String get parcelSwap;

  /// No description provided for @parcelUzbekistan.
  ///
  /// In uz, this message translates to:
  /// **'O‘zbekiston'**
  String get parcelUzbekistan;

  /// No description provided for @parcelKorea.
  ///
  /// In uz, this message translates to:
  /// **'Koreya'**
  String get parcelKorea;

  /// No description provided for @parcelUzbToKor.
  ///
  /// In uz, this message translates to:
  /// **'O‘zbekistondan Koreyaga'**
  String get parcelUzbToKor;

  /// No description provided for @parcelKorToUzb.
  ///
  /// In uz, this message translates to:
  /// **'Koreyadan O‘zbekistonga'**
  String get parcelKorToUzb;

  /// No description provided for @parcelByDate.
  ///
  /// In uz, this message translates to:
  /// **'Sana bo‘yicha'**
  String get parcelByDate;

  /// No description provided for @parcelByCity.
  ///
  /// In uz, this message translates to:
  /// **'Shahar bo‘yicha'**
  String get parcelByCity;

  /// No description provided for @parcelPostCount.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta e’lon}}'**
  String parcelPostCount(int count);

  /// No description provided for @parcelNoDates.
  ///
  /// In uz, this message translates to:
  /// **'Bu yo‘nalishda hozircha e’lonlar yo‘q'**
  String get parcelNoDates;

  /// No description provided for @parcelNoPosts.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlar topilmadi'**
  String get parcelNoPosts;

  /// No description provided for @parcelNoCities.
  ///
  /// In uz, this message translates to:
  /// **'Shaharlar topilmadi'**
  String get parcelNoCities;

  /// No description provided for @parcelSeeOther.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa yo‘nalish: {route}'**
  String parcelSeeOther(String route);

  /// No description provided for @parcelError.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotni yuklab bo‘lmadi. Internetni tekshirib, qaytadan urinib ko‘ring.'**
  String get parcelError;

  /// No description provided for @parcelHowTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qanday ishlaydi?'**
  String get parcelHowTitle;

  /// No description provided for @parcelHow1.
  ///
  /// In uz, this message translates to:
  /// **'Yo‘nalish va qidiruv usulini tanlang'**
  String get parcelHow1;

  /// No description provided for @parcelHow2.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni ko‘rib chiqing va kuryer bilan bog‘laning'**
  String get parcelHow2;

  /// No description provided for @parcelHow3.
  ///
  /// In uz, this message translates to:
  /// **'Pochtangizni xavfsiz yetkazing!'**
  String get parcelHow3;

  /// No description provided for @parcelWriteTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegramda yozish'**
  String get parcelWriteTelegram;

  /// No description provided for @parcelCall.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘ng‘iroq qilish'**
  String get parcelCall;

  /// No description provided for @parcelCopy.
  ///
  /// In uz, this message translates to:
  /// **'Nusxa olish'**
  String get parcelCopy;

  /// No description provided for @parcelCopied.
  ///
  /// In uz, this message translates to:
  /// **'Nusxa olindi'**
  String get parcelCopied;

  /// No description provided for @parcelContactInText.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer kontakti xabarda ko‘rsatilgan'**
  String get parcelContactInText;

  /// No description provided for @parcelShowMore.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘proq'**
  String get parcelShowMore;

  /// No description provided for @parcelShowLess.
  ///
  /// In uz, this message translates to:
  /// **'Yig‘ish'**
  String get parcelShowLess;

  /// No description provided for @parcelSearchCity.
  ///
  /// In uz, this message translates to:
  /// **'Shaharni qidirish'**
  String get parcelSearchCity;

  /// No description provided for @themeToDay.
  ///
  /// In uz, this message translates to:
  /// **'Kunduzgi rejim'**
  String get themeToDay;

  /// No description provided for @themeToNight.
  ///
  /// In uz, this message translates to:
  /// **'Tungi rejim'**
  String get themeToNight;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
