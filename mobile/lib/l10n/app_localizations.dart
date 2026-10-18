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

  /// No description provided for @parcelNoticeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ehtiyot bo‘ling'**
  String get parcelNoticeTitle;

  /// No description provided for @parcelNotice.
  ///
  /// In uz, this message translates to:
  /// **'Bu e’lonlar Telegram guruhlaridan olinadi. Biz kuryerlar bilan bog‘liq emasmiz — faqat ularning e’lonlarini ko‘rsatamiz. Orada firibgarlar ham bo‘lishi mumkin. Yuzaga kelgan har qanday zarar uchun javobgar emasmiz.'**
  String get parcelNotice;

  /// No description provided for @parcelNoticeShort.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlar Telegram guruhlaridan. Biz kuryerlar bilan bog‘liq emasmiz.'**
  String get parcelNoticeShort;

  /// No description provided for @parcelNoticeOk.
  ///
  /// In uz, this message translates to:
  /// **'Tushundim'**
  String get parcelNoticeOk;

  /// No description provided for @parcelWaking.
  ///
  /// In uz, this message translates to:
  /// **'Server ishga tushmoqda, biroz kuting…'**
  String get parcelWaking;

  /// No description provided for @parcelOffline.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasi yo‘q. Oxirgi yuklangan e’lonlar ko‘rsatilmoqda.'**
  String get parcelOffline;

  /// No description provided for @parcelSearch.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get parcelSearch;

  /// No description provided for @parcelSearchPosts.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlardan qidirish'**
  String get parcelSearchPosts;

  /// No description provided for @parcelSearching.
  ///
  /// In uz, this message translates to:
  /// **'Qidirilmoqda… {done}/{total} kun'**
  String parcelSearching(int done, int total);

  /// No description provided for @parcelNothingFound.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get parcelNothingFound;

  /// No description provided for @parcelSavedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan e’lonlar'**
  String get parcelSavedTitle;

  /// No description provided for @parcelSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get parcelSave;

  /// No description provided for @parcelUnsave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlardan olib tashlash'**
  String get parcelUnsave;

  /// No description provided for @parcelSavedEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha saqlangan e’lon yo‘q. E’londagi belgini bosib saqlang.'**
  String get parcelSavedEmpty;

  /// No description provided for @parcelRemoved.
  ///
  /// In uz, this message translates to:
  /// **'Olib tashlandi'**
  String get parcelRemoved;

  /// No description provided for @parcelUndo.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get parcelUndo;

  /// No description provided for @parcelShare.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get parcelShare;

  /// No description provided for @parcelEnd.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa e’lonlar yo‘q'**
  String get parcelEnd;

  /// No description provided for @parcelDraft.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum! {route} reysingiz ({date}) bo‘yicha pochta haqida yozyapman.'**
  String parcelDraft(String route, String date);

  /// No description provided for @parcelDraftNoDate.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum! {route} reysingiz bo‘yicha pochta haqida yozyapman.'**
  String parcelDraftNoDate(String route);

  /// No description provided for @linksTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydali linklar'**
  String get linksTitle;

  /// No description provided for @linksSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta Telegram guruh va kanal'**
  String linksSubtitle(int count);

  /// No description provided for @linksSearch.
  ///
  /// In uz, this message translates to:
  /// **'Guruh, shahar yoki mavzu'**
  String get linksSearch;

  /// No description provided for @linksJobs.
  ///
  /// In uz, this message translates to:
  /// **'Ish'**
  String get linksJobs;

  /// No description provided for @linksLife.
  ///
  /// In uz, this message translates to:
  /// **'Koreya hayoti'**
  String get linksLife;

  /// No description provided for @linksGroups.
  ///
  /// In uz, this message translates to:
  /// **'Guruhlar'**
  String get linksGroups;

  /// No description provided for @linksFavorites.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilar'**
  String get linksFavorites;

  /// No description provided for @linksNearest.
  ///
  /// In uz, this message translates to:
  /// **'Yaqinlik'**
  String get linksNearest;

  /// No description provided for @linksByRegion.
  ///
  /// In uz, this message translates to:
  /// **'Hududlar'**
  String get linksByRegion;

  /// No description provided for @linksYourPlace.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvingiz: {city}'**
  String linksYourPlace(String city);

  /// No description provided for @linksLocate.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni aniqlang — yaqin guruhlar birinchi chiqadi'**
  String get linksLocate;

  /// No description provided for @linksLocateButton.
  ///
  /// In uz, this message translates to:
  /// **'Aniqlash'**
  String get linksLocateButton;

  /// No description provided for @linksNationwide.
  ///
  /// In uz, this message translates to:
  /// **'Butun Koreya'**
  String get linksNationwide;

  /// No description provided for @linksNearby.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin atrofda'**
  String get linksNearby;

  /// No description provided for @linksFarther.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa shaharlar'**
  String get linksFarther;

  /// No description provided for @linksRegionCapital.
  ///
  /// In uz, this message translates to:
  /// **'Seul va Gyeonggi'**
  String get linksRegionCapital;

  /// No description provided for @linksRegionChungcheong.
  ///
  /// In uz, this message translates to:
  /// **'Chungcheong'**
  String get linksRegionChungcheong;

  /// No description provided for @linksRegionJeolla.
  ///
  /// In uz, this message translates to:
  /// **'Jeolla'**
  String get linksRegionJeolla;

  /// No description provided for @linksRegionGyeongsang.
  ///
  /// In uz, this message translates to:
  /// **'Gyeongsang'**
  String get linksRegionGyeongsang;

  /// No description provided for @linksOther.
  ///
  /// In uz, this message translates to:
  /// **'Boshqalar'**
  String get linksOther;

  /// No description provided for @linksTopicOfficial.
  ///
  /// In uz, this message translates to:
  /// **'Rasmiy'**
  String get linksTopicOfficial;

  /// No description provided for @linksTopicNews.
  ///
  /// In uz, this message translates to:
  /// **'Yangiliklar va ma’lumot'**
  String get linksTopicNews;

  /// No description provided for @linksTopicLegal.
  ///
  /// In uz, this message translates to:
  /// **'Huquq va vizalar'**
  String get linksTopicLegal;

  /// No description provided for @linksTopicInsurance.
  ///
  /// In uz, this message translates to:
  /// **'Sug‘urta'**
  String get linksTopicInsurance;

  /// No description provided for @linksTopicWork.
  ///
  /// In uz, this message translates to:
  /// **'Ish va karyera'**
  String get linksTopicWork;

  /// No description provided for @linksTopicEveryday.
  ///
  /// In uz, this message translates to:
  /// **'Kundalik hayot'**
  String get linksTopicEveryday;

  /// No description provided for @linksForEveryone.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy'**
  String get linksForEveryone;

  /// No description provided for @linksForWomen.
  ///
  /// In uz, this message translates to:
  /// **'Ayollar uchun'**
  String get linksForWomen;

  /// No description provided for @linksOurs.
  ///
  /// In uz, this message translates to:
  /// **'Bizning guruh: taklif va savollar uchun'**
  String get linksOurs;

  /// No description provided for @linksSuggestTitle.
  ///
  /// In uz, this message translates to:
  /// **'Guruhingiz ro‘yxatda yo‘qmi?'**
  String get linksSuggestTitle;

  /// No description provided for @linksSuggestBody.
  ///
  /// In uz, this message translates to:
  /// **'Muslim Vegukin guruhiga yozing, qo‘shamiz.'**
  String get linksSuggestBody;

  /// No description provided for @linksOpen.
  ///
  /// In uz, this message translates to:
  /// **'Telegramda ochish'**
  String get linksOpen;

  /// No description provided for @linksCopy.
  ///
  /// In uz, this message translates to:
  /// **'Havolani nusxalash'**
  String get linksCopy;

  /// No description provided for @linksCopied.
  ///
  /// In uz, this message translates to:
  /// **'Havola nusxalandi'**
  String get linksCopied;

  /// No description provided for @linksShare.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get linksShare;

  /// No description provided for @linksFavorite.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilarga qo‘shish'**
  String get linksFavorite;

  /// No description provided for @linksUnfavorite.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilardan olib tashlash'**
  String get linksUnfavorite;

  /// No description provided for @linksNothing.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get linksNothing;

  /// No description provided for @linksResults.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta natija'**
  String linksResults(int count);

  /// No description provided for @donationTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xayriya'**
  String get donationTitle;

  /// No description provided for @donationHeroTitle.
  ///
  /// In uz, this message translates to:
  /// **'Loyiha faoliyatini qo‘llab-quvvatlang'**
  String get donationHeroTitle;

  /// No description provided for @donationHeroSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yordamingiz bilan loyiha yanada rivojlanadi'**
  String get donationHeroSubtitle;

  /// No description provided for @donationMessage.
  ///
  /// In uz, this message translates to:
  /// **'Agar ushbu bot sizga foydali bo‘layotgan bo‘lsa va uning ishlashi hamda rivojlanishiga o‘z hissangizni qo‘shmoqchi bo‘lsangiz, quyidagi hisob raqamga istalgan miqdorda moddiy mablag‘laringizni yuborishingiz mumkin.'**
  String get donationMessage;

  /// No description provided for @donationName.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get donationName;

  /// No description provided for @donationAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisob raqam'**
  String get donationAccount;

  /// No description provided for @donationCopied.
  ///
  /// In uz, this message translates to:
  /// **'Nusxa olindi!'**
  String get donationCopied;

  /// No description provided for @donationUsageTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yig‘ilgan mablag‘lar quyidagilar uchun ishlatiladi'**
  String get donationUsageTitle;

  /// No description provided for @donationUsage1.
  ///
  /// In uz, this message translates to:
  /// **'Server va hosting xarajatlari'**
  String get donationUsage1;

  /// No description provided for @donationUsage2.
  ///
  /// In uz, this message translates to:
  /// **'Texnik xizmat va muntazam yangilanishlar'**
  String get donationUsage2;

  /// No description provided for @donationUsage3.
  ///
  /// In uz, this message translates to:
  /// **'Dasturchilar mehnati va loyihani rivojlantirish'**
  String get donationUsage3;

  /// No description provided for @donationThanksText.
  ///
  /// In uz, this message translates to:
  /// **'Sizning har qanday hissangiz biz uchun katta ahamiyatga ega!'**
  String get donationThanksText;

  /// No description provided for @donationThanks.
  ///
  /// In uz, this message translates to:
  /// **'Rahmat!'**
  String get donationThanks;

  /// No description provided for @communityTitle.
  ///
  /// In uz, this message translates to:
  /// **'Jamoa'**
  String get communityTitle;

  /// No description provided for @communityHeroTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rasmiy Telegram Guruhi'**
  String get communityHeroTitle;

  /// No description provided for @communityHeroSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Bot foydalanuvchilari jamiyati'**
  String get communityHeroSubtitle;

  /// No description provided for @communityJoinNow.
  ///
  /// In uz, this message translates to:
  /// **'Hoziroq qo‘shiling'**
  String get communityJoinNow;

  /// No description provided for @communityPurposeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Guruh maqsadi'**
  String get communityPurposeTitle;

  /// No description provided for @communityPurposeText.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu guruh Muslim Vegukin Bot foydalanuvchilari uchun rasmiy muhokama maydonidir. Bu yerda bot bilan bog‘liq barcha masalalarni muhokama qilishingiz mumkin.'**
  String get communityPurposeText;

  /// No description provided for @communityAllowedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Guruh muhokama mavzulari'**
  String get communityAllowedTitle;

  /// No description provided for @communityTopicPlaceTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi manzillar haqida xabar berish'**
  String get communityTopicPlaceTitle;

  /// No description provided for @communityTopicPlaceBody.
  ///
  /// In uz, this message translates to:
  /// **'Yangi masjid, restoran yoki do‘kon qo‘shilishi kerak bo‘lsa'**
  String get communityTopicPlaceBody;

  /// No description provided for @communityTopicIdeaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Takliflar va g‘oyalar'**
  String get communityTopicIdeaTitle;

  /// No description provided for @communityTopicIdeaBody.
  ///
  /// In uz, this message translates to:
  /// **'Botni yaxshilash uchun fikrlaringiz'**
  String get communityTopicIdeaBody;

  /// No description provided for @communityTopicBugTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xatolar haqida xabar berish'**
  String get communityTopicBugTitle;

  /// No description provided for @communityTopicBugBody.
  ///
  /// In uz, this message translates to:
  /// **'Agar botda muammo topsangiz'**
  String get communityTopicBugBody;

  /// No description provided for @communityTopicNewsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bot yangiliklari'**
  String get communityTopicNewsTitle;

  /// No description provided for @communityTopicNewsBody.
  ///
  /// In uz, this message translates to:
  /// **'Yangi funksiyalar va o‘zgarishlar haqida e’lonlar'**
  String get communityTopicNewsBody;

  /// No description provided for @communityTopicBetaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Beta versiyalar muhokamasi'**
  String get communityTopicBetaTitle;

  /// No description provided for @communityTopicBetaBody.
  ///
  /// In uz, this message translates to:
  /// **'Yangi funksiyalarni ommaga chiqarishdan oldin sinab ko‘rish'**
  String get communityTopicBetaBody;

  /// No description provided for @communityTopicQuestionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bot haqida savollar'**
  String get communityTopicQuestionTitle;

  /// No description provided for @communityTopicQuestionBody.
  ///
  /// In uz, this message translates to:
  /// **'Qanday ishlatish, funksiyalar haqida'**
  String get communityTopicQuestionBody;

  /// No description provided for @communityTopicPeopleTitle.
  ///
  /// In uz, this message translates to:
  /// **'Jamiyat bilan muloqot'**
  String get communityTopicPeopleTitle;

  /// No description provided for @communityTopicPeopleBody.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa foydalanuvchilar bilan tajriba almashish'**
  String get communityTopicPeopleBody;

  /// No description provided for @communityRulesTitle.
  ///
  /// In uz, this message translates to:
  /// **'Guruh qoidalari'**
  String get communityRulesTitle;

  /// No description provided for @communityRulesWarning.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagi turdagi xabarlar o‘chirib tashlanadi'**
  String get communityRulesWarning;

  /// No description provided for @communityBanned1Title.
  ///
  /// In uz, this message translates to:
  /// **'Reklama va savdo e’lonlari'**
  String get communityBanned1Title;

  /// No description provided for @communityBanned1Body.
  ///
  /// In uz, this message translates to:
  /// **'Har qanday turdagi sotish yoki xarid e’lonlari'**
  String get communityBanned1Body;

  /// No description provided for @communityBanned2Title.
  ///
  /// In uz, this message translates to:
  /// **'O‘quv kurslari reklamasi'**
  String get communityBanned2Title;

  /// No description provided for @communityBanned2Body.
  ///
  /// In uz, this message translates to:
  /// **'Til kurslari, o‘quv markazlari va boshqalar'**
  String get communityBanned2Body;

  /// No description provided for @communityBanned3Title.
  ///
  /// In uz, this message translates to:
  /// **'Bot bilan bog‘liq bo‘lmagan savollar'**
  String get communityBanned3Title;

  /// No description provided for @communityBanned3Body.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy savollar uchun boshqa guruhlardan foydalaning'**
  String get communityBanned3Body;

  /// No description provided for @communityBanned4Title.
  ///
  /// In uz, this message translates to:
  /// **'Spam va takroriy xabarlar'**
  String get communityBanned4Title;

  /// No description provided for @communityBanned4Body.
  ///
  /// In uz, this message translates to:
  /// **'Bir xil xabarlarni qayta-qayta yozish'**
  String get communityBanned4Body;

  /// No description provided for @communityBanned5Title.
  ///
  /// In uz, this message translates to:
  /// **'Mavzudan tashqari munozaralar'**
  String get communityBanned5Title;

  /// No description provided for @communityBanned5Body.
  ///
  /// In uz, this message translates to:
  /// **'Bot bilan aloqasi bo‘lmagan suhbatlar'**
  String get communityBanned5Body;

  /// No description provided for @communityPenaltyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirish'**
  String get communityPenaltyTitle;

  /// No description provided for @communityPenaltyText.
  ///
  /// In uz, this message translates to:
  /// **'Qoidalarga zid xabarlar o‘chiriladi. Agar o‘chirilgan xabar qayta yozilsa, foydalanuvchi guruhda yozish huquqidan cheklanadi (restrict).'**
  String get communityPenaltyText;

  /// No description provided for @communityCta.
  ///
  /// In uz, this message translates to:
  /// **'Qoidalarga rioya qilgan holda guruhga qo‘shilishingizni so‘rab qolamiz!'**
  String get communityCta;

  /// No description provided for @donationTransfer.
  ///
  /// In uz, this message translates to:
  /// **'Pul o‘tkazish'**
  String get donationTransfer;

  /// No description provided for @donationBank.
  ///
  /// In uz, this message translates to:
  /// **'Bank'**
  String get donationBank;

  /// No description provided for @donationCopyAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisob raqamni nusxalash'**
  String get donationCopyAccount;

  /// No description provided for @donationCopyName.
  ///
  /// In uz, this message translates to:
  /// **'Ismni nusxalash'**
  String get donationCopyName;

  /// No description provided for @donationOpenApp.
  ///
  /// In uz, this message translates to:
  /// **'Bank ilovasida o‘tkazish'**
  String get donationOpenApp;

  /// No description provided for @donationOpenAppHint.
  ///
  /// In uz, this message translates to:
  /// **'Hisob raqam nusxalanadi — ilovada joylang'**
  String get donationOpenAppHint;

  /// No description provided for @donationPasteHint.
  ///
  /// In uz, this message translates to:
  /// **'Hisob raqam nusxalandi — ilovada joylang'**
  String get donationPasteHint;

  /// No description provided for @donationShare.
  ///
  /// In uz, this message translates to:
  /// **'Rekvizitlarni ulashish'**
  String get donationShare;

  /// No description provided for @donationAsk.
  ///
  /// In uz, this message translates to:
  /// **'Savol va takliflar uchun — guruhimiz'**
  String get donationAsk;

  /// No description provided for @communityCopyLink.
  ///
  /// In uz, this message translates to:
  /// **'Havolani nusxalash'**
  String get communityCopyLink;

  /// No description provided for @communityLinkCopied.
  ///
  /// In uz, this message translates to:
  /// **'Havola nusxalandi'**
  String get communityLinkCopied;

  /// No description provided for @communityShare.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get communityShare;

  /// No description provided for @communityMore.
  ///
  /// In uz, this message translates to:
  /// **'Guruhda yana'**
  String get communityMore;

  /// No description provided for @communityTemplateHint.
  ///
  /// In uz, this message translates to:
  /// **'Shablon nusxalanadi. Guruhda joylab, bo‘sh joylarni to‘ldiring.'**
  String get communityTemplateHint;

  /// No description provided for @communityTemplateGo.
  ///
  /// In uz, this message translates to:
  /// **'Nusxalash va guruhni ochish'**
  String get communityTemplateGo;

  /// No description provided for @communityTemplateCopied.
  ///
  /// In uz, this message translates to:
  /// **'Shablon nusxalandi — guruhda joylang'**
  String get communityTemplateCopied;

  /// No description provided for @communityTemplatePlace.
  ///
  /// In uz, this message translates to:
  /// **'📍 Yangi joy\nNomi: \nTuri: masjid / oshxona / do‘kon\nManzil: \nXaritadagi havola: \nQo‘shimcha: '**
  String get communityTemplatePlace;

  /// No description provided for @communityTemplateBug.
  ///
  /// In uz, this message translates to:
  /// **'🐛 Xato\nQaysi bo‘limda: \nNima bo‘ldi: \nNima bo‘lishi kerak edi: \n\nTelefon: {phone}\nIlova: {version}'**
  String communityTemplateBug(String phone, String version);

  /// No description provided for @barcodeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tarkib tekshirish'**
  String get barcodeTitle;

  /// No description provided for @barcodeHint.
  ///
  /// In uz, this message translates to:
  /// **'Shtrix kodni ramkaga to‘g‘rilang'**
  String get barcodeHint;

  /// No description provided for @barcodeChecking.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirilmoqda…'**
  String get barcodeChecking;

  /// No description provided for @barcodeTypeCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni kiritish'**
  String get barcodeTypeCode;

  /// No description provided for @barcodeTorch.
  ///
  /// In uz, this message translates to:
  /// **'Chiroq'**
  String get barcodeTorch;

  /// No description provided for @barcodeSwitchCamera.
  ///
  /// In uz, this message translates to:
  /// **'Kamerani almashtirish'**
  String get barcodeSwitchCamera;

  /// No description provided for @barcodeBackToCamera.
  ///
  /// In uz, this message translates to:
  /// **'Skanerlash'**
  String get barcodeBackToCamera;

  /// No description provided for @barcodeCameraOffTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kameraga ruxsat berilmagan'**
  String get barcodeCameraOffTitle;

  /// No description provided for @barcodeCameraOffBody.
  ///
  /// In uz, this message translates to:
  /// **'Skanerlash uchun kameraga ruxsat bering yoki kodni qo‘lda kiriting.'**
  String get barcodeCameraOffBody;

  /// No description provided for @barcodeOpenSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalarni ochish'**
  String get barcodeOpenSettings;

  /// No description provided for @barcodeCameraError.
  ///
  /// In uz, this message translates to:
  /// **'Kameraga ulanib bo‘lmadi.'**
  String get barcodeCameraError;

  /// No description provided for @barcodeRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get barcodeRetry;

  /// No description provided for @barcodeVerdictJoiz.
  ///
  /// In uz, this message translates to:
  /// **'Joiz'**
  String get barcodeVerdictJoiz;

  /// No description provided for @barcodeVerdictShubhali.
  ///
  /// In uz, this message translates to:
  /// **'Shubhali'**
  String get barcodeVerdictShubhali;

  /// No description provided for @barcodeVerdictNojoiz.
  ///
  /// In uz, this message translates to:
  /// **'Joiz emas'**
  String get barcodeVerdictNojoiz;

  /// No description provided for @barcodeVerdictJoizDesc.
  ///
  /// In uz, this message translates to:
  /// **'Tarkibida ta’qiqlangan ingredientlar topilmadi'**
  String get barcodeVerdictJoizDesc;

  /// No description provided for @barcodeVerdictShubhaliDesc.
  ///
  /// In uz, this message translates to:
  /// **'Ta’qiqlangan moddalar yo‘q, lekin bir zavodda ishlab chiqarilgan yoki ayrim ingredientlar o‘zagi HAYVONlardan olingan bo‘lishi mumkin.'**
  String get barcodeVerdictShubhaliDesc;

  /// No description provided for @barcodeVerdictNojoizDesc.
  ///
  /// In uz, this message translates to:
  /// **'Tarkibida ta’qiqlangan ingredientlar aniqlandi'**
  String get barcodeVerdictNojoizDesc;

  /// No description provided for @barcodePork.
  ///
  /// In uz, this message translates to:
  /// **'Cho‘chqa'**
  String get barcodePork;

  /// No description provided for @barcodeAlcohol.
  ///
  /// In uz, this message translates to:
  /// **'Alkogol'**
  String get barcodeAlcohol;

  /// No description provided for @barcodeMeat.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa go‘sht'**
  String get barcodeMeat;

  /// No description provided for @barcodeSeafood.
  ///
  /// In uz, this message translates to:
  /// **'Dengiz mahsulotlari'**
  String get barcodeSeafood;

  /// No description provided for @barcodeAbsent.
  ///
  /// In uz, this message translates to:
  /// **'yo‘q'**
  String get barcodeAbsent;

  /// No description provided for @barcodePresent.
  ///
  /// In uz, this message translates to:
  /// **'bor'**
  String get barcodePresent;

  /// No description provided for @barcodeAmbiguous.
  ///
  /// In uz, this message translates to:
  /// **'Tarkibida 트랜스지방, 쇼트닝, 향료 yoki 글리세린 bor — o‘simlik yoki HAYVON YOG‘idan olinishi mumkin.'**
  String get barcodeAmbiguous;

  /// No description provided for @barcodeFactoryWarn.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot ta’qiqlangan ingredientlar tayyorlanadigan zavod/uskunalarda ishlab chiqarilgan.'**
  String get barcodeFactoryWarn;

  /// No description provided for @barcodeFactoryOk.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot ishlab chiqarilgan zavod/uskunalarda ta’qiqlangan mahsulotlar ishlatilmaydi.'**
  String get barcodeFactoryOk;

  /// No description provided for @barcodeIngredients.
  ///
  /// In uz, this message translates to:
  /// **'Tarkibi'**
  String get barcodeIngredients;

  /// No description provided for @barcodeDoubtfulLink.
  ///
  /// In uz, this message translates to:
  /// **'Shubhali mahsulotni yesa bo‘ladimi?'**
  String get barcodeDoubtfulLink;

  /// No description provided for @barcodeFoundIn.
  ///
  /// In uz, this message translates to:
  /// **'Topildi:'**
  String get barcodeFoundIn;

  /// No description provided for @barcodeGeneralDb.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy ma’lumotlar bazasi'**
  String get barcodeGeneralDb;

  /// No description provided for @barcodeStoreUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Do‘kon belgilanmagan'**
  String get barcodeStoreUnknown;

  /// No description provided for @barcodeAlsoAt.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa do‘konlarda ham bor:'**
  String get barcodeAlsoAt;

  /// No description provided for @barcodeCopyCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni nusxalash'**
  String get barcodeCopyCode;

  /// No description provided for @barcodeCopied.
  ///
  /// In uz, this message translates to:
  /// **'Nusxalandi'**
  String get barcodeCopied;

  /// No description provided for @barcodeScanNext.
  ///
  /// In uz, this message translates to:
  /// **'Keyingisini skanerlash'**
  String get barcodeScanNext;

  /// No description provided for @barcodeNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot topilmadi'**
  String get barcodeNotFound;

  /// No description provided for @barcodeNotFoundDesc.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu mahsulot hozircha bazada yo‘q. Tez orada qo‘shilishi mumkin.'**
  String get barcodeNotFoundDesc;

  /// No description provided for @barcodeOfflineTitle.
  ///
  /// In uz, this message translates to:
  /// **'Internet yo‘q'**
  String get barcodeOfflineTitle;

  /// No description provided for @barcodeOfflineBody.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotni tekshirish uchun internet kerak. Ulanishni tekshirib, qayta urinib ko‘ring.'**
  String get barcodeOfflineBody;

  /// No description provided for @barcodeSaved.
  ///
  /// In uz, this message translates to:
  /// **'Avval saqlangan natija · internet yo‘q'**
  String get barcodeSaved;

  /// No description provided for @barcodeRecent.
  ///
  /// In uz, this message translates to:
  /// **'So‘nggi tekshiruvlar'**
  String get barcodeRecent;

  /// No description provided for @barcodeClear.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get barcodeClear;

  /// No description provided for @barcodeTypeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kodni kiriting'**
  String get barcodeTypeTitle;

  /// No description provided for @barcodeTypeHint.
  ///
  /// In uz, this message translates to:
  /// **'Shtrixlar ostidagi raqamlar: 8 tadan 14 tagacha.'**
  String get barcodeTypeHint;

  /// No description provided for @barcodeSearch.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get barcodeSearch;

  /// No description provided for @barcodeErrEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kod kiriting.'**
  String get barcodeErrEmpty;

  /// No description provided for @barcodeErrNonDigit.
  ///
  /// In uz, this message translates to:
  /// **'Faqat raqamlar kiriting.'**
  String get barcodeErrNonDigit;

  /// No description provided for @barcodeErrLength.
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kod 8 dan 14 tagacha raqamdan iborat bo‘lishi kerak.'**
  String get barcodeErrLength;

  /// No description provided for @barcodeErrChecksum.
  ///
  /// In uz, this message translates to:
  /// **'Shtrix-kod noto‘g‘ri. Raqamlarni tekshiring.'**
  String get barcodeErrChecksum;

  /// No description provided for @barcodeStores.
  ///
  /// In uz, this message translates to:
  /// **'Do‘konlar'**
  String get barcodeStores;

  /// How many products a store has.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta mahsulot}}'**
  String barcodeProducts(int count);

  /// No description provided for @barcodeSoon.
  ///
  /// In uz, this message translates to:
  /// **'Yaqinda'**
  String get barcodeSoon;

  /// No description provided for @barcodeStoresError.
  ///
  /// In uz, this message translates to:
  /// **'Do‘konlar yuklanmadi'**
  String get barcodeStoresError;

  /// No description provided for @barcodeAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get barcodeAll;

  /// No description provided for @barcodeStoreEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot topilmadi'**
  String get barcodeStoreEmpty;

  /// No description provided for @barcodeStoreEmptyDesc.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa turkum yoki hukmni tanlang.'**
  String get barcodeStoreEmptyDesc;

  /// No description provided for @barcodeProductsError.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar yuklanmadi'**
  String get barcodeProductsError;

  /// No description provided for @barcodeCheckConnection.
  ///
  /// In uz, this message translates to:
  /// **'Internetni tekshirib, qayta urinib ko‘ring.'**
  String get barcodeCheckConnection;

  /// No description provided for @barcodeContribTitle.
  ///
  /// In uz, this message translates to:
  /// **'Halol baza yig‘ishga sherik bo‘ling'**
  String get barcodeContribTitle;

  /// No description provided for @barcodeContribBody.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar tarkibini o‘qiy oladiganlar uchun: GS25, CU, 7-Eleven, Emart24, No Brand va Daiso do‘konlaridagi halol mahsulotlar bazasini birgalikda yig‘amiz. Har bir yozuv minglab yurtdoshlarimizga yetib boradi — ortingizdan sadaqa-i joriyangizni qoldiring.'**
  String get barcodeContribBody;

  /// No description provided for @barcodeContribCta.
  ///
  /// In uz, this message translates to:
  /// **'Adminga yozish'**
  String get barcodeContribCta;

  /// No description provided for @barcodeDisclaimer.
  ///
  /// In uz, this message translates to:
  /// **'Bu ma’lumotlar faqat mahsulot tarkibi asosida taqdim etilgan bo‘lib, *xatoliklar bo‘lishi mumkin*. Biz rasmiy diniy hukm (fatvo) bermaymiz. Xatolik topsangiz, Telegram guruhimizga xabar bering.'**
  String get barcodeDisclaimer;

  /// No description provided for @barcodeCatDrinks.
  ///
  /// In uz, this message translates to:
  /// **'Ichimliklar'**
  String get barcodeCatDrinks;

  /// No description provided for @barcodeCatSnacks.
  ///
  /// In uz, this message translates to:
  /// **'Yengil ovqatlar'**
  String get barcodeCatSnacks;

  /// No description provided for @barcodeCatSweets.
  ///
  /// In uz, this message translates to:
  /// **'Shirinliklar'**
  String get barcodeCatSweets;

  /// No description provided for @barcodeCatIceCream.
  ///
  /// In uz, this message translates to:
  /// **'Muzqaymoq'**
  String get barcodeCatIceCream;

  /// No description provided for @barcodeCatBaked.
  ///
  /// In uz, this message translates to:
  /// **'Non mahsulotlari'**
  String get barcodeCatBaked;

  /// No description provided for @barcodeCatNoodles.
  ///
  /// In uz, this message translates to:
  /// **'Lag‘mon/Ramen'**
  String get barcodeCatNoodles;

  /// No description provided for @barcodeCatLunchbox.
  ///
  /// In uz, this message translates to:
  /// **'Pechenya/Pishiriqlar'**
  String get barcodeCatLunchbox;

  /// No description provided for @barcodeCatDairy.
  ///
  /// In uz, this message translates to:
  /// **'Sut mahsulotlari'**
  String get barcodeCatDairy;

  /// No description provided for @barcodeCatCanned.
  ///
  /// In uz, this message translates to:
  /// **'Konserva'**
  String get barcodeCatCanned;

  /// No description provided for @barcodeCatFrozen.
  ///
  /// In uz, this message translates to:
  /// **'Muzlatilgan'**
  String get barcodeCatFrozen;

  /// No description provided for @barcodeCatSauces.
  ///
  /// In uz, this message translates to:
  /// **'Ziravor/Souslar'**
  String get barcodeCatSauces;

  /// No description provided for @barcodeCatFruits.
  ///
  /// In uz, this message translates to:
  /// **'Meva/Sabzavot'**
  String get barcodeCatFruits;

  /// No description provided for @barcodeCatDried.
  ///
  /// In uz, this message translates to:
  /// **'Quritilgan'**
  String get barcodeCatDried;

  /// No description provided for @qnaLabel.
  ///
  /// In uz, this message translates to:
  /// **'Savol-javob markazi'**
  String get qnaLabel;

  /// No description provided for @qnaVerseRef.
  ///
  /// In uz, this message translates to:
  /// **'Nahl surasi, 43-oyat'**
  String get qnaVerseRef;

  /// No description provided for @qnaSource.
  ///
  /// In uz, this message translates to:
  /// **'Shayx Muhammad Sodiq Muhammad Yusuf va boshqa ustozlarning javoblari'**
  String get qnaSource;

  /// No description provided for @qnaCount.
  ///
  /// In uz, this message translates to:
  /// **'100 000+ savol'**
  String get qnaCount;

  /// No description provided for @qnaAi.
  ///
  /// In uz, this message translates to:
  /// **'Sun’iy intellekt qidiruvi'**
  String get qnaAi;

  /// No description provided for @qnaSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Savolingizni o‘z so‘zlaringiz bilan yozing…'**
  String get qnaSearchHint;

  /// No description provided for @qnaUzbekNote.
  ///
  /// In uz, this message translates to:
  /// **'Savollar va javoblar o‘zbek tilida.'**
  String get qnaUzbekNote;

  /// No description provided for @qnaDaily.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik tanlov'**
  String get qnaDaily;

  /// No description provided for @qnaDailySub.
  ///
  /// In uz, this message translates to:
  /// **'Har kuni yangi savollar'**
  String get qnaDailySub;

  /// No description provided for @qnaNewSet.
  ///
  /// In uz, this message translates to:
  /// **'Yangi savollar'**
  String get qnaNewSet;

  /// No description provided for @qnaLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Savollar yuklanmadi'**
  String get qnaLoadError;

  /// No description provided for @qnaCheckConnection.
  ///
  /// In uz, this message translates to:
  /// **'Internetni tekshirib, qayta urinib ko‘ring.'**
  String get qnaCheckConnection;

  /// No description provided for @qnaRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get qnaRetry;

  /// No description provided for @qnaSaved.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan javoblar'**
  String get qnaSaved;

  /// No description provided for @qnaSavedEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hali hech narsa saqlanmagan'**
  String get qnaSavedEmpty;

  /// No description provided for @qnaSavedHint.
  ///
  /// In uz, this message translates to:
  /// **'Javobni belgi tugmasi bilan saqlang — internet bo‘lmasa ham o‘qiysiz.'**
  String get qnaSavedHint;

  /// No description provided for @qnaSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get qnaSave;

  /// No description provided for @qnaUnsave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlardan olib tashlash'**
  String get qnaUnsave;

  /// No description provided for @qnaSavedNote.
  ///
  /// In uz, this message translates to:
  /// **'Saqlandi'**
  String get qnaSavedNote;

  /// No description provided for @qnaRemovedNote.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlardan olib tashlandi'**
  String get qnaRemovedNote;

  /// No description provided for @qnaShare.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get qnaShare;

  /// No description provided for @qnaTextSize.
  ///
  /// In uz, this message translates to:
  /// **'Matn o‘lchami'**
  String get qnaTextSize;

  /// No description provided for @qnaQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Savol'**
  String get qnaQuestion;

  /// No description provided for @qnaAnswer.
  ///
  /// In uz, this message translates to:
  /// **'Javob'**
  String get qnaAnswer;

  /// No description provided for @qnaOpenSource.
  ///
  /// In uz, this message translates to:
  /// **'Manbaga o‘tish'**
  String get qnaOpenSource;

  /// No description provided for @qnaCopy.
  ///
  /// In uz, this message translates to:
  /// **'Nusxalash'**
  String get qnaCopy;

  /// No description provided for @qnaCopied.
  ///
  /// In uz, this message translates to:
  /// **'Savol va javob nusxalandi'**
  String get qnaCopied;

  /// No description provided for @qnaRelated.
  ///
  /// In uz, this message translates to:
  /// **'O‘xshash savollar'**
  String get qnaRelated;

  /// No description provided for @qnaAnswerError.
  ///
  /// In uz, this message translates to:
  /// **'Javob yuklanmadi'**
  String get qnaAnswerError;

  /// No description provided for @qnaOther.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa'**
  String get qnaOther;

  /// No description provided for @qnaSearchTitle.
  ///
  /// In uz, this message translates to:
  /// **'Savol qidirish'**
  String get qnaSearchTitle;

  /// No description provided for @qnaSearchButton.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get qnaSearchButton;

  /// No description provided for @qnaMinLetters.
  ///
  /// In uz, this message translates to:
  /// **'Kamida 3 ta harf yozing'**
  String get qnaMinLetters;

  /// No description provided for @qnaHowTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qanday ishlaydi?'**
  String get qnaHowTitle;

  /// No description provided for @qnaHowBody.
  ///
  /// In uz, this message translates to:
  /// **'Sun’iy intellekt o‘zbek til modeli savolingizning ma’nosini tushunib, minglab savol-javoblar ichidan eng o‘xshashlarini topadi. So‘zma-so‘z mos kelishi shart emas: savolingizni to‘liq va grammatik to‘g‘ri yozsangiz, javob aniqroq bo‘ladi. Lotin yoki kirill yozuvida yozishingiz mumkin.'**
  String get qnaHowBody;

  /// No description provided for @qnaRecent.
  ///
  /// In uz, this message translates to:
  /// **'So‘nggi qidiruvlar'**
  String get qnaRecent;

  /// No description provided for @qnaClear.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get qnaClear;

  /// No description provided for @qnaRemove.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirish'**
  String get qnaRemove;

  /// No description provided for @qnaExamples.
  ///
  /// In uz, this message translates to:
  /// **'Masalan'**
  String get qnaExamples;

  /// How many questions a search found.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta natija}}'**
  String qnaResults(int count);

  /// No description provided for @qnaNoResults.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get qnaNoResults;

  /// No description provided for @qnaNoResultsHint.
  ///
  /// In uz, this message translates to:
  /// **'Savolni boshqacharoq, to‘liqroq yozib ko‘ring.'**
  String get qnaNoResultsHint;

  /// No description provided for @qnaOfflineTitle.
  ///
  /// In uz, this message translates to:
  /// **'Internet yo‘q'**
  String get qnaOfflineTitle;

  /// No description provided for @qnaOfflineBody.
  ///
  /// In uz, this message translates to:
  /// **'Qidiruv uchun internet kerak. Saqlangan javoblar internetsiz ham ochiladi.'**
  String get qnaOfflineBody;

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
