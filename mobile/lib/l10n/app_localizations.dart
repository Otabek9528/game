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

  /// No description provided for @bizTitle.
  ///
  /// In uz, this message translates to:
  /// **'Biznes katalogi'**
  String get bizTitle;

  /// No description provided for @bizTagline.
  ///
  /// In uz, this message translates to:
  /// **'Koreyadagi o‘zbek bizneslari — bir joyda'**
  String get bizTagline;

  /// No description provided for @bizSearchTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qidiruv'**
  String get bizSearchTitle;

  /// No description provided for @bizSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Biznes yoki xizmatni qidiring'**
  String get bizSearchHint;

  /// How many businesses are listed.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta biznes}}'**
  String bizCountAll(int count);

  /// How many businesses a search found.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} ta topildi}}'**
  String bizCountFound(int count);

  /// No description provided for @bizTileEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bo‘sh'**
  String get bizTileEmpty;

  /// No description provided for @bizDirectoryEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Katalog hozircha bo‘sh'**
  String get bizDirectoryEmpty;

  /// No description provided for @bizDirectoryEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Bu yerda Koreyadagi o‘zbek bizneslari to‘planadi.'**
  String get bizDirectoryEmptyBody;

  /// No description provided for @bizSaved.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlar'**
  String get bizSaved;

  /// No description provided for @bizCategories.
  ///
  /// In uz, this message translates to:
  /// **'Yo‘nalishlar'**
  String get bizCategories;

  /// No description provided for @bizOrderNote.
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar eng ko‘p yoqtirgan bizneslar yuqorida'**
  String get bizOrderNote;

  /// No description provided for @bizCategoryEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Bu yo‘nalishda hali biznes yo‘q'**
  String get bizCategoryEmpty;

  /// No description provided for @bizCategoryEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Yangi bizneslar qo‘shilgach shu yerda ko‘rinadi. Boshqa yo‘nalishlarga ham qarab ko‘ring.'**
  String get bizCategoryEmptyBody;

  /// No description provided for @bizSeeAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get bizSeeAll;

  /// No description provided for @bizNothingFound.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get bizNothingFound;

  /// No description provided for @bizNothingFoundBody.
  ///
  /// In uz, this message translates to:
  /// **'“{query}” bo‘yicha biznes topilmadi. Boshqacha yozib ko‘ring yoki yo‘nalishlardan qidiring.'**
  String bizNothingFoundBody(String query);

  /// No description provided for @bizLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab bo‘lmadi'**
  String get bizLoadError;

  /// No description provided for @bizCheckConnection.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasini tekshirib, qayta urinib ko‘ring.'**
  String get bizCheckConnection;

  /// No description provided for @bizRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get bizRetry;

  /// No description provided for @bizUzbekNote.
  ///
  /// In uz, this message translates to:
  /// **'Bizneslar haqidagi ma’lumotlar o‘zbek tilida.'**
  String get bizUzbekNote;

  /// No description provided for @bizSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get bizSave;

  /// No description provided for @bizUnsave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlardan olib tashlash'**
  String get bizUnsave;

  /// No description provided for @bizSavedNote.
  ///
  /// In uz, this message translates to:
  /// **'Saqlandi — aloqa ma’lumotlari internetsiz ham ochiladi'**
  String get bizSavedNote;

  /// No description provided for @bizRemovedNote.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlardan olib tashlandi'**
  String get bizRemovedNote;

  /// No description provided for @bizShare.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get bizShare;

  /// No description provided for @bizShareFooter.
  ///
  /// In uz, this message translates to:
  /// **'Muslim Vegukin biznes katalogidan'**
  String get bizShareFooter;

  /// How many times a listing was opened.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} marta ko‘rilgan}}'**
  String bizViews(int count);

  /// How many people liked a business.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, other{{count} kishiga yoqdi}}'**
  String bizLikes(int count);

  /// No description provided for @bizLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotni yuklab bo‘lmadi.'**
  String get bizLoadFailed;

  /// No description provided for @bizLinks.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa havolalar'**
  String get bizLinks;

  /// No description provided for @bizAbout.
  ///
  /// In uz, this message translates to:
  /// **'Biznes haqida'**
  String get bizAbout;

  /// No description provided for @bizNoInfo.
  ///
  /// In uz, this message translates to:
  /// **'Bu biznes hali to‘liq ma’lumot kiritmagan.'**
  String get bizNoInfo;

  /// No description provided for @bizNoContact.
  ///
  /// In uz, this message translates to:
  /// **'Aloqa ma’lumotlari ko‘rsatilmagan.'**
  String get bizNoContact;

  /// No description provided for @bizNoContactAsk.
  ///
  /// In uz, this message translates to:
  /// **'Admin orqali so‘rash'**
  String get bizNoContactAsk;

  /// No description provided for @bizReport.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumot noto‘g‘rimi? Adminga xabar bering'**
  String get bizReport;

  /// No description provided for @bizCopyAddress.
  ///
  /// In uz, this message translates to:
  /// **'Nusxalash'**
  String get bizCopyAddress;

  /// No description provided for @bizAddressCopied.
  ///
  /// In uz, this message translates to:
  /// **'Manzil nusxalandi'**
  String get bizAddressCopied;

  /// No description provided for @bizPhoneCopied.
  ///
  /// In uz, this message translates to:
  /// **'Raqam nusxalandi'**
  String get bizPhoneCopied;

  /// No description provided for @bizActCall.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘ng‘iroq qilish'**
  String get bizActCall;

  /// No description provided for @bizActTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegramda yozish'**
  String get bizActTelegram;

  /// No description provided for @bizActChannel.
  ///
  /// In uz, this message translates to:
  /// **'Telegramda ochish'**
  String get bizActChannel;

  /// No description provided for @bizActKakao.
  ///
  /// In uz, this message translates to:
  /// **'KakaoTalkda yozish'**
  String get bizActKakao;

  /// No description provided for @bizActWebsite.
  ///
  /// In uz, this message translates to:
  /// **'Saytni ochish'**
  String get bizActWebsite;

  /// No description provided for @bizActInstagram.
  ///
  /// In uz, this message translates to:
  /// **'Instagramda ko‘rish'**
  String get bizActInstagram;

  /// No description provided for @bizActTiktok.
  ///
  /// In uz, this message translates to:
  /// **'TikTokda ko‘rish'**
  String get bizActTiktok;

  /// No description provided for @bizActYoutube.
  ///
  /// In uz, this message translates to:
  /// **'YouTube’da ko‘rish'**
  String get bizActYoutube;

  /// No description provided for @bizActFacebook.
  ///
  /// In uz, this message translates to:
  /// **'Facebookda ochish'**
  String get bizActFacebook;

  /// No description provided for @bizActPlay.
  ///
  /// In uz, this message translates to:
  /// **'Google Play’da ochish'**
  String get bizActPlay;

  /// No description provided for @bizActAppStore.
  ///
  /// In uz, this message translates to:
  /// **'App Store’da ochish'**
  String get bizActAppStore;

  /// No description provided for @bizActOpen.
  ///
  /// In uz, this message translates to:
  /// **'Ochish'**
  String get bizActOpen;

  /// No description provided for @bizChannelPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get bizChannelPhone;

  /// No description provided for @bizChannelGroup.
  ///
  /// In uz, this message translates to:
  /// **'Telegram kanal / guruh'**
  String get bizChannelGroup;

  /// No description provided for @bizChannelWebsite.
  ///
  /// In uz, this message translates to:
  /// **'Veb-sayt'**
  String get bizChannelWebsite;

  /// No description provided for @bizPrivateGroup.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq guruh'**
  String get bizPrivateGroup;

  /// No description provided for @bizMapNaver.
  ///
  /// In uz, this message translates to:
  /// **'Naver xarita'**
  String get bizMapNaver;

  /// No description provided for @bizMapKakao.
  ///
  /// In uz, this message translates to:
  /// **'Kakao xarita'**
  String get bizMapKakao;

  /// No description provided for @bizMapGoogle.
  ///
  /// In uz, this message translates to:
  /// **'Google xarita'**
  String get bizMapGoogle;

  /// No description provided for @bizOwnerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Biznes egasimisiz?'**
  String get bizOwnerTitle;

  /// No description provided for @bizOwnerBody.
  ///
  /// In uz, this message translates to:
  /// **'Biznesingizni katalogga qo‘shing — mijozlar sizni shu yerdan topadi.'**
  String get bizOwnerBody;

  /// No description provided for @bizOwnerBodyEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Bu yo‘nalishga birinchi bo‘lib qo‘shiling.'**
  String get bizOwnerBodyEmpty;

  /// No description provided for @bizOwnerEyebrow.
  ///
  /// In uz, this message translates to:
  /// **'Biznes egalari uchun'**
  String get bizOwnerEyebrow;

  /// No description provided for @bizOwnerSheetTitle.
  ///
  /// In uz, this message translates to:
  /// **'Katalogga qo‘shilish'**
  String get bizOwnerSheetTitle;

  /// No description provided for @bizStep1Title.
  ///
  /// In uz, this message translates to:
  /// **'Ariza yuborish'**
  String get bizStep1Title;

  /// No description provided for @bizStep1Body.
  ///
  /// In uz, this message translates to:
  /// **'Biznes logosi, nomi, yo‘nalishi va aloqa ma’lumotlarini kiriting.'**
  String get bizStep1Body;

  /// No description provided for @bizStep2Title.
  ///
  /// In uz, this message translates to:
  /// **'To‘lov'**
  String get bizStep2Title;

  /// No description provided for @bizStep2Body.
  ///
  /// In uz, this message translates to:
  /// **'Bir martalik to‘lov — {amount}. Adminga to‘lov skrinshotini yuborasiz.'**
  String bizStep2Body(String amount);

  /// No description provided for @bizStep3Title.
  ///
  /// In uz, this message translates to:
  /// **'Katalogda'**
  String get bizStep3Title;

  /// No description provided for @bizStep3Body.
  ///
  /// In uz, this message translates to:
  /// **'To‘lov tasdiqlangach biznesingiz katalogda ko‘rina boshlaydi.'**
  String get bizStep3Body;

  /// No description provided for @bizOwnerFine.
  ///
  /// In uz, this message translates to:
  /// **'Katalogda ko‘rinish tartibi biznesga bosilgan klass soniga qarab belgilanadi: eng ko‘p yoqtirilgan biznes yuqorida turadi.'**
  String get bizOwnerFine;

  /// No description provided for @bizOwnerHow.
  ///
  /// In uz, this message translates to:
  /// **'Ariza Telegram orqali yuboriladi: adminga yozing, u biznesingizni qo‘shishda yordam beradi.'**
  String get bizOwnerHow;

  /// No description provided for @bizOwnerContact.
  ///
  /// In uz, this message translates to:
  /// **'Admin bilan bog‘lanish'**
  String get bizOwnerContact;

  /// A sum in Korean won, already formatted.
  ///
  /// In uz, this message translates to:
  /// **'{amount} won'**
  String bizCurrency(String amount);

  /// No description provided for @accountTitle.
  ///
  /// In uz, this message translates to:
  /// **'Akkaunt'**
  String get accountTitle;

  /// No description provided for @signInTitle.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntingizga kiring'**
  String get signInTitle;

  /// No description provided for @signInWhy.
  ///
  /// In uz, this message translates to:
  /// **'Joylarni kuzatish va bildirishnomalar kirmasdan ham ishlaydi. Izoh yozish, ma’lumotni tuzatish va e’lon berish uchun kiring — boshqalar kim yozganini bilsin.'**
  String get signInWhy;

  /// No description provided for @signInTelegramNote.
  ///
  /// In uz, this message translates to:
  /// **'Bu bo‘lim Telegram orqali ishlaydi. Muslim Vegukin botidagi akkauntingiz bilan kiring — botda joylagan e’lonlaringiz shu yerda ham ko‘rinadi.'**
  String get signInTelegramNote;

  /// No description provided for @signInTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegram orqali kirish'**
  String get signInTelegram;

  /// No description provided for @signInWhatsApp.
  ///
  /// In uz, this message translates to:
  /// **'WhatsApp orqali kirish'**
  String get signInWhatsApp;

  /// No description provided for @signInGoogle.
  ///
  /// In uz, this message translates to:
  /// **'Google orqali kirish'**
  String get signInGoogle;

  /// No description provided for @signInWaitingTitle.
  ///
  /// In uz, this message translates to:
  /// **'{app}da «Ha, kirish»ni bosing'**
  String signInWaitingTitle(String app);

  /// No description provided for @signInWaitingBody.
  ///
  /// In uz, this message translates to:
  /// **'Shu yerda kutib turamiz. Tasdiqlagach, ilovaga qayting.'**
  String get signInWaitingBody;

  /// No description provided for @signInOpenAgain.
  ///
  /// In uz, this message translates to:
  /// **'{app}ni qayta ochish'**
  String signInOpenAgain(String app);

  /// No description provided for @signInCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get signInCancel;

  /// No description provided for @signInExpired.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt tugadi yoki bekor qilindi. Qaytadan urinib ko‘ring.'**
  String get signInExpired;

  /// No description provided for @signInFailed.
  ///
  /// In uz, this message translates to:
  /// **'Bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.'**
  String get signInFailed;

  /// No description provided for @signInDone.
  ///
  /// In uz, this message translates to:
  /// **'Kirdingiz'**
  String get signInDone;

  /// No description provided for @signedInWith.
  ///
  /// In uz, this message translates to:
  /// **'{provider} orqali kirilgan'**
  String signedInWith(String provider);

  /// No description provided for @signOut.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get signOut;

  /// No description provided for @accountDelete.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntni o‘chirish'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In uz, this message translates to:
  /// **'Akkaunt o‘chirilsinmi?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvlaringiz, hududlaringiz va izohlaringiz butunlay o‘chiriladi. Buni qaytarib bo‘lmaydi.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleteTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegram botda qilinganlari ham.'**
  String get accountDeleteTelegram;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirish'**
  String get accountDeleteConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Akkaunt o‘chirildi'**
  String get accountDeleted;

  /// No description provided for @accountPushOn.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar shu telefonga keladi'**
  String get accountPushOn;

  /// No description provided for @accountPushOff.
  ///
  /// In uz, this message translates to:
  /// **'Xabarlar baribir «Kelgan xabarlar»ga tushadi, lekin telefon ularni ko‘rsatmaydi.'**
  String get accountPushOff;

  /// No description provided for @pushOpen.
  ///
  /// In uz, this message translates to:
  /// **'Ochish'**
  String get pushOpen;

  /// No description provided for @inboxTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kelgan xabarlar'**
  String get inboxTitle;

  /// No description provided for @inboxUnread.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta yangi'**
  String inboxUnread(int count);

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha xabar yo‘q'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Sizga yuborilgan bildirishnomalar shu yerda saqlanadi — o‘tkazib yuborganlaringiz ham.'**
  String get inboxEmptyBody;

  /// No description provided for @inboxFailed.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab bo‘lmadi. Internetni tekshiring.'**
  String get inboxFailed;

  /// No description provided for @inboxEarlier.
  ///
  /// In uz, this message translates to:
  /// **'Avvalgilarini ko‘rsatish'**
  String get inboxEarlier;

  /// No description provided for @inboxPushOff.
  ///
  /// In uz, this message translates to:
  /// **'Bu telefonda bildirishnomalar o‘chiq. Yangi xabarlar baribir shu yerda chiqadi.'**
  String get inboxPushOff;

  /// No description provided for @inboxMessage.
  ///
  /// In uz, this message translates to:
  /// **'Xabar'**
  String get inboxMessage;

  /// No description provided for @inboxOpenSection.
  ///
  /// In uz, this message translates to:
  /// **'«{section}» bo‘limini ochish'**
  String inboxOpenSection(String section);

  /// No description provided for @inboxPhoto.
  ///
  /// In uz, this message translates to:
  /// **'{total} ta rasmdan {index}-si'**
  String inboxPhoto(int index, int total);

  /// No description provided for @hkLede.
  ///
  /// In uz, this message translates to:
  /// **'Ofisingizdagi bo‘sh kunlarni ko‘ring. Hammasi band bo‘lsa, kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.'**
  String get hkLede;

  /// No description provided for @hkSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Ofis nomini izlang'**
  String get hkSearchHint;

  /// No description provided for @hkMyWatches.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvlarim'**
  String get hkMyWatches;

  /// No description provided for @hkActiveWatches.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta faol kuzatuv'**
  String hkActiveWatches(int count);

  /// No description provided for @hkLastViewed.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi ko‘rilgan'**
  String get hkLastViewed;

  /// No description provided for @hkStep1.
  ///
  /// In uz, this message translates to:
  /// **'Ofisingizni toping'**
  String get hkStep1;

  /// No description provided for @hkStep2.
  ///
  /// In uz, this message translates to:
  /// **'Bo‘sh kunlarni ko‘ring'**
  String get hkStep2;

  /// No description provided for @hkStep3.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea\'da bron qiling'**
  String get hkStep3;

  /// No description provided for @hkAddressCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ofisingizni bilmaysizmi?'**
  String get hkAddressCardTitle;

  /// No description provided for @hkAddressCardBody.
  ///
  /// In uz, this message translates to:
  /// **'Uy manzilingiz bo‘yicha topib beramiz'**
  String get hkAddressCardBody;

  /// No description provided for @hkOffices.
  ///
  /// In uz, this message translates to:
  /// **'Immigratsiya ofislari'**
  String get hkOffices;

  /// No description provided for @hkCounters.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta bo‘lim'**
  String hkCounters(int count);

  /// No description provided for @hkNoMatch.
  ///
  /// In uz, this message translates to:
  /// **'Bunday ofis topilmadi. Boshqa so‘z bilan izlang yoki manzil bo‘yicha toping.'**
  String get hkNoMatch;

  /// No description provided for @hkLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab bo‘lmadi. Internetni tekshiring.'**
  String get hkLoadFailed;

  /// No description provided for @hkAddressTitle.
  ///
  /// In uz, this message translates to:
  /// **'Manzil bo‘yicha topish'**
  String get hkAddressTitle;

  /// No description provided for @hkAddressLede.
  ///
  /// In uz, this message translates to:
  /// **'Har bir ofis o‘z tumanlariga xizmat qiladi. Viloyatingizni tanlang va uy manzilingizni koreyscha yozing.'**
  String get hkAddressLede;

  /// No description provided for @hkProvince.
  ///
  /// In uz, this message translates to:
  /// **'1. Viloyat'**
  String get hkProvince;

  /// No description provided for @hkAddress.
  ///
  /// In uz, this message translates to:
  /// **'2. Uy manzili (koreyscha)'**
  String get hkAddress;

  /// No description provided for @hkAddressHint.
  ///
  /// In uz, this message translates to:
  /// **'Manzilda shahar yoki tuman nomi bo‘lsin (-시, -구, -군), masalan 안산시 단원구.'**
  String get hkAddressHint;

  /// No description provided for @hkFindOffice.
  ///
  /// In uz, this message translates to:
  /// **'Ofisni topish'**
  String get hkFindOffice;

  /// No description provided for @hkNeedProvince.
  ///
  /// In uz, this message translates to:
  /// **'Avval viloyatni tanlang'**
  String get hkNeedProvince;

  /// No description provided for @hkNeedAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni yozing'**
  String get hkNeedAddress;

  /// No description provided for @hkYourOffice.
  ///
  /// In uz, this message translates to:
  /// **'Sizning ofisingiz:'**
  String get hkYourOffice;

  /// No description provided for @hkPickOne.
  ///
  /// In uz, this message translates to:
  /// **'Mosini tanlang:'**
  String get hkPickOne;

  /// No description provided for @hkAddressNoMatch.
  ///
  /// In uz, this message translates to:
  /// **'Bu manzil uchun ofis topilmadi. Manzilni to‘liq yozing.'**
  String get hkAddressNoMatch;

  /// No description provided for @hkCountersTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi bo‘lim kerak?'**
  String get hkCountersTitle;

  /// No description provided for @hkCountersLede.
  ///
  /// In uz, this message translates to:
  /// **'Bo‘limlar bir xil ishni bajaradi, lekin joyi, qavati yoki qabul vaqti farq qilishi mumkin. Tanlashdan oldin tavsifini o‘qing.'**
  String get hkCountersLede;

  /// No description provided for @hkFromAfternoon.
  ///
  /// In uz, this message translates to:
  /// **'Qabul 09:36 dan'**
  String get hkFromAfternoon;

  /// No description provided for @hkMore.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil'**
  String get hkMore;

  /// No description provided for @hkCounterN.
  ///
  /// In uz, this message translates to:
  /// **'{n}-bo‘lim'**
  String hkCounterN(int n);

  /// No description provided for @hkCalendarHint.
  ///
  /// In uz, this message translates to:
  /// **'Kunni bosing — joylarni HiKorea\'dan hozir tekshiramiz.'**
  String get hkCalendarHint;

  /// No description provided for @hkCheckedNow.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgina tekshirildi'**
  String get hkCheckedNow;

  /// No description provided for @hkCheckedMinutes.
  ///
  /// In uz, this message translates to:
  /// **'{n} daqiqa oldin tekshirildi'**
  String hkCheckedMinutes(int n);

  /// No description provided for @hkCheckedHours.
  ///
  /// In uz, this message translates to:
  /// **'{n} soat oldin tekshirildi'**
  String hkCheckedHours(int n);

  /// No description provided for @hkCheckedDays.
  ///
  /// In uz, this message translates to:
  /// **'{n} kun oldin tekshirildi'**
  String hkCheckedDays(int n);

  /// No description provided for @hkEarliest.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaqin bo‘sh kun'**
  String get hkEarliest;

  /// No description provided for @hkAllFull.
  ///
  /// In uz, this message translates to:
  /// **'Hozir hamma kunlar band'**
  String get hkAllFull;

  /// No description provided for @hkAllFullBody.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.'**
  String get hkAllFullBody;

  /// No description provided for @hkLegendOpen.
  ///
  /// In uz, this message translates to:
  /// **'Bo‘sh'**
  String get hkLegendOpen;

  /// No description provided for @hkLegendSome.
  ///
  /// In uz, this message translates to:
  /// **'Bandlik bor'**
  String get hkLegendSome;

  /// No description provided for @hkLegendFull.
  ///
  /// In uz, this message translates to:
  /// **'To‘la band'**
  String get hkLegendFull;

  /// No description provided for @hkLegendClosed.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq'**
  String get hkLegendClosed;

  /// No description provided for @hkNoDates.
  ///
  /// In uz, this message translates to:
  /// **'Hozir hech qanday kun ko‘rinmayapti. Kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.'**
  String get hkNoDates;

  /// No description provided for @hkNotifyMe.
  ///
  /// In uz, this message translates to:
  /// **'Joy ochilganda xabar berish'**
  String get hkNotifyMe;

  /// No description provided for @hkChecking.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea tekshirilmoqda…'**
  String get hkChecking;

  /// No description provided for @hkDayClosed.
  ///
  /// In uz, this message translates to:
  /// **'Bu kuni ofis ishlamaydi'**
  String get hkDayClosed;

  /// No description provided for @hkFullyBooked.
  ///
  /// In uz, this message translates to:
  /// **'To‘la band'**
  String get hkFullyBooked;

  /// No description provided for @hkLastOne.
  ///
  /// In uz, this message translates to:
  /// **'Faqat 1 ta joy qoldi'**
  String get hkLastOne;

  /// No description provided for @hkSlotsFree.
  ///
  /// In uz, this message translates to:
  /// **'{n} ta bo‘sh joy'**
  String hkSlotsFree(int n);

  /// No description provided for @hkBookCue.
  ///
  /// In uz, this message translates to:
  /// **'Bron qilish HiKorea saytida bo‘ladi.'**
  String get hkBookCue;

  /// No description provided for @hkFullCue.
  ///
  /// In uz, this message translates to:
  /// **'Bo‘sh joy yo‘q. Kuzatuv o‘rnatsangiz, joy ochilishi bilan xabar beramiz.'**
  String get hkFullCue;

  /// No description provided for @hkBookedOf.
  ///
  /// In uz, this message translates to:
  /// **'{capacity} tadan {taken} tasi band'**
  String hkBookedOf(int taken, int capacity);

  /// No description provided for @hkMorning.
  ///
  /// In uz, this message translates to:
  /// **'Ertalab'**
  String get hkMorning;

  /// No description provided for @hkAfternoon.
  ///
  /// In uz, this message translates to:
  /// **'Tushdan keyin'**
  String get hkAfternoon;

  /// No description provided for @hkLeft.
  ///
  /// In uz, this message translates to:
  /// **'{n} ta qoldi'**
  String hkLeft(int n);

  /// No description provided for @hkSlotFull.
  ///
  /// In uz, this message translates to:
  /// **'Band'**
  String get hkSlotFull;

  /// No description provided for @hkBook.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea\'da bron qilish'**
  String get hkBook;

  /// No description provided for @hkFetchFailed.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea\'ga ulanib bo‘lmadi. Birozdan so‘ng qayta urinib ko‘ring.'**
  String get hkFetchFailed;

  /// No description provided for @hkSessionExpired.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea bilan aloqamiz yangilanmoqda. Birozdan so‘ng urinib ko‘ring.'**
  String get hkSessionExpired;

  /// No description provided for @hkWatchTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi kunlarni kuzataylik?'**
  String get hkWatchTitle;

  /// No description provided for @hkWatchLede.
  ///
  /// In uz, this message translates to:
  /// **'Shu kunlarda joy ochilishi bilan bildirishnoma yuboramiz.'**
  String get hkWatchLede;

  /// No description provided for @hkNextDays.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi {n} kun'**
  String hkNextDays(int n);

  /// No description provided for @hkPickDates.
  ///
  /// In uz, this message translates to:
  /// **'Aniq sanalarni tanlash'**
  String get hkPickDates;

  /// No description provided for @hkDays.
  ///
  /// In uz, this message translates to:
  /// **'{n} kun'**
  String hkDays(int n);

  /// No description provided for @hkStartWatching.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatishni boshlash'**
  String get hkStartWatching;

  /// No description provided for @hkTooLong.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘pi bilan 90 kun kuzatish mumkin'**
  String get hkTooLong;

  /// No description provided for @hkDuplicate.
  ///
  /// In uz, this message translates to:
  /// **'Bu kunlar allaqachon kuzatilmoqda'**
  String get hkDuplicate;

  /// No description provided for @hkMaxReached.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘pi bilan 10 ta kuzatuv. Avval bittasini to‘xtating.'**
  String get hkMaxReached;

  /// No description provided for @hkCreateFailed.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvni o‘rnatib bo‘lmadi. Qayta urinib ko‘ring.'**
  String get hkCreateFailed;

  /// No description provided for @hkDoneTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuv o‘rnatildi'**
  String get hkDoneTitle;

  /// No description provided for @hkDoneBody.
  ///
  /// In uz, this message translates to:
  /// **'Har 5 daqiqada tekshiramiz. Joy ochilishi bilan bildirishnoma keladi.'**
  String get hkDoneBody;

  /// No description provided for @hkPushOff.
  ///
  /// In uz, this message translates to:
  /// **'Bu telefonda bildirishnomalar o‘chiq — xabarlar faqat «Kelgan xabarlar»da ko‘rinadi.'**
  String get hkPushOff;

  /// No description provided for @hkSendTest.
  ///
  /// In uz, this message translates to:
  /// **'Sinov bildirishnomasi'**
  String get hkSendTest;

  /// No description provided for @hkTestSent.
  ///
  /// In uz, this message translates to:
  /// **'Yuborildi'**
  String get hkTestSent;

  /// No description provided for @hkTestFailed.
  ///
  /// In uz, this message translates to:
  /// **'Yuborib bo‘lmadi. Bildirishnomalar yoqilganini tekshiring.'**
  String get hkTestFailed;

  /// No description provided for @hkSeeWatches.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvlarimni ko‘rish'**
  String get hkSeeWatches;

  /// No description provided for @hkWatchesEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hali kuzatuv yo‘q'**
  String get hkWatchesEmpty;

  /// No description provided for @hkWatchesEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Ofisni tanlang, kalendarini ko‘ring va kuzatuv o‘rnating.'**
  String get hkWatchesEmptyBody;

  /// No description provided for @hkStatusActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get hkStatusActive;

  /// No description provided for @hkStatusExpired.
  ///
  /// In uz, this message translates to:
  /// **'Muddati tugagan'**
  String get hkStatusExpired;

  /// No description provided for @hkStatusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'To‘xtatilgan'**
  String get hkStatusCancelled;

  /// No description provided for @hkStatusUndeliverable.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib bo‘lmadi'**
  String get hkStatusUndeliverable;

  /// No description provided for @hkStop.
  ///
  /// In uz, this message translates to:
  /// **'To‘xtatish'**
  String get hkStop;

  /// No description provided for @hkStopTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuv to‘xtatilsinmi?'**
  String get hkStopTitle;

  /// No description provided for @hkStopped.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuv to‘xtatildi'**
  String get hkStopped;

  /// No description provided for @hkStopFailed.
  ///
  /// In uz, this message translates to:
  /// **'To‘xtatib bo‘lmadi. Qayta urinib ko‘ring.'**
  String get hkStopFailed;

  /// No description provided for @hkCalendar.
  ///
  /// In uz, this message translates to:
  /// **'Kalendar'**
  String get hkCalendar;

  /// No description provided for @hkPastWatches.
  ///
  /// In uz, this message translates to:
  /// **'Tugaganlar'**
  String get hkPastWatches;

  /// No description provided for @hkPickOffice.
  ///
  /// In uz, this message translates to:
  /// **'Ofisni tanlash'**
  String get hkPickOffice;

  /// No description provided for @hkStep1Body.
  ///
  /// In uz, this message translates to:
  /// **'Nomi yoki uy manzilingiz bo‘yicha'**
  String get hkStep1Body;

  /// No description provided for @hkStep2Body.
  ///
  /// In uz, this message translates to:
  /// **'Har bir bo‘limning keyingi 3 oyi, har 5 daqiqada yangilanadi'**
  String get hkStep2Body;

  /// No description provided for @hkStep3Body.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi band bo‘lsa — kuzatuv o‘rnating, joy ochilganda xabar beramiz'**
  String get hkStep3Body;

  /// No description provided for @hkHowTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qanday ishlaydi'**
  String get hkHowTitle;

  /// No description provided for @hkStartTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizning ofisingiz qaysi?'**
  String get hkStartTitle;

  /// No description provided for @hkStartBody.
  ///
  /// In uz, this message translates to:
  /// **'Bu yashash joyingizga bog‘liq: har bir ofis o‘z tumanlariga xizmat qiladi.'**
  String get hkStartBody;

  /// No description provided for @hkStartOr.
  ///
  /// In uz, this message translates to:
  /// **'yoki quyidagi ro‘yxatdan tanlang'**
  String get hkStartOr;

  /// No description provided for @hkYourWatches.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatuvlaringiz'**
  String get hkYourWatches;

  /// No description provided for @hkSeeAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi ({count})'**
  String hkSeeAll(int count);

  /// No description provided for @hkWatchFree.
  ///
  /// In uz, this message translates to:
  /// **'Sanalaringizda {n} ta bo‘sh kun bor'**
  String hkWatchFree(int n);

  /// No description provided for @hkWatchFull.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi band — kuzatyapmiz'**
  String get hkWatchFull;

  /// No description provided for @hkEarliestShort.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaqin bo‘sh kun: {day}'**
  String hkEarliestShort(String day);

  /// No description provided for @hkAllFullShort.
  ///
  /// In uz, this message translates to:
  /// **'Hozir hamma kunlar band'**
  String get hkAllFullShort;

  /// No description provided for @hkOfficeMain.
  ///
  /// In uz, this message translates to:
  /// **'Immigratsiya ofisi'**
  String get hkOfficeMain;

  /// No description provided for @hkOfficeBranch.
  ///
  /// In uz, this message translates to:
  /// **'Filial'**
  String get hkOfficeBranch;

  /// No description provided for @hkOfficeBranchOf.
  ///
  /// In uz, this message translates to:
  /// **'{office} filiali'**
  String hkOfficeBranchOf(String office);

  /// No description provided for @hkAllOffices.
  ///
  /// In uz, this message translates to:
  /// **'Barcha ofislar'**
  String get hkAllOffices;

  /// No description provided for @hkFreeDays.
  ///
  /// In uz, this message translates to:
  /// **'{date}gacha {n} ta bo‘sh kun'**
  String hkFreeDays(int n, String date);

  /// No description provided for @hkBookedUntil.
  ///
  /// In uz, this message translates to:
  /// **'{date}gacha band. Kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.'**
  String hkBookedUntil(String date);

  /// No description provided for @hkHowBooking.
  ///
  /// In uz, this message translates to:
  /// **'Bron qilish HiKorea saytida, o‘z HiKorea akkauntingiz bilan bo‘ladi. Bu yerda bo‘sh kunlarni ko‘rasiz.'**
  String get hkHowBooking;

  /// No description provided for @hkLegendLater.
  ///
  /// In uz, this message translates to:
  /// **'Hali ochilmagan'**
  String get hkLegendLater;

  /// No description provided for @hkWatchShort.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatish'**
  String get hkWatchShort;

  /// No description provided for @hkStale.
  ///
  /// In uz, this message translates to:
  /// **'Bu bo‘limni oxirgi paytda tekshira olmadik — kunlar eskirgan bo‘lishi mumkin.'**
  String get hkStale;

  /// No description provided for @accountGuest.
  ///
  /// In uz, this message translates to:
  /// **'Mehmon'**
  String get accountGuest;

  /// No description provided for @accountGuestBody.
  ///
  /// In uz, this message translates to:
  /// **'Kirsangiz, izohlaringizda ismingiz ko‘rinadi, kuzatuvlaringiz esa yangi telefonga ham o‘tadi.'**
  String get accountGuestBody;

  /// No description provided for @accountSignIn.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get accountSignIn;

  /// No description provided for @accountNoPhoto.
  ///
  /// In uz, this message translates to:
  /// **'WhatsApp profil rasmini ilovalarga bermaydi.'**
  String get accountNoPhoto;

  /// No description provided for @accountNotifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get accountNotifications;

  /// No description provided for @accountPushOffTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar o‘chiq'**
  String get accountPushOffTitle;

  /// No description provided for @accountTurnOn.
  ///
  /// In uz, this message translates to:
  /// **'Yoqish'**
  String get accountTurnOn;

  /// No description provided for @accountWhatComes.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea\'da joy ochilishi, kuzatayotgan joy va hududlaringiz yangiliklari, e’lonlar.'**
  String get accountWhatComes;

  /// No description provided for @accountTelegramToo.
  ///
  /// In uz, this message translates to:
  /// **'Ular Telegram\'dagi Muslim Vegukin botidan ham keladi.'**
  String get accountTelegramToo;

  /// No description provided for @accountTestPush.
  ///
  /// In uz, this message translates to:
  /// **'Sinov bildirishnomasi'**
  String get accountTestPush;

  /// No description provided for @accountTestSent.
  ///
  /// In uz, this message translates to:
  /// **'Yuborildi — telefoningizda ko‘ring'**
  String get accountTestSent;

  /// No description provided for @accountTestFailed.
  ///
  /// In uz, this message translates to:
  /// **'Yuborib bo‘lmadi. Birozdan so‘ng qayta urinib ko‘ring.'**
  String get accountTestFailed;

  /// No description provided for @accountActivity.
  ///
  /// In uz, this message translates to:
  /// **'Faoliyatingiz'**
  String get accountActivity;

  /// No description provided for @accountInboxNone.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha xabar yo‘q'**
  String get accountInboxNone;

  /// No description provided for @accountInboxAll.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta xabar'**
  String accountInboxAll(int count);

  /// No description provided for @accountApp.
  ///
  /// In uz, this message translates to:
  /// **'Ilova'**
  String get accountApp;

  /// No description provided for @accountLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get accountLanguage;

  /// No description provided for @accountDarkMode.
  ///
  /// In uz, this message translates to:
  /// **'Tungi rejim'**
  String get accountDarkMode;

  /// No description provided for @accountManage.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntni boshqarish'**
  String get accountManage;

  /// No description provided for @accountActive.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta faol'**
  String accountActive(int count);

  /// No description provided for @hkDormantTitle.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea bu bo‘limda hech qanday kun ko‘rsatmayapti'**
  String get hkDormantTitle;

  /// No description provided for @hkDormantBody.
  ///
  /// In uz, this message translates to:
  /// **'{date}dan beri HiKorea bu yerda hech qanday kun ko‘rsatmayapti — na bo‘sh, na band. HiKorea bo‘limni yangisiga almashtirganda shunday bo‘ladi. Ofisning boshqa bo‘limlarini ko‘ring yoki HiKorea saytida tekshiring.'**
  String hkDormantBody(String date);

  /// No description provided for @hkDormantBodyNoDate.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea bu yerda hech qanday kun ko‘rsatmayapti — na bo‘sh, na band. HiKorea bo‘limni yangisiga almashtirganda shunday bo‘ladi. Ofisning boshqa bo‘limlarini ko‘ring yoki HiKorea saytida tekshiring.'**
  String get hkDormantBodyNoDate;

  /// No description provided for @hkOtherCounters.
  ///
  /// In uz, this message translates to:
  /// **'Ofisning boshqa bo‘limlari'**
  String get hkOtherCounters;

  /// No description provided for @hkCheckOnHikorea.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea\'da tekshirish'**
  String get hkCheckOnHikorea;

  /// No description provided for @hkNoDaysShort.
  ///
  /// In uz, this message translates to:
  /// **'HiKorea\'da kun ko‘rinmayapti'**
  String get hkNoDaysShort;

  /// No description provided for @hkLeafLegend.
  ///
  /// In uz, this message translates to:
  /// **'Sana — eng yaqin bo‘sh kun'**
  String get hkLeafLegend;

  /// No description provided for @hkLeafFull.
  ///
  /// In uz, this message translates to:
  /// **'Band'**
  String get hkLeafFull;

  /// No description provided for @hkWatchingHere.
  ///
  /// In uz, this message translates to:
  /// **'Shu yerda kuzatuvingiz bor'**
  String get hkWatchingHere;

  /// No description provided for @plNearest.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaqin'**
  String get plNearest;

  /// No description provided for @plMetres.
  ///
  /// In uz, this message translates to:
  /// **'{n} m'**
  String plMetres(String n);

  /// No description provided for @plKm.
  ///
  /// In uz, this message translates to:
  /// **'{n} km'**
  String plKm(String n);

  /// No description provided for @plNoReviews.
  ///
  /// In uz, this message translates to:
  /// **'Hali izoh yo‘q'**
  String get plNoReviews;

  /// No description provided for @plReviewCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta izoh'**
  String plReviewCount(int count);

  /// No description provided for @plAddressNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Bu manzil topilmadi. Koreys tilida, aniqroq yozib ko‘ring.'**
  String get plAddressNotFound;

  /// No description provided for @plNothingFound.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get plNothingFound;

  /// No description provided for @plLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Joylarni yuklab bo‘lmadi. Internetni tekshiring.'**
  String get plLoadFailed;

  /// No description provided for @plMissingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro‘yxatda yo‘q joyni bilasizmi?'**
  String get plMissingTitle;

  /// No description provided for @plMissingBody.
  ///
  /// In uz, this message translates to:
  /// **'Guruhimizga yozing — qo‘shib qo‘yamiz.'**
  String get plMissingBody;

  /// No description provided for @plWatchingBadge.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatilmoqda'**
  String get plWatchingBadge;

  /// No description provided for @plPhotoCount.
  ///
  /// In uz, this message translates to:
  /// **'{i} / {n}'**
  String plPhotoCount(String i, String n);

  /// No description provided for @plWatch.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatish'**
  String get plWatch;

  /// No description provided for @plWatchers.
  ///
  /// In uz, this message translates to:
  /// **'{count} kishi kuzatmoqda'**
  String plWatchers(int count);

  /// No description provided for @plWatchOn.
  ///
  /// In uz, this message translates to:
  /// **'Yangiliklari shu telefonga keladi'**
  String get plWatchOn;

  /// No description provided for @plWatchOff.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatish to‘xtatildi'**
  String get plWatchOff;

  /// No description provided for @plWatchNoPush.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar o‘chiq — yangiliklar kelmaydi'**
  String get plWatchNoPush;

  /// No description provided for @plWatchPushOn.
  ///
  /// In uz, this message translates to:
  /// **'Yoqish'**
  String get plWatchPushOn;

  /// No description provided for @plAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get plAddress;

  /// No description provided for @plNoAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil ko‘rsatilmagan'**
  String get plNoAddress;

  /// No description provided for @plPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get plPhone;

  /// No description provided for @plMenu.
  ///
  /// In uz, this message translates to:
  /// **'Menyu'**
  String get plMenu;

  /// No description provided for @plMenuOpen.
  ///
  /// In uz, this message translates to:
  /// **'Menyuni ochish'**
  String get plMenuOpen;

  /// No description provided for @plAddressCopied.
  ///
  /// In uz, this message translates to:
  /// **'Manzil nusxalandi'**
  String get plAddressCopied;

  /// No description provided for @plCopyAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni nusxalash'**
  String get plCopyAddress;

  /// No description provided for @plMapAttribution.
  ///
  /// In uz, this message translates to:
  /// **'© OpenStreetMap'**
  String get plMapAttribution;

  /// No description provided for @plAbout.
  ///
  /// In uz, this message translates to:
  /// **'Muassasa haqida'**
  String get plAbout;

  /// No description provided for @plAboutEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Ish vaqti va dam olish kunlari hali qo‘shilmagan.'**
  String get plAboutEmpty;

  /// No description provided for @plAboutAdd.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumot qo‘shish'**
  String get plAboutAdd;

  /// No description provided for @plSuggestChange.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgartirishni taklif qilish'**
  String get plSuggestChange;

  /// No description provided for @plSocial.
  ///
  /// In uz, this message translates to:
  /// **'Ijtimoiy tarmoqlarda'**
  String get plSocial;

  /// No description provided for @plSocialEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Bu joy ijtimoiy tarmoqlarda bormi?'**
  String get plSocialEmpty;

  /// No description provided for @plSocialAdd.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘shish'**
  String get plSocialAdd;

  /// No description provided for @plInviteLink.
  ///
  /// In uz, this message translates to:
  /// **'Havola'**
  String get plInviteLink;

  /// No description provided for @plPendingField.
  ///
  /// In uz, this message translates to:
  /// **'{what}: taklifingiz ko‘rib chiqilmoqda'**
  String plPendingField(String what);

  /// No description provided for @plNoteLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumot'**
  String get plNoteLabel;

  /// No description provided for @plReviews.
  ///
  /// In uz, this message translates to:
  /// **'Izohlar'**
  String get plReviews;

  /// No description provided for @plReviewsFirst.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi bo‘lib izoh qoldiring — boshqalarga yordam bo‘ladi.'**
  String get plReviewsFirst;

  /// No description provided for @plWriteReview.
  ///
  /// In uz, this message translates to:
  /// **'Izoh qoldirish'**
  String get plWriteReview;

  /// No description provided for @plEditReview.
  ///
  /// In uz, this message translates to:
  /// **'Izohingizni o‘zgartirish'**
  String get plEditReview;

  /// No description provided for @plYourReview.
  ///
  /// In uz, this message translates to:
  /// **'Sizning izohingiz'**
  String get plYourReview;

  /// No description provided for @plAllReviews.
  ///
  /// In uz, this message translates to:
  /// **'Hammasini ko‘rish ({count})'**
  String plAllReviews(int count);

  /// No description provided for @plNoText.
  ///
  /// In uz, this message translates to:
  /// **'Faqat baho'**
  String get plNoText;

  /// No description provided for @plCorrections.
  ///
  /// In uz, this message translates to:
  /// **'Nomi, manzili yoki telefoni noto‘g‘rimi? Guruhimizga yozing.'**
  String get plCorrections;

  /// No description provided for @plLoadDetailFailed.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotlarni yuklab bo‘lmadi. Internetni tekshiring.'**
  String get plLoadDetailFailed;

  /// No description provided for @plGone.
  ///
  /// In uz, this message translates to:
  /// **'Bu joy topilmadi — ro‘yxatdan olib tashlangan bo‘lishi mumkin.'**
  String get plGone;

  /// No description provided for @plRateQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Qanday baholaysiz?'**
  String get plRateQuestion;

  /// No description provided for @plStar1.
  ///
  /// In uz, this message translates to:
  /// **'Juda yomon'**
  String get plStar1;

  /// No description provided for @plStar2.
  ///
  /// In uz, this message translates to:
  /// **'Yomon'**
  String get plStar2;

  /// No description provided for @plStar3.
  ///
  /// In uz, this message translates to:
  /// **'O‘rtacha'**
  String get plStar3;

  /// No description provided for @plStar4.
  ///
  /// In uz, this message translates to:
  /// **'Yaxshi'**
  String get plStar4;

  /// No description provided for @plStar5.
  ///
  /// In uz, this message translates to:
  /// **'A’lo'**
  String get plStar5;

  /// No description provided for @plReviewHintMosque.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: namoz vaqtlari, kirish eshigidagi parol, qanday borish mumkin.'**
  String get plReviewHintMosque;

  /// No description provided for @plReviewHintRestaurant.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: taomlar, narxlar, xizmat, ish vaqti.'**
  String get plReviewHintRestaurant;

  /// No description provided for @plReviewHintShop.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: nimalar sotiladi, narxlar, ish vaqti.'**
  String get plReviewHintShop;

  /// No description provided for @plReviewPlaceholder.
  ///
  /// In uz, this message translates to:
  /// **'Fikringizni yozing (ixtiyoriy)'**
  String get plReviewPlaceholder;

  /// No description provided for @plReviewPublic.
  ///
  /// In uz, this message translates to:
  /// **'Izoh hammaga ko‘rinadi, ismingiz esa ko‘rinmaydi.'**
  String get plReviewPublic;

  /// No description provided for @plReviewSend.
  ///
  /// In uz, this message translates to:
  /// **'Chop etish'**
  String get plReviewSend;

  /// No description provided for @plReviewSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get plReviewSave;

  /// No description provided for @plReviewPick.
  ///
  /// In uz, this message translates to:
  /// **'Avval yulduzchani tanlang'**
  String get plReviewPick;

  /// No description provided for @plReviewPublished.
  ///
  /// In uz, this message translates to:
  /// **'Rahmat! Izohingiz chop etildi.'**
  String get plReviewPublished;

  /// No description provided for @plReviewUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Izohingiz yangilandi.'**
  String get plReviewUpdated;

  /// No description provided for @plReviewDelete.
  ///
  /// In uz, this message translates to:
  /// **'Izohni o‘chirish'**
  String get plReviewDelete;

  /// No description provided for @plReviewDeleteAsk.
  ///
  /// In uz, this message translates to:
  /// **'Izohingiz o‘chirilsinmi?'**
  String get plReviewDeleteAsk;

  /// No description provided for @plReviewDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Izohingiz o‘chirildi.'**
  String get plReviewDeleted;

  /// No description provided for @plDelete.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirish'**
  String get plDelete;

  /// No description provided for @plCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get plCancel;

  /// No description provided for @plSend.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get plSend;

  /// No description provided for @plSuggestPick.
  ///
  /// In uz, this message translates to:
  /// **'Nimani qo‘shmoqchisiz?'**
  String get plSuggestPick;

  /// No description provided for @plSuggestAddLink.
  ///
  /// In uz, this message translates to:
  /// **'{platform} havolasini qo‘shish'**
  String plSuggestAddLink(String platform);

  /// No description provided for @plSuggestEditLink.
  ///
  /// In uz, this message translates to:
  /// **'{platform} havolasini o‘zgartirish'**
  String plSuggestEditLink(String platform);

  /// No description provided for @plSuggestAddNote.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumot qo‘shish'**
  String get plSuggestAddNote;

  /// No description provided for @plSuggestEditNote.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotni o‘zgartirish'**
  String get plSuggestEditNote;

  /// No description provided for @plSuggestCurrent.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgi: {value}'**
  String plSuggestCurrent(String value);

  /// No description provided for @plHintTelegram.
  ///
  /// In uz, this message translates to:
  /// **'@username yoki t.me havolasi'**
  String get plHintTelegram;

  /// No description provided for @plHintTiktok.
  ///
  /// In uz, this message translates to:
  /// **'@username yoki tiktok.com havolasi'**
  String get plHintTiktok;

  /// No description provided for @plHintInstagram.
  ///
  /// In uz, this message translates to:
  /// **'@username yoki instagram.com havolasi'**
  String get plHintInstagram;

  /// No description provided for @plHintNote.
  ///
  /// In uz, this message translates to:
  /// **'Ish vaqti, dam olish kunlari yoki e’lon.'**
  String get plHintNote;

  /// No description provided for @plNotePlaceholder.
  ///
  /// In uz, this message translates to:
  /// **'Masalan:\nDu–Ju: 11:00 – 22:00\nShanba: yopiq'**
  String get plNotePlaceholder;

  /// No description provided for @plModeration.
  ///
  /// In uz, this message translates to:
  /// **'Admin tekshirgach chop etiladi.'**
  String get plModeration;

  /// No description provided for @plSuggestSent.
  ///
  /// In uz, this message translates to:
  /// **'Rahmat! Taklifingiz ko‘rib chiqilmoqda.'**
  String get plSuggestSent;

  /// No description provided for @plAnnounceMosque.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yozish'**
  String get plAnnounceMosque;

  /// No description provided for @plAnnounceOwner.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yuborish'**
  String get plAnnounceOwner;

  /// No description provided for @plAnnounceWhyMosque.
  ///
  /// In uz, this message translates to:
  /// **'Masalan, hayit namozi vaqti — kuzatayotganlarga yuboriladi.'**
  String get plAnnounceWhyMosque;

  /// No description provided for @plAnnounceWhyOwner.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatayotganlarga yangilik yuboring.'**
  String get plAnnounceWhyOwner;

  /// No description provided for @plAnnouncePending.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta e’lon tekshiruvda'**
  String plAnnouncePending(int count);

  /// No description provided for @plAnnounceTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lon'**
  String get plAnnounceTitle;

  /// No description provided for @plAnnouncePlaceholderOwner.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: 25-dekabr kuni oshxonamiz yopiq bo‘ladi.'**
  String get plAnnouncePlaceholderOwner;

  /// No description provided for @plAnnouncePlaceholderMosque.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Hayit namozi 07:00, 08:00 va 09:00 da o‘qiladi.'**
  String get plAnnouncePlaceholderMosque;

  /// No description provided for @plAnnounceReach.
  ///
  /// In uz, this message translates to:
  /// **'Admin tasdiqlagach, taxminan {count} kishiga yuboriladi.'**
  String plAnnounceReach(int count);

  /// No description provided for @plAnnounceSend.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruvga yuborish'**
  String get plAnnounceSend;

  /// No description provided for @plAnnounceSent.
  ///
  /// In uz, this message translates to:
  /// **'E’lon tekshiruvga yuborildi'**
  String get plAnnounceSent;

  /// No description provided for @plTextEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Avval matn yozing.'**
  String get plTextEmpty;

  /// No description provided for @plClaimPrompt.
  ///
  /// In uz, this message translates to:
  /// **'Bu joy egasimisiz?'**
  String get plClaimPrompt;

  /// No description provided for @plClaimWhy.
  ///
  /// In uz, this message translates to:
  /// **'Egasi kuzatayotganlarga e’lon yubora oladi.'**
  String get plClaimWhy;

  /// No description provided for @plClaimConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Ismingiz va aloqa ma’lumotingiz administratorga yuboriladi. U egalikni tekshirish uchun siz bilan bog‘lanadi. Davom etasizmi?'**
  String get plClaimConfirm;

  /// No description provided for @plClaimContinue.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get plClaimContinue;

  /// No description provided for @plClaimSent.
  ///
  /// In uz, this message translates to:
  /// **'So‘rov yuborildi. Administrator siz bilan bog‘lanadi.'**
  String get plClaimSent;

  /// No description provided for @plClaimPending.
  ///
  /// In uz, this message translates to:
  /// **'Egalik so‘rovingiz ko‘rib chiqilmoqda.'**
  String get plClaimPending;

  /// No description provided for @plYouOwn.
  ///
  /// In uz, this message translates to:
  /// **'Siz bu joyning egasisiz'**
  String get plYouOwn;

  /// No description provided for @plErrNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Internetga ulanib bo‘lmadi. Qayta urinib ko‘ring.'**
  String get plErrNetwork;

  /// No description provided for @plErrGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi. Qayta urinib ko‘ring.'**
  String get plErrGeneric;

  /// No description provided for @plErrSignIn.
  ///
  /// In uz, this message translates to:
  /// **'Buning uchun akkauntga kiring.'**
  String get plErrSignIn;

  /// No description provided for @plErrTooManyReviews.
  ///
  /// In uz, this message translates to:
  /// **'Bugun juda ko‘p izoh qoldirdingiz. Ertaga urinib ko‘ring.'**
  String get plErrTooManyReviews;

  /// No description provided for @plErrTooLong.
  ///
  /// In uz, this message translates to:
  /// **'Matn juda uzun.'**
  String get plErrTooLong;

  /// No description provided for @plErrTooShort.
  ///
  /// In uz, this message translates to:
  /// **'Juda qisqa.'**
  String get plErrTooShort;

  /// No description provided for @plErrWrongHost.
  ///
  /// In uz, this message translates to:
  /// **'Bu havola boshqa saytga tegishli. To‘g‘ri havolani kiriting.'**
  String get plErrWrongHost;

  /// No description provided for @plErrHandle.
  ///
  /// In uz, this message translates to:
  /// **'Username noto‘g‘ri. Faqat harflar, raqamlar va pastki chiziq.'**
  String get plErrHandle;

  /// No description provided for @plErrUrl.
  ///
  /// In uz, this message translates to:
  /// **'Bu havolaga o‘xshamaydi.'**
  String get plErrUrl;

  /// No description provided for @plErrIncomplete.
  ///
  /// In uz, this message translates to:
  /// **'Havola to‘liq emas.'**
  String get plErrIncomplete;

  /// No description provided for @plErrNotProfile.
  ///
  /// In uz, this message translates to:
  /// **'Bu post havolasi. Profil havolasini yuboring.'**
  String get plErrNotProfile;

  /// No description provided for @plErrPending.
  ///
  /// In uz, this message translates to:
  /// **'Bu bo‘yicha taklif allaqachon ko‘rib chiqilmoqda.'**
  String get plErrPending;

  /// No description provided for @plErrSame.
  ///
  /// In uz, this message translates to:
  /// **'Bu allaqachon saqlangan.'**
  String get plErrSame;

  /// No description provided for @plErrRateLimited.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi takliflar limitiga yetdingiz. Ertaga urinib ko‘ring.'**
  String get plErrRateLimited;

  /// No description provided for @plErrGone.
  ///
  /// In uz, this message translates to:
  /// **'Bu joy endi mavjud emas.'**
  String get plErrGone;

  /// No description provided for @plErrNotOwner.
  ///
  /// In uz, this message translates to:
  /// **'Bu joy uchun faqat tasdiqlangan egasi e’lon yubora oladi.'**
  String get plErrNotOwner;

  /// No description provided for @plErrHasOwner.
  ///
  /// In uz, this message translates to:
  /// **'Bu joyning egasi allaqachon tasdiqlangan.'**
  String get plErrHasOwner;

  /// No description provided for @plErrTooManyPending.
  ///
  /// In uz, this message translates to:
  /// **'Tekshiruvni kutayotgan so‘rovlaringiz ko‘p. Avval ular ko‘rib chiqilsin.'**
  String get plErrTooManyPending;

  /// No description provided for @plPhotoFailed.
  ///
  /// In uz, this message translates to:
  /// **'Rasmni yuklab bo‘lmadi'**
  String get plPhotoFailed;

  /// No description provided for @plMosque.
  ///
  /// In uz, this message translates to:
  /// **'Masjid'**
  String get plMosque;

  /// No description provided for @plRestaurant.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona'**
  String get plRestaurant;

  /// No description provided for @plShop.
  ///
  /// In uz, this message translates to:
  /// **'Do‘kon'**
  String get plShop;

  /// No description provided for @plNearMe.
  ///
  /// In uz, this message translates to:
  /// **'O‘z atrofimdan izlash'**
  String get plNearMe;

  /// No description provided for @plByAddress.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa manzil atrofidan izlash'**
  String get plByAddress;

  /// No description provided for @plAddressTip.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni KOREYS tilida yozing: shahar, tuman, ko‘cha. Xaritadan nusxa olsangiz ham bo‘ladi.'**
  String get plAddressTip;

  /// No description provided for @plSearchButton.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get plSearchButton;

  /// No description provided for @plRecentAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Oldingi manzillar'**
  String get plRecentAddresses;

  /// No description provided for @plChooseTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qayerdan izlaymiz?'**
  String get plChooseTitle;

  /// No description provided for @plChooseBody.
  ///
  /// In uz, this message translates to:
  /// **'Yuqoridagi tugmalardan birini tanlang: o‘z atrofingizdan yoki boshqa manzil atrofidan — eng yaqin 5 ta joy chiqadi.'**
  String get plChooseBody;

  /// No description provided for @plNearestMosques.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, =1{Sizga eng yaqin masjid} other{Sizga eng yaqin {count} ta masjid}}'**
  String plNearestMosques(int count);

  /// No description provided for @plNearestRestaurants.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, =1{Sizga eng yaqin oshxona} other{Sizga eng yaqin {count} ta oshxona}}'**
  String plNearestRestaurants(int count);

  /// No description provided for @plNearestShops.
  ///
  /// In uz, this message translates to:
  /// **'{count, plural, =1{Sizga eng yaqin do‘kon} other{Sizga eng yaqin {count} ta do‘kon}}'**
  String plNearestShops(int count);

  /// No description provided for @plNearestToAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilga eng yaqinlari'**
  String get plNearestToAddress;

  /// No description provided for @plHereNow.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvingiz: {city} · {when}'**
  String plHereNow(String city, String when);

  /// No description provided for @plHereNowNoCity.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvingiz aniqlandi · {when}'**
  String plHereNowNoCity(String when);

  /// No description provided for @plSavedNote.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgi joylashuvni aniqlab bo‘lmadi — {city}dagi oldingi joylashuv bo‘yicha ({when})'**
  String plSavedNote(String city, String when);

  /// No description provided for @plSavedNoteNoCity.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgi joylashuvni aniqlab bo‘lmadi — oldingi joylashuv bo‘yicha ({when})'**
  String plSavedNoteNoCity(String when);

  /// No description provided for @plLocatingYou.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvingiz aniqlanmoqda…'**
  String get plLocatingYou;

  /// No description provided for @plLoadingPlaces.
  ///
  /// In uz, this message translates to:
  /// **'Joylar yuklanmoqda…'**
  String get plLoadingPlaces;

  /// No description provided for @plDeniedBody.
  ///
  /// In uz, this message translates to:
  /// **'Eng yaqin joylarni topish uchun joylashuvga ruxsat bering — yoki manzil bo‘yicha izlang.'**
  String get plDeniedBody;

  /// No description provided for @plAllow.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat berish'**
  String get plAllow;

  /// No description provided for @plBlockedBody.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvga ruxsat sozlamalarda o‘chirilgan. Uni yoqing — yoki manzil bo‘yicha izlang.'**
  String get plBlockedBody;

  /// No description provided for @plOffBody.
  ///
  /// In uz, this message translates to:
  /// **'Telefonda joylashuv o‘chiq. Uni yoqing — yoki manzil bo‘yicha izlang.'**
  String get plOffBody;

  /// No description provided for @plFailedBody.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni aniqlab bo‘lmadi. Qayta urinib ko‘ring — yoki manzil bo‘yicha izlang.'**
  String get plFailedBody;

  /// No description provided for @plUseAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil bo‘yicha izlash'**
  String get plUseAddress;

  /// No description provided for @plDetails.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil'**
  String get plDetails;

  /// No description provided for @plKmFromYou.
  ///
  /// In uz, this message translates to:
  /// **'Sizdan {km}'**
  String plKmFromYou(String km);

  /// No description provided for @plKmFromAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzildan {km}'**
  String plKmFromAddress(String km);

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

  /// No description provided for @plSocialMore.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa tarmoqdagi sahifasini bilasizmi?'**
  String get plSocialMore;

  /// No description provided for @plCallNumber.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘ng‘iroq qilish'**
  String get plCallNumber;

  /// No description provided for @plPhotoLoading.
  ///
  /// In uz, this message translates to:
  /// **'Rasm yuklanmoqda…'**
  String get plPhotoLoading;

  /// No description provided for @plPhotoLoadingSpeed.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanish tezligi internetingizga bog‘liq'**
  String get plPhotoLoadingSpeed;

  /// No description provided for @plGettingThere.
  ///
  /// In uz, this message translates to:
  /// **'Qanday borish mumkin'**
  String get plGettingThere;

  /// No description provided for @plContact.
  ///
  /// In uz, this message translates to:
  /// **'Aloqa'**
  String get plContact;

  /// No description provided for @plNewsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangiliklar'**
  String get plNewsTitle;

  /// No description provided for @carMarket.
  ///
  /// In uz, this message translates to:
  /// **'Avto Bozor'**
  String get carMarket;

  /// No description provided for @carTabBrowse.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rish'**
  String get carTabBrowse;

  /// No description provided for @carTabSearch.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get carTabSearch;

  /// No description provided for @carTabSaved.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilar'**
  String get carTabSaved;

  /// No description provided for @carListings.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta e’lon'**
  String carListings(String count);

  /// No description provided for @carAvailableSold.
  ///
  /// In uz, this message translates to:
  /// **'{available} mavjud · {sold} sotilgan'**
  String carAvailableSold(String available, String sold);

  /// No description provided for @carSearchSub.
  ///
  /// In uz, this message translates to:
  /// **'Atributlar bo‘yicha toping'**
  String get carSearchSub;

  /// No description provided for @carSavedSub.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta saqlangan'**
  String carSavedSub(String count);

  /// No description provided for @carLoading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda…'**
  String get carLoading;

  /// No description provided for @carMedianPrice.
  ///
  /// In uz, this message translates to:
  /// **'o‘rtacha narx'**
  String get carMedianPrice;

  /// No description provided for @carNoneOnSale.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha sotuvda yo‘q'**
  String get carNoneOnSale;

  /// No description provided for @carSoldCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} sotilgan'**
  String carSoldCount(String count);

  /// No description provided for @carSortNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get carSortNew;

  /// No description provided for @carSortValue.
  ///
  /// In uz, this message translates to:
  /// **'Eng arzonlari'**
  String get carSortValue;

  /// No description provided for @carSortPriceUp.
  ///
  /// In uz, this message translates to:
  /// **'Narx ↑'**
  String get carSortPriceUp;

  /// No description provided for @carSortPriceDown.
  ///
  /// In uz, this message translates to:
  /// **'Narx ↓'**
  String get carSortPriceDown;

  /// No description provided for @carSortMileage.
  ///
  /// In uz, this message translates to:
  /// **'Yurgani ↑'**
  String get carSortMileage;

  /// No description provided for @carSortYear.
  ///
  /// In uz, this message translates to:
  /// **'Yili ↓'**
  String get carSortYear;

  /// No description provided for @carAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get carAll;

  /// No description provided for @carAvailable.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud'**
  String get carAvailable;

  /// No description provided for @carSold.
  ///
  /// In uz, this message translates to:
  /// **'Sotilgan'**
  String get carSold;

  /// No description provided for @carEmptyAllTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha e’lon yo‘q'**
  String get carEmptyAllTitle;

  /// No description provided for @carEmptyAllBody.
  ///
  /// In uz, this message translates to:
  /// **'Tez orada yangi mashinalar qo‘shiladi'**
  String get carEmptyAllBody;

  /// No description provided for @carEmptyModelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bu modelda e’lon yo‘q'**
  String get carEmptyModelTitle;

  /// No description provided for @carEmptyModelBody.
  ///
  /// In uz, this message translates to:
  /// **'Yuqoridagi nomdan boshqa modelni tanlang'**
  String get carEmptyModelBody;

  /// No description provided for @carChannelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Vegukin Avto — kanal'**
  String get carChannelTitle;

  /// No description provided for @carChannelBody.
  ///
  /// In uz, this message translates to:
  /// **'Barcha yangi e’lonlar shu yerda jonli chiqadi'**
  String get carChannelBody;

  /// No description provided for @carOpen.
  ///
  /// In uz, this message translates to:
  /// **'Ochish'**
  String get carOpen;

  /// No description provided for @carLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab bo‘lmadi'**
  String get carLoadFailed;

  /// No description provided for @carCheckInternet.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasini tekshiring'**
  String get carCheckInternet;

  /// No description provided for @carDeal.
  ///
  /// In uz, this message translates to:
  /// **'Arzon'**
  String get carDeal;

  /// No description provided for @carNegotiable.
  ///
  /// In uz, this message translates to:
  /// **'Kelishiladi'**
  String get carNegotiable;

  /// No description provided for @carNoPrice.
  ///
  /// In uz, this message translates to:
  /// **'Narxi keltirilmagan'**
  String get carNoPrice;

  /// No description provided for @carFewDetails.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumot kam'**
  String get carFewDetails;

  /// No description provided for @carSeen.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rilgan'**
  String get carSeen;

  /// No description provided for @carSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get carSave;

  /// No description provided for @carUnsave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanganlardan olib tashlash'**
  String get carUnsave;

  /// No description provided for @carFuelPetrol.
  ///
  /// In uz, this message translates to:
  /// **'Benzin'**
  String get carFuelPetrol;

  /// No description provided for @carFuelDiesel.
  ///
  /// In uz, this message translates to:
  /// **'Dizel'**
  String get carFuelDiesel;

  /// No description provided for @carFuelLpg.
  ///
  /// In uz, this message translates to:
  /// **'LPG'**
  String get carFuelLpg;

  /// No description provided for @carFuelHybrid.
  ///
  /// In uz, this message translates to:
  /// **'Gibrid'**
  String get carFuelHybrid;

  /// No description provided for @carAutomatic.
  ///
  /// In uz, this message translates to:
  /// **'Avtomat'**
  String get carAutomatic;

  /// No description provided for @carManual.
  ///
  /// In uz, this message translates to:
  /// **'Mexanika'**
  String get carManual;

  /// No description provided for @carNotGiven.
  ///
  /// In uz, this message translates to:
  /// **'Keltirilmagan'**
  String get carNotGiven;

  /// No description provided for @carPickModel.
  ///
  /// In uz, this message translates to:
  /// **'Marka va modelni tanlang'**
  String get carPickModel;

  /// No description provided for @carPriceMax.
  ///
  /// In uz, this message translates to:
  /// **'Narx (gacha), ₩'**
  String get carPriceMax;

  /// No description provided for @carMileageMax.
  ///
  /// In uz, this message translates to:
  /// **'Yurgani (km gacha)'**
  String get carMileageMax;

  /// No description provided for @carYearFrom.
  ///
  /// In uz, this message translates to:
  /// **'Yildan'**
  String get carYearFrom;

  /// No description provided for @carFuel.
  ///
  /// In uz, this message translates to:
  /// **'Yoqilg‘i'**
  String get carFuel;

  /// No description provided for @carStatus.
  ///
  /// In uz, this message translates to:
  /// **'Holati'**
  String get carStatus;

  /// No description provided for @carResults.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta natija'**
  String carResults(String count);

  /// No description provided for @carNothingFound.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get carNothingFound;

  /// No description provided for @carWidenFilters.
  ///
  /// In uz, this message translates to:
  /// **'Filtrlarni kengaytiring'**
  String get carWidenFilters;

  /// No description provided for @carClearFilters.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get carClearFilters;

  /// No description provided for @carSavedEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sevimlilar bo‘sh'**
  String get carSavedEmptyTitle;

  /// No description provided for @carSavedEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Yoqqan mashinalarni ❤ tugmasi bilan saqlang'**
  String get carSavedEmptyBody;

  /// No description provided for @carStartBrowsing.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rishni boshlash'**
  String get carStartBrowsing;

  /// No description provided for @carPickBrand.
  ///
  /// In uz, this message translates to:
  /// **'Markani tanlang'**
  String get carPickBrand;

  /// No description provided for @carAnyBrand.
  ///
  /// In uz, this message translates to:
  /// **'Har qanday'**
  String get carAnyBrand;

  /// No description provided for @carAllBrands.
  ///
  /// In uz, this message translates to:
  /// **'barcha markalar'**
  String get carAllBrands;

  /// No description provided for @carBrandListings.
  ///
  /// In uz, this message translates to:
  /// **'{count} e’lon'**
  String carBrandListings(String count);

  /// No description provided for @carAllOf.
  ///
  /// In uz, this message translates to:
  /// **'Barcha {brand}'**
  String carAllOf(String brand);

  /// No description provided for @carSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish…'**
  String get carSearchHint;

  /// No description provided for @carCatalogFailed.
  ///
  /// In uz, this message translates to:
  /// **'Markalar yuklanmadi. Internetni tekshirib, qayta oching.'**
  String get carCatalogFailed;

  /// No description provided for @carViews.
  ///
  /// In uz, this message translates to:
  /// **'{count} marta ko‘rilgan'**
  String carViews(String count);

  /// No description provided for @carNotice.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotlar e’lon matnidan avtomatik o‘qilgan va xato bo‘lishi mumkin. Aniq narx va tafsilotlar uchun e’lon matnini diqqat bilan o‘qing.'**
  String get carNotice;

  /// No description provided for @carPostText.
  ///
  /// In uz, this message translates to:
  /// **'E’lon matni'**
  String get carPostText;

  /// No description provided for @carNoText.
  ///
  /// In uz, this message translates to:
  /// **'Matn keltirilmagan'**
  String get carNoText;

  /// No description provided for @carReadMore.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘proq o‘qish'**
  String get carReadMore;

  /// No description provided for @carReadLess.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get carReadLess;

  /// No description provided for @carSource.
  ///
  /// In uz, this message translates to:
  /// **'Manba: {name} kanali'**
  String carSource(String name);

  /// No description provided for @carPriceAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Narx tahlili'**
  String get carPriceAnalysis;

  /// No description provided for @carVeryCheap.
  ///
  /// In uz, this message translates to:
  /// **'Juda arzon'**
  String get carVeryCheap;

  /// No description provided for @carCheap.
  ///
  /// In uz, this message translates to:
  /// **'Arzon'**
  String get carCheap;

  /// No description provided for @carAtMarket.
  ///
  /// In uz, this message translates to:
  /// **'Bozor narxida'**
  String get carAtMarket;

  /// No description provided for @carPricier.
  ///
  /// In uz, this message translates to:
  /// **'Qimmatroq'**
  String get carPricier;

  /// No description provided for @carExpensive.
  ///
  /// In uz, this message translates to:
  /// **'Qimmat'**
  String get carExpensive;

  /// No description provided for @carNearAverage.
  ///
  /// In uz, this message translates to:
  /// **'o‘rtachaga yaqin'**
  String get carNearAverage;

  /// No description provided for @carBelowAverage.
  ///
  /// In uz, this message translates to:
  /// **'o‘rtachadan {percent}% arzon'**
  String carBelowAverage(String percent);

  /// No description provided for @carAboveAverage.
  ///
  /// In uz, this message translates to:
  /// **'o‘rtachadan {percent}% qimmat'**
  String carAboveAverage(String percent);

  /// No description provided for @carFewComparables.
  ///
  /// In uz, this message translates to:
  /// **'faqat {count} ta taqqoslash bor'**
  String carFewComparables(String count);

  /// No description provided for @carScaleCheap.
  ///
  /// In uz, this message translates to:
  /// **'arzon {price}'**
  String carScaleCheap(String price);

  /// No description provided for @carScaleDear.
  ///
  /// In uz, this message translates to:
  /// **'qimmat {price}'**
  String carScaleDear(String price);

  /// No description provided for @carNearYearBasis.
  ///
  /// In uz, this message translates to:
  /// **'{year} y. atrofidagi {count} ta · o‘rtacha {median}'**
  String carNearYearBasis(String year, String count, String median);

  /// No description provided for @carModelBasis.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta sotuvda · o‘rtacha {median}'**
  String carModelBasis(String count, String median);

  /// No description provided for @carSoldBasis.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta sotilgan · {median}'**
  String carSoldBasis(String count, String median);

  /// No description provided for @carDetails.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil'**
  String get carDetails;

  /// No description provided for @carGeneration.
  ///
  /// In uz, this message translates to:
  /// **'Avlod'**
  String get carGeneration;

  /// No description provided for @carYear.
  ///
  /// In uz, this message translates to:
  /// **'Yili'**
  String get carYear;

  /// No description provided for @carMileage.
  ///
  /// In uz, this message translates to:
  /// **'Yurgani'**
  String get carMileage;

  /// No description provided for @carGearbox.
  ///
  /// In uz, this message translates to:
  /// **'Karobka'**
  String get carGearbox;

  /// No description provided for @carLegal.
  ///
  /// In uz, this message translates to:
  /// **'Hujjatlari'**
  String get carLegal;

  /// No description provided for @carLegalOk.
  ///
  /// In uz, this message translates to:
  /// **'Legal'**
  String get carLegalOk;

  /// No description provided for @carLegalNoReg.
  ///
  /// In uz, this message translates to:
  /// **'Oformleniyasiz'**
  String get carLegalNoReg;

  /// No description provided for @carRegistration.
  ///
  /// In uz, this message translates to:
  /// **'Nomiga o‘tkazish'**
  String get carRegistration;

  /// No description provided for @carRequired.
  ///
  /// In uz, this message translates to:
  /// **'Shart'**
  String get carRequired;

  /// No description provided for @carNotRequired.
  ///
  /// In uz, this message translates to:
  /// **'Shart emas'**
  String get carNotRequired;

  /// No description provided for @carPosted.
  ///
  /// In uz, this message translates to:
  /// **'E’lon'**
  String get carPosted;

  /// No description provided for @carSourceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Manba'**
  String get carSourceLabel;

  /// No description provided for @carContact.
  ///
  /// In uz, this message translates to:
  /// **'Bog‘lanish'**
  String get carContact;

  /// No description provided for @carSellerPhone.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi telefoni'**
  String get carSellerPhone;

  /// No description provided for @carCall.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘ng‘iroq'**
  String get carCall;

  /// No description provided for @carCopy.
  ///
  /// In uz, this message translates to:
  /// **'Nusxa'**
  String get carCopy;

  /// No description provided for @carCopied.
  ///
  /// In uz, this message translates to:
  /// **'Raqam nusxalandi'**
  String get carCopied;

  /// No description provided for @carWriteOnTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegram orqali yozish'**
  String get carWriteOnTelegram;

  /// No description provided for @carWrite.
  ///
  /// In uz, this message translates to:
  /// **'Yozish'**
  String get carWrite;

  /// No description provided for @carNumberInText.
  ///
  /// In uz, this message translates to:
  /// **'Raqam e’lon matnida'**
  String get carNumberInText;

  /// No description provided for @carSimilar.
  ///
  /// In uz, this message translates to:
  /// **'O‘xshash mashinalar'**
  String get carSimilar;

  /// No description provided for @carSimilarSub.
  ///
  /// In uz, this message translates to:
  /// **'narx bo‘yicha'**
  String get carSimilarSub;

  /// No description provided for @carNoComparables.
  ///
  /// In uz, this message translates to:
  /// **'Taqqoslash uchun e’lon yo‘q'**
  String get carNoComparables;

  /// No description provided for @carListingFailed.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yuklanmadi'**
  String get carListingFailed;

  /// No description provided for @carVideoSize.
  ///
  /// In uz, this message translates to:
  /// **'Video · {size} MB'**
  String carVideoSize(String size);

  /// No description provided for @carListing.
  ///
  /// In uz, this message translates to:
  /// **'E’lon'**
  String get carListing;

  /// No description provided for @carTabAlerts.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma'**
  String get carTabAlerts;

  /// No description provided for @carTabSell.
  ///
  /// In uz, this message translates to:
  /// **'Sotish'**
  String get carTabSell;

  /// No description provided for @carAlertsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnomalar'**
  String get carAlertsTitle;

  /// No description provided for @carAlertsActive.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta faol'**
  String carAlertsActive(String count);

  /// No description provided for @carNewAlert.
  ///
  /// In uz, this message translates to:
  /// **'Yangi xabarnoma'**
  String get carNewAlert;

  /// No description provided for @carAnyCar.
  ///
  /// In uz, this message translates to:
  /// **'Barcha mashinalar'**
  String get carAnyCar;

  /// No description provided for @carCreateAlert.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma yaratish'**
  String get carCreateAlert;

  /// No description provided for @carMyAlerts.
  ///
  /// In uz, this message translates to:
  /// **'Mening xabarnomalarim'**
  String get carMyAlerts;

  /// No description provided for @carNoAlertsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma yo‘q'**
  String get carNoAlertsTitle;

  /// No description provided for @carNoAlertsBody.
  ///
  /// In uz, this message translates to:
  /// **'Yangi mos e’lon chiqsa, sizga bildiramiz'**
  String get carNoAlertsBody;

  /// No description provided for @carAllListings.
  ///
  /// In uz, this message translates to:
  /// **'Barcha e’lonlar'**
  String get carAllListings;

  /// No description provided for @carAlertNeedsFilter.
  ///
  /// In uz, this message translates to:
  /// **'Kamida bitta filtr tanlang (model, narx, yurgani, yil yoki yoqilg‘i).'**
  String get carAlertNeedsFilter;

  /// No description provided for @carAlertDuplicate.
  ///
  /// In uz, this message translates to:
  /// **'Bunday xabarnoma allaqachon mavjud.'**
  String get carAlertDuplicate;

  /// No description provided for @carAlertLimit.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnomalar soni chegarasiga yetdingiz.'**
  String get carAlertLimit;

  /// No description provided for @carAlertCreated.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma yaratildi: mos e’lon chiqsa, telefoningizga keladi.'**
  String get carAlertCreated;

  /// No description provided for @carAlertDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma o‘chirildi'**
  String get carAlertDeleted;

  /// No description provided for @carSignInAlertsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mos mashina chiqsa, xabar beramiz'**
  String get carSignInAlertsTitle;

  /// No description provided for @carSignInAlertsBody.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma uchun akkauntga kiring. Ko‘rish va saqlash uchun kirish shart emas.'**
  String get carSignInAlertsBody;

  /// No description provided for @carSignInButton.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntga kirish'**
  String get carSignInButton;

  /// No description provided for @carPushOff.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar o‘chiq — xabarnomalar telefonga kelmaydi.'**
  String get carPushOff;

  /// No description provided for @carPushOn.
  ///
  /// In uz, this message translates to:
  /// **'Yoqish'**
  String get carPushOn;

  /// No description provided for @carErrorGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi. Qayta urinib ko‘ring.'**
  String get carErrorGeneric;

  /// No description provided for @carMyPosts.
  ///
  /// In uz, this message translates to:
  /// **'Mening e’lonlarim'**
  String get carMyPosts;

  /// No description provided for @carNewPost.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e’lon qo‘shish'**
  String get carNewPost;

  /// No description provided for @carNewPostSub.
  ///
  /// In uz, this message translates to:
  /// **'Mashinangizni soting'**
  String get carNewPostSub;

  /// No description provided for @carNoPostsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hali e’lon yo‘q'**
  String get carNoPostsTitle;

  /// No description provided for @carNoPostsBody.
  ///
  /// In uz, this message translates to:
  /// **'Yuqoridagi tugma orqali birinchi e’loningizni joylang — bir necha daqiqada tayyor bo‘ladi.'**
  String get carNoPostsBody;

  /// No description provided for @carStatePending.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rib chiqilmoqda'**
  String get carStatePending;

  /// No description provided for @carStateApproved.
  ///
  /// In uz, this message translates to:
  /// **'Joylandi'**
  String get carStateApproved;

  /// No description provided for @carStateRejected.
  ///
  /// In uz, this message translates to:
  /// **'Rad etildi'**
  String get carStateRejected;

  /// No description provided for @carStateChanges.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgartirish kerak'**
  String get carStateChanges;

  /// No description provided for @carStateDraft.
  ///
  /// In uz, this message translates to:
  /// **'Qoralama'**
  String get carStateDraft;

  /// No description provided for @carEdit.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get carEdit;

  /// No description provided for @carMarkSold.
  ///
  /// In uz, this message translates to:
  /// **'Sotildi'**
  String get carMarkSold;

  /// No description provided for @carDelete.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirish'**
  String get carDelete;

  /// No description provided for @carSoldConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sotildi deb belgilash?'**
  String get carSoldConfirmTitle;

  /// No description provided for @carSoldConfirmBody.
  ///
  /// In uz, this message translates to:
  /// **'E’lon bozorda sotilgan sifatida ko‘rsatiladi.'**
  String get carSoldConfirmBody;

  /// No description provided for @carSoldConfirmYes.
  ///
  /// In uz, this message translates to:
  /// **'Ha, sotildi'**
  String get carSoldConfirmYes;

  /// No description provided for @carMarkedSold.
  ///
  /// In uz, this message translates to:
  /// **'Sotilgan deb belgilandi'**
  String get carMarkedSold;

  /// No description provided for @carDeleteConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni o‘chirish?'**
  String get carDeleteConfirmTitle;

  /// No description provided for @carDeleteConfirmBody.
  ///
  /// In uz, this message translates to:
  /// **'Bu amalni qaytarib bo‘lmaydi.'**
  String get carDeleteConfirmBody;

  /// No description provided for @carDeleted.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirildi'**
  String get carDeleted;

  /// No description provided for @carCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get carCancel;

  /// No description provided for @carSignInSellTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mashinangizni soting'**
  String get carSignInSellTitle;

  /// No description provided for @carSignInSellBody.
  ///
  /// In uz, this message translates to:
  /// **'E’lon joylash uchun akkauntga kiring.'**
  String get carSignInSellBody;

  /// No description provided for @carNewPostTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e’lon'**
  String get carNewPostTitle;

  /// No description provided for @carEditPostTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni tahrirlash'**
  String get carEditPostTitle;

  /// No description provided for @carPhotos.
  ///
  /// In uz, this message translates to:
  /// **'Rasmlar va video'**
  String get carPhotos;

  /// No description provided for @carPhotosHint.
  ///
  /// In uz, this message translates to:
  /// **'Birinchisi muqova bo‘ladi. Ko‘pi bilan 10 ta, har bir video ≤ 50MB.'**
  String get carPhotosHint;

  /// No description provided for @carPhotosLocked.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgandan keyin rasmlarni o‘zgartirib bo‘lmaydi.'**
  String get carPhotosLocked;

  /// No description provided for @carAddMedia.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘shish'**
  String get carAddMedia;

  /// No description provided for @carCover.
  ///
  /// In uz, this message translates to:
  /// **'Muqova'**
  String get carCover;

  /// No description provided for @carCarSection.
  ///
  /// In uz, this message translates to:
  /// **'Mashina'**
  String get carCarSection;

  /// No description provided for @carBrand.
  ///
  /// In uz, this message translates to:
  /// **'Marka'**
  String get carBrand;

  /// No description provided for @carModel.
  ///
  /// In uz, this message translates to:
  /// **'Model'**
  String get carModel;

  /// No description provided for @carPickBrandFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval markani tanlang'**
  String get carPickBrandFirst;

  /// No description provided for @carPickModelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Modelni tanlang'**
  String get carPickModelTitle;

  /// No description provided for @carOtherModel.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa model (qo‘lda)'**
  String get carOtherModel;

  /// No description provided for @carModelHint.
  ///
  /// In uz, this message translates to:
  /// **'masalan: Sonata'**
  String get carModelHint;

  /// No description provided for @carPickYear.
  ///
  /// In uz, this message translates to:
  /// **'Yilni tanlang'**
  String get carPickYear;

  /// No description provided for @carGenerationOptional.
  ///
  /// In uz, this message translates to:
  /// **'Avlod (ixtiyoriy)'**
  String get carGenerationOptional;

  /// No description provided for @carMileageLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yurgan masofasi (km)'**
  String get carMileageLabel;

  /// No description provided for @carFuelType.
  ///
  /// In uz, this message translates to:
  /// **'Yoqilg‘i turi'**
  String get carFuelType;

  /// No description provided for @carPriceSection.
  ///
  /// In uz, this message translates to:
  /// **'Narx va hujjatlar'**
  String get carPriceSection;

  /// No description provided for @carPriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Narxi (₩)'**
  String get carPriceLabel;

  /// No description provided for @carNegotiableSub.
  ///
  /// In uz, this message translates to:
  /// **'Xaridor bilan kelishish mumkin'**
  String get carNegotiableSub;

  /// No description provided for @carLegalLabel.
  ///
  /// In uz, this message translates to:
  /// **'Rasmiy holati'**
  String get carLegalLabel;

  /// No description provided for @carLegalNo.
  ///
  /// In uz, this message translates to:
  /// **'Nolegal'**
  String get carLegalNo;

  /// No description provided for @carRegQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Nomiga o‘tkazish kerakmi?'**
  String get carRegQuestion;

  /// No description provided for @carRegYes.
  ///
  /// In uz, this message translates to:
  /// **'Ha, kerak'**
  String get carRegYes;

  /// No description provided for @carPhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam'**
  String get carPhoneLabel;

  /// No description provided for @carContactHint.
  ///
  /// In uz, this message translates to:
  /// **'Kamida bittasini to‘ldiring.'**
  String get carContactHint;

  /// No description provided for @carDescription.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif'**
  String get carDescription;

  /// No description provided for @carDescriptionHint.
  ///
  /// In uz, this message translates to:
  /// **'Holati, butligi, almashtirilgan qismlar, sababi...'**
  String get carDescriptionHint;

  /// No description provided for @carSubmit.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rib chiqishga yuborish'**
  String get carSubmit;

  /// No description provided for @carSaveChanges.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get carSaveChanges;

  /// No description provided for @carRequiredMissing.
  ///
  /// In uz, this message translates to:
  /// **'Majburiy maydonlarni to‘ldiring'**
  String get carRequiredMissing;

  /// No description provided for @carChangesSaved.
  ///
  /// In uz, this message translates to:
  /// **'Saqlandi'**
  String get carChangesSaved;

  /// No description provided for @carSubmitted.
  ///
  /// In uz, this message translates to:
  /// **'Yuborildi! Admin tekshirgach e’loningiz joylanadi.'**
  String get carSubmitted;

  /// No description provided for @carUploading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda: {done} / {total}'**
  String carUploading(String done, String total);

  /// No description provided for @carVideoTooBig.
  ///
  /// In uz, this message translates to:
  /// **'Video 50MB dan katta'**
  String get carVideoTooBig;

  /// No description provided for @carMediaLimit.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘pi bilan 10 ta'**
  String get carMediaLimit;

  /// No description provided for @carNeedPhoto.
  ///
  /// In uz, this message translates to:
  /// **'Kamida bitta rasm qo‘shing'**
  String get carNeedPhoto;

  /// No description provided for @carDupTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bu mashina allaqachon e’lon qilingan'**
  String get carDupTitle;

  /// No description provided for @carDupBody.
  ///
  /// In uz, this message translates to:
  /// **'Shu raqam va shu mashina bilan e’lon bor. Bir xil e’lonni qayta joylab bo‘lmaydi.'**
  String get carDupBody;

  /// No description provided for @carDupOwn.
  ///
  /// In uz, this message translates to:
  /// **'Sizning e’loningiz'**
  String get carDupOwn;

  /// No description provided for @carOk.
  ///
  /// In uz, this message translates to:
  /// **'Tushunarli'**
  String get carOk;

  /// No description provided for @carChannelNudge.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e’lonlarni birinchi bo‘lib ko‘rish uchun @vegukin_car kanaliga a’zo bo‘ling'**
  String get carChannelNudge;

  /// No description provided for @hsTabBoard.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlar'**
  String get hsTabBoard;

  /// No description provided for @hsTabMine.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlarim'**
  String get hsTabMine;

  /// No description provided for @hsTabAlerts.
  ///
  /// In uz, this message translates to:
  /// **'Xabarnoma'**
  String get hsTabAlerts;

  /// No description provided for @hsTabPost.
  ///
  /// In uz, this message translates to:
  /// **'Joylash'**
  String get hsTabPost;

  /// No description provided for @hsSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Koreys tilida manzil yozsangiz, e’lonlar shu joyga yaqinligi bo‘yicha saralanadi.'**
  String get hsSearchHint;

  /// No description provided for @hsSearch.
  ///
  /// In uz, this message translates to:
  /// **'Izlash'**
  String get hsSearch;

  /// No description provided for @hsRecent.
  ///
  /// In uz, this message translates to:
  /// **'Eng yangi e’lonlar'**
  String get hsRecent;

  /// No description provided for @hsNearest.
  ///
  /// In uz, this message translates to:
  /// **'Yaqinlik bo‘yicha'**
  String get hsNearest;

  /// No description provided for @hsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta'**
  String hsCount(String count);

  /// No description provided for @hsCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get hsCancel;

  /// No description provided for @hsMore.
  ///
  /// In uz, this message translates to:
  /// **'Yana yuklash'**
  String get hsMore;

  /// No description provided for @hsAllShown.
  ///
  /// In uz, this message translates to:
  /// **'Barcha e’lonlar ko‘rsatildi'**
  String get hsAllShown;

  /// No description provided for @hsNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get hsNew;

  /// No description provided for @hsYours.
  ///
  /// In uz, this message translates to:
  /// **'Sizniki'**
  String get hsYours;

  /// No description provided for @hsSeeNumber.
  ///
  /// In uz, this message translates to:
  /// **'Raqamni ko‘rish'**
  String get hsSeeNumber;

  /// No description provided for @hsViaTelegram.
  ///
  /// In uz, this message translates to:
  /// **'Telegram orqali bog‘lanish'**
  String get hsViaTelegram;

  /// No description provided for @hsNoContact.
  ///
  /// In uz, this message translates to:
  /// **'Aloqa ma’lumoti yo‘q'**
  String get hsNoContact;

  /// No description provided for @hsEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha e’lon yo‘q'**
  String get hsEmptyTitle;

  /// No description provided for @hsEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi bo‘lib e’lon joylang — pastdagi «Joylash» tugmasini bosing.'**
  String get hsEmptyBody;

  /// No description provided for @hsPostAd.
  ///
  /// In uz, this message translates to:
  /// **'E’lon joylash'**
  String get hsPostAd;

  /// No description provided for @hsGeoTitle.
  ///
  /// In uz, this message translates to:
  /// **'Manzil topilmadi'**
  String get hsGeoTitle;

  /// No description provided for @hsGeoBody.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni koreys tilida, to‘liqroq yozib ko‘ring:'**
  String get hsGeoBody;

  /// No description provided for @hsRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get hsRetry;

  /// No description provided for @hsLoadFailedTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlarni yuklab bo‘lmadi'**
  String get hsLoadFailedTitle;

  /// No description provided for @hsLoadFailedBody.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasini tekshiring va qayta urinib ko‘ring.'**
  String get hsLoadFailedBody;

  /// No description provided for @hsOpenFailedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ochib bo‘lmadi'**
  String get hsOpenFailedTitle;

  /// No description provided for @hsOpenFailedBody.
  ///
  /// In uz, this message translates to:
  /// **'Bu e’lon o‘chirilgan yoki muddati tugagan bo‘lishi mumkin.'**
  String get hsOpenFailedBody;

  /// No description provided for @hsCopy.
  ///
  /// In uz, this message translates to:
  /// **'Nusxalash'**
  String get hsCopy;

  /// No description provided for @hsNoPhone.
  ///
  /// In uz, this message translates to:
  /// **'Tel raqam ko‘rsatilmagan.'**
  String get hsNoPhone;

  /// No description provided for @hsEdit.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get hsEdit;

  /// No description provided for @hsDelete.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirish'**
  String get hsDelete;

  /// No description provided for @hsCopied.
  ///
  /// In uz, this message translates to:
  /// **'Raqam nusxalab olindi'**
  String get hsCopied;

  /// No description provided for @hsDeleteConfirm.
  ///
  /// In uz, this message translates to:
  /// **'E’lon o‘chirilsinmi? Buni qaytarib bo‘lmaydi.'**
  String get hsDeleteConfirm;

  /// No description provided for @hsDeleted.
  ///
  /// In uz, this message translates to:
  /// **'E’lon o‘chirildi'**
  String get hsDeleted;

  /// No description provided for @hsMineTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mening e’lonlarim'**
  String get hsMineTitle;

  /// No description provided for @hsMineSub.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlar 30 kundan keyin ro‘yxatdan olinadi. Muddat tugashidan oldin shu yerdan uzaytiring.'**
  String get hsMineSub;

  /// No description provided for @hsActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get hsActive;

  /// No description provided for @hsExpired.
  ///
  /// In uz, this message translates to:
  /// **'Muddati tugagan'**
  String get hsExpired;

  /// No description provided for @hsDaysLeft.
  ///
  /// In uz, this message translates to:
  /// **'{count} kun qoldi'**
  String hsDaysLeft(String count);

  /// No description provided for @hsHidden.
  ///
  /// In uz, this message translates to:
  /// **'Ro‘yxatda ko‘rinmaydi'**
  String get hsHidden;

  /// No description provided for @hsExtend.
  ///
  /// In uz, this message translates to:
  /// **'Uzaytirish'**
  String get hsExtend;

  /// No description provided for @hsExtended.
  ///
  /// In uz, this message translates to:
  /// **'Muddat yana {count} kunga uzaytirildi'**
  String hsExtended(String count);

  /// No description provided for @hsMineEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizda e’lon yo‘q'**
  String get hsMineEmptyTitle;

  /// No description provided for @hsMineEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Joylagan e’lonlaringiz shu yerda ko‘rinadi.'**
  String get hsMineEmptyBody;

  /// No description provided for @hsFailedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab bo‘lmadi'**
  String get hsFailedTitle;

  /// No description provided for @hsFailedBody.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinib ko‘ring.'**
  String get hsFailedBody;

  /// No description provided for @hsNewTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e’lon'**
  String get hsNewTitle;

  /// No description provided for @hsEditTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni tahrirlash'**
  String get hsEditTitle;

  /// No description provided for @hsComposeSub.
  ///
  /// In uz, this message translates to:
  /// **'Manzil, telefon raqami va qisqa tavsif kifoya'**
  String get hsComposeSub;

  /// No description provided for @hsAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get hsAddress;

  /// No description provided for @hsRequired.
  ///
  /// In uz, this message translates to:
  /// **'majburiy'**
  String get hsRequired;

  /// No description provided for @hsAddressHint.
  ///
  /// In uz, this message translates to:
  /// **'Koreys tilida yozing. Manzil keyin o‘zgartirilmaydi.'**
  String get hsAddressHint;

  /// No description provided for @hsAddressLocked.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni o‘zgartirib bo‘lmaydi. Xato bo‘lsa, e’lonni o‘chirib, yangisini joylang.'**
  String get hsAddressLocked;

  /// No description provided for @hsPhone.
  ///
  /// In uz, this message translates to:
  /// **'Bog‘lanish uchun telefon raqam'**
  String get hsPhone;

  /// No description provided for @hsContactHint.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami yoki Telegram — kamida bittasi ko‘rsatilishi shart.'**
  String get hsContactHint;

  /// No description provided for @hsTelegramOptIn.
  ///
  /// In uz, this message translates to:
  /// **'Telegram orqali bog‘lanish'**
  String get hsTelegramOptIn;

  /// No description provided for @hsYourUsername.
  ///
  /// In uz, this message translates to:
  /// **'Sizning username: {name}'**
  String hsYourUsername(String name);

  /// No description provided for @hsBody.
  ///
  /// In uz, this message translates to:
  /// **'E’lon matni'**
  String get hsBody;

  /// No description provided for @hsBodyHint.
  ///
  /// In uz, this message translates to:
  /// **'Ijara haqi, depozit, boshlanish sanasi, muddati va boshqa shartlarni yozing. Masalan: oyiga 500,000 won, depozit 5,000,000 won, avgust oyidan boshlab, kamida olti oyga. Kommunal alohida.'**
  String get hsBodyHint;

  /// No description provided for @hsSubmit.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni joylash'**
  String get hsSubmit;

  /// No description provided for @hsSave.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgarishlarni saqlash'**
  String get hsSave;

  /// No description provided for @hsSaved.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgarishlar saqlandi'**
  String get hsSaved;

  /// No description provided for @hsPosted.
  ///
  /// In uz, this message translates to:
  /// **'E’loningiz joylandi'**
  String get hsPosted;

  /// No description provided for @hsErrUsername.
  ///
  /// In uz, this message translates to:
  /// **'5-32 belgi: harflar, raqamlar va pastki chiziq. Harf bilan boshlansin.'**
  String get hsErrUsername;

  /// No description provided for @hsErrContactRequired.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami yoki Telegram — kamida bittasini ko‘rsating.'**
  String get hsErrContactRequired;

  /// No description provided for @hsErrAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni koreys tilida, to‘liq yozing.'**
  String get hsErrAddress;

  /// No description provided for @hsErrPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamini to‘g‘ri yozing.'**
  String get hsErrPhone;

  /// No description provided for @hsErrBody.
  ///
  /// In uz, this message translates to:
  /// **'Matn kamida 20 ta belgidan iborat bo‘lsin.'**
  String get hsErrBody;

  /// No description provided for @hsErrUsernameEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Username yozing yoki belgini olib tashlang.'**
  String get hsErrUsernameEmpty;

  /// No description provided for @hsErrGeocode.
  ///
  /// In uz, this message translates to:
  /// **'Manzil topilmadi. To‘liqroq yozib ko‘ring.'**
  String get hsErrGeocode;

  /// No description provided for @hsAlertsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get hsAlertsTitle;

  /// No description provided for @hsAlertsSub.
  ///
  /// In uz, this message translates to:
  /// **'Manzil va qidiruv radiusini kiriting. Shu radius ichida yangi e’lon qo‘yilsa, darhol xabar beramiz.'**
  String get hsAlertsSub;

  /// No description provided for @hsRadius.
  ///
  /// In uz, this message translates to:
  /// **'Qidiruv radiusi: shu masofadagi barcha e’lonlar'**
  String get hsRadius;

  /// No description provided for @hsRadiusCustom.
  ///
  /// In uz, this message translates to:
  /// **'Yoki o‘zingiz kiriting'**
  String get hsRadiusCustom;

  /// No description provided for @hsAdd.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘shish'**
  String get hsAdd;

  /// No description provided for @hsErrRadius.
  ///
  /// In uz, this message translates to:
  /// **'Doira 1 km dan 500 km gacha bo‘lsin.'**
  String get hsErrRadius;

  /// No description provided for @hsAlertOff.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirilgan — botni bloklagansiz'**
  String get hsAlertOff;

  /// No description provided for @hsAlertSent.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta xabar yuborilgan'**
  String hsAlertSent(String count);

  /// No description provided for @hsAlertDeleteConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Bu bildirishnoma o‘chirilsinmi?'**
  String get hsAlertDeleteConfirm;

  /// No description provided for @hsAlertAdded.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnoma qo‘shildi'**
  String get hsAlertAdded;

  /// No description provided for @hsAlertDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnoma o‘chirildi'**
  String get hsAlertDeleted;

  /// No description provided for @hsAlertsEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bildirishnoma yo‘q'**
  String get hsAlertsEmptyTitle;

  /// No description provided for @hsAlertsEmptyBody.
  ///
  /// In uz, this message translates to:
  /// **'Yuqorida manzil yozib, qidiruv radiusini tanlang. Istalgancha bildirishnoma qo‘shishingiz mumkin.'**
  String get hsAlertsEmptyBody;

  /// No description provided for @hsSignInPostTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lon joylash uchun akkauntga kiring'**
  String get hsSignInPostTitle;

  /// No description provided for @hsSignInPostBody.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlarni ko‘rish va raqamlarni ochish uchun kirish shart emas.'**
  String get hsSignInPostBody;

  /// No description provided for @hsSignInAlertsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e’lon chiqsa, xabar beramiz'**
  String get hsSignInAlertsTitle;

  /// No description provided for @hsSignInAlertsBody.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnoma uchun akkauntga kiring. Telefoningizga keladi.'**
  String get hsSignInAlertsBody;

  /// No description provided for @hsSignIn.
  ///
  /// In uz, this message translates to:
  /// **'Akkauntga kirish'**
  String get hsSignIn;

  /// No description provided for @hsErrForbidden.
  ///
  /// In uz, this message translates to:
  /// **'Bu e’lon sizniki emas.'**
  String get hsErrForbidden;

  /// No description provided for @hsErrNotFound.
  ///
  /// In uz, this message translates to:
  /// **'E’lon topilmadi.'**
  String get hsErrNotFound;

  /// No description provided for @hsErrGone.
  ///
  /// In uz, this message translates to:
  /// **'E’lon o‘chirilgan yoki muddati tugagan.'**
  String get hsErrGone;

  /// No description provided for @hsErrGeoUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Manzil xizmati javob bermayapti. Birozdan keyin urinib ko‘ring.'**
  String get hsErrGeoUnavailable;

  /// No description provided for @hsErrUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat vaqtincha ishlamayapti.'**
  String get hsErrUnavailable;

  /// No description provided for @hsErrServer.
  ///
  /// In uz, this message translates to:
  /// **'Serverda xatolik yuz berdi.'**
  String get hsErrServer;

  /// No description provided for @hsErrRateSeconds.
  ///
  /// In uz, this message translates to:
  /// **'Juda ko‘p urinish. {count} soniyadan keyin qayta urining.'**
  String hsErrRateSeconds(String count);

  /// No description provided for @hsErrRateMinutes.
  ///
  /// In uz, this message translates to:
  /// **'Juda ko‘p urinish. {count} daqiqadan keyin qayta urining.'**
  String hsErrRateMinutes(String count);

  /// No description provided for @hsErrNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Serverga ulanib bo‘lmadi. Qayta urinib ko‘ring.'**
  String get hsErrNetwork;

  /// No description provided for @hsErrGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi.'**
  String get hsErrGeneric;

  /// No description provided for @hsSending.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilmoqda…'**
  String get hsSending;

  /// No description provided for @jbTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ish e’lonlari guruhi'**
  String get jbTitle;

  /// No description provided for @jbSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Bot foydalanuvchilari uchun maxsus xizmat'**
  String get jbSubtitle;

  /// No description provided for @jbBotDoes.
  ///
  /// In uz, this message translates to:
  /// **'Bot tomonidan:'**
  String get jbBotDoes;

  /// No description provided for @jbPoint1.
  ///
  /// In uz, this message translates to:
  /// **'50 dan ortiq ish e’lon guruhlari sizning o‘rningizga kunda 24 soat kuzatib boriladi'**
  String get jbPoint1;

  /// No description provided for @jbPoint2.
  ///
  /// In uz, this message translates to:
  /// **'Faqat ish bilan bog‘liq bo‘lgan e’lonlar ajratib olinadi'**
  String get jbPoint2;

  /// No description provided for @jbPoint3.
  ///
  /// In uz, this message translates to:
  /// **'Barcha ajratib olingan e’lonlar shu zahoti “Ish e’lonlari” guruhida e’lon qilib boriladi'**
  String get jbPoint3;

  /// No description provided for @jbGetLink.
  ///
  /// In uz, this message translates to:
  /// **'Guruh linkini olish'**
  String get jbGetLink;

  /// No description provided for @jbLinkNote.
  ///
  /// In uz, this message translates to:
  /// **'Havola faqat siz uchun yaratiladi va 15 soniya amal qiladi'**
  String get jbLinkNote;

  /// No description provided for @jbLinkLoading.
  ///
  /// In uz, this message translates to:
  /// **'Link yaratilmoqda…'**
  String get jbLinkLoading;

  /// No description provided for @jbSecondsLeft.
  ///
  /// In uz, this message translates to:
  /// **'soniya qoldi'**
  String get jbSecondsLeft;

  /// No description provided for @jbYourLink.
  ///
  /// In uz, this message translates to:
  /// **'Sizning havolangiz:'**
  String get jbYourLink;

  /// No description provided for @jbJoin.
  ///
  /// In uz, this message translates to:
  /// **'Guruhga qo‘shilish'**
  String get jbJoin;

  /// No description provided for @jbLinkWarning.
  ///
  /// In uz, this message translates to:
  /// **'Diqqat! Havola faqat 15 soniya davomida amal qiladi. Shoshiling!'**
  String get jbLinkWarning;

  /// No description provided for @jbExpiredTitle.
  ///
  /// In uz, this message translates to:
  /// **'Havola muddati tugadi'**
  String get jbExpiredTitle;

  /// No description provided for @jbExpiredBody.
  ///
  /// In uz, this message translates to:
  /// **'Yangi havola olish uchun quyidagi tugmani bosing'**
  String get jbExpiredBody;

  /// No description provided for @jbRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get jbRetry;

  /// No description provided for @jbErrorTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi'**
  String get jbErrorTitle;

  /// No description provided for @jbLinkError.
  ///
  /// In uz, this message translates to:
  /// **'Link yaratishda xatolik.'**
  String get jbLinkError;

  /// No description provided for @jbCopied.
  ///
  /// In uz, this message translates to:
  /// **'Nusxa olindi'**
  String get jbCopied;

  /// No description provided for @jbPost.
  ///
  /// In uz, this message translates to:
  /// **'E’lon joylash'**
  String get jbPost;

  /// No description provided for @jbMyPosts.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlarim'**
  String get jbMyPosts;

  /// No description provided for @jbNewPost.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e’lon'**
  String get jbNewPost;

  /// No description provided for @jbHowTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bu qanday ishlaydi?'**
  String get jbHowTitle;

  /// No description provided for @jbHow1.
  ///
  /// In uz, this message translates to:
  /// **'Ish e’loningizni yozing va komissiya turini tanlang'**
  String get jbHow1;

  /// No description provided for @jbHow2.
  ///
  /// In uz, this message translates to:
  /// **'E’loningiz faqat bot guruhiga joylanadi. Foydalanuvchilar siz bilan tez orada bog‘lanishadi'**
  String get jbHow2;

  /// No description provided for @jbHow3.
  ///
  /// In uz, this message translates to:
  /// **'Odam topilgach, e’lonni “Band” deb belgilang'**
  String get jbHow3;

  /// No description provided for @jbHowCommission.
  ///
  /// In uz, this message translates to:
  /// **'Komissiya ixtiyoriy — o‘zingiz tanlaysiz. Tanlasangiz, ishni olgan har bir kishi sizga bir martalik 10,000 KRW to‘laydi'**
  String get jbHowCommission;

  /// No description provided for @jbHowRule.
  ///
  /// In uz, this message translates to:
  /// **'Sharti: E’lon faqat bot guruhida e’lon qilinib, boshqa guruhlarga joylanmasligi kerak'**
  String get jbHowRule;

  /// No description provided for @jbHowWait.
  ///
  /// In uz, this message translates to:
  /// **'Agar 2-3 soat ichida odam topilmasa, boshqa guruhlarda e’lon qilishingiz mumkin'**
  String get jbHowWait;

  /// No description provided for @jbEditing.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni tahrirlash'**
  String get jbEditing;

  /// No description provided for @jbCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get jbCancel;

  /// No description provided for @jbText.
  ///
  /// In uz, this message translates to:
  /// **'E’lon matni'**
  String get jbText;

  /// No description provided for @jbContact.
  ///
  /// In uz, this message translates to:
  /// **'Bog‘lanish uchun'**
  String get jbContact;

  /// No description provided for @jbRequired.
  ///
  /// In uz, this message translates to:
  /// **'majburiy'**
  String get jbRequired;

  /// No description provided for @jbContactManual.
  ///
  /// In uz, this message translates to:
  /// **'Yoki telefon raqamni kiritish'**
  String get jbContactManual;

  /// No description provided for @jbContactBack.
  ///
  /// In uz, this message translates to:
  /// **'Telegram username ishlatish'**
  String get jbContactBack;

  /// No description provided for @jbContactHint.
  ///
  /// In uz, this message translates to:
  /// **'Tel raqam yoki Telegram username kiriting'**
  String get jbContactHint;

  /// No description provided for @jbCommission.
  ///
  /// In uz, this message translates to:
  /// **'Komissiya'**
  String get jbCommission;

  /// No description provided for @jbCommissionPick.
  ///
  /// In uz, this message translates to:
  /// **'tanlang'**
  String get jbCommissionPick;

  /// No description provided for @jbWithCommission.
  ///
  /// In uz, this message translates to:
  /// **'Komissiyali'**
  String get jbWithCommission;

  /// No description provided for @jbWithCommissionBody.
  ///
  /// In uz, this message translates to:
  /// **'Ishni olgan har bir kishi sizga bir martalik 10,000 KRW to‘laydi.'**
  String get jbWithCommissionBody;

  /// No description provided for @jbNoCommission.
  ///
  /// In uz, this message translates to:
  /// **'Komissiyasiz'**
  String get jbNoCommission;

  /// No description provided for @jbFree.
  ///
  /// In uz, this message translates to:
  /// **'Bepul'**
  String get jbFree;

  /// No description provided for @jbNoCommissionBody.
  ///
  /// In uz, this message translates to:
  /// **'Hech qanday to‘lov talab qilinmaydi — faqat e’lon joylanadi.'**
  String get jbNoCommissionBody;

  /// No description provided for @jbPreview.
  ///
  /// In uz, this message translates to:
  /// **'E’lon ostida shunday ko‘rinadi:'**
  String get jbPreview;

  /// No description provided for @jbFootYes.
  ///
  /// In uz, this message translates to:
  /// **'👉 Bu e’lon faqat shu guruhga qo‘yildi.\n👉 Ishga qatnashgan har bir kishi ish egasiga bir martalik komissiyani: 10,000 KRW ish haqini olish vaqtida to‘laydi.\n👉 E’lon egasiga murojaat qilish orqali siz ushbu to‘lovga rozilik bildirasiz.'**
  String get jbFootYes;

  /// No description provided for @jbFootNo.
  ///
  /// In uz, this message translates to:
  /// **'👉 Bu e’lon faqat shu guruhga qo‘yildi.\n👉 Bu e’lon uchun hech qanday komissiya olinmaydi.'**
  String get jbFootNo;

  /// No description provided for @jbAgree.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu xabar ish bilan bog‘liq e’lonligini tasdiqlayman va boshqa Telegram guruhlarga 2-3 soat ichida joylamayman.'**
  String get jbAgree;

  /// No description provided for @jbSubmit.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni joylash'**
  String get jbSubmit;

  /// No description provided for @jbSave.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgarishlarni saqlash'**
  String get jbSave;

  /// No description provided for @jbBanWarning.
  ///
  /// In uz, this message translates to:
  /// **'Reklama, shaxsiy xabarlar yoki ish bilan bog‘liq bo‘lmagan e’lonlar davomiy qo‘ygan foydalanuvchi bloklanadi.'**
  String get jbBanWarning;

  /// No description provided for @jbSending.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yuborilmoqda…'**
  String get jbSending;

  /// No description provided for @jbSaving.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgarishlar saqlanmoqda…'**
  String get jbSaving;

  /// No description provided for @jbSentTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yuborildi!'**
  String get jbSentTitle;

  /// No description provided for @jbSentBody.
  ///
  /// In uz, this message translates to:
  /// **'E’loningiz guruhga muvaffaqiyatli joylandi.'**
  String get jbSentBody;

  /// No description provided for @jbSavedTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yangilandi!'**
  String get jbSavedTitle;

  /// No description provided for @jbSavedBody.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgarishlar guruhdagi xabarga ham qo‘llanildi.'**
  String get jbSavedBody;

  /// No description provided for @jbChipCommission.
  ///
  /// In uz, this message translates to:
  /// **'Komissiyali e’lon — 10,000 KRW'**
  String get jbChipCommission;

  /// No description provided for @jbChipFree.
  ///
  /// In uz, this message translates to:
  /// **'Komissiyasiz e’lon'**
  String get jbChipFree;

  /// No description provided for @jbPostAgain.
  ///
  /// In uz, this message translates to:
  /// **'Yana e’lon joylash'**
  String get jbPostAgain;

  /// No description provided for @jbPostError.
  ///
  /// In uz, this message translates to:
  /// **'E’lon yuborishda xatolik.'**
  String get jbPostError;

  /// No description provided for @jbEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hali e’lon joylamadingiz'**
  String get jbEmptyTitle;

  /// No description provided for @jbEmptyAction.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi e’lonni joylash'**
  String get jbEmptyAction;

  /// No description provided for @jbHintText.
  ///
  /// In uz, this message translates to:
  /// **'E’lon matni kamida 10 belgi bo‘lishi kerak'**
  String get jbHintText;

  /// No description provided for @jbHintContact.
  ///
  /// In uz, this message translates to:
  /// **'Bog‘lanish uchun kontakt ma’lumotini kiriting'**
  String get jbHintContact;

  /// No description provided for @jbHintCommission.
  ///
  /// In uz, this message translates to:
  /// **'Komissiya turini tanlang'**
  String get jbHintCommission;

  /// No description provided for @jbHintAgree.
  ///
  /// In uz, this message translates to:
  /// **'Qoidalarga rozilik belgisini qo‘ying'**
  String get jbHintAgree;

  /// No description provided for @jbActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get jbActive;

  /// No description provided for @jbReserved.
  ///
  /// In uz, this message translates to:
  /// **'Band'**
  String get jbReserved;

  /// No description provided for @jbFinished.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get jbFinished;

  /// No description provided for @jbReserve.
  ///
  /// In uz, this message translates to:
  /// **'Band qilish'**
  String get jbReserve;

  /// No description provided for @jbReopen.
  ///
  /// In uz, this message translates to:
  /// **'Faol qilish'**
  String get jbReopen;

  /// No description provided for @jbFinish.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlash'**
  String get jbFinish;

  /// No description provided for @jbDone.
  ///
  /// In uz, this message translates to:
  /// **'Ish bajarildi'**
  String get jbDone;

  /// No description provided for @jbEdit.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get jbEdit;

  /// No description provided for @jbDelete.
  ///
  /// In uz, this message translates to:
  /// **'O‘chirish'**
  String get jbDelete;

  /// No description provided for @jbFinishIn.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlash uchun: {hours} soat {minutes} daq. qoldi'**
  String jbFinishIn(int hours, int minutes);

  /// No description provided for @jbReserveText.
  ///
  /// In uz, this message translates to:
  /// **'Ishchi topildimi? E’lonni band sifatida belgilashni xohlaysizmi?'**
  String get jbReserveText;

  /// No description provided for @jbReopenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qayta faollashtirish'**
  String get jbReopenTitle;

  /// No description provided for @jbReopenText.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni qayta faol holatga o‘tkazmoqchimisiz?'**
  String get jbReopenText;

  /// No description provided for @jbFinishText.
  ///
  /// In uz, this message translates to:
  /// **'Ish bajarildi deb belgilamoqchimisiz? Bu qaytarib bo‘lmaydi.'**
  String get jbFinishText;

  /// No description provided for @jbDeleteTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lonni o‘chirish'**
  String get jbDeleteTitle;

  /// No description provided for @jbDeleteText.
  ///
  /// In uz, this message translates to:
  /// **'E’lon guruhdan ham, ro‘yxatingizdan ham butunlay o‘chiriladi. Davom etasizmi?'**
  String get jbDeleteText;

  /// No description provided for @jbYes.
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get jbYes;

  /// No description provided for @jbJustNow.
  ///
  /// In uz, this message translates to:
  /// **'hozirgina'**
  String get jbJustNow;

  /// No description provided for @jbMinutesAgo.
  ///
  /// In uz, this message translates to:
  /// **'{n} daq. oldin'**
  String jbMinutesAgo(int n);

  /// No description provided for @jbHoursAgo.
  ///
  /// In uz, this message translates to:
  /// **'{n} soat oldin'**
  String jbHoursAgo(int n);

  /// No description provided for @jbDaysAgo.
  ///
  /// In uz, this message translates to:
  /// **'{n} kun oldin'**
  String jbDaysAgo(int n);

  /// No description provided for @jbErrNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Tarmoq xatosi. Qayta urinib ko‘ring.'**
  String get jbErrNetwork;

  /// No description provided for @jbSignInTitle.
  ///
  /// In uz, this message translates to:
  /// **'E’lon joylash uchun kiring'**
  String get jbSignInTitle;

  /// No description provided for @jbSignInBody.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlaringiz akkauntingizga bog‘lanadi: keyin ularni band qilish, tahrirlash yoki o‘chirish mumkin.'**
  String get jbSignInBody;

  /// No description provided for @jbSignIn.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get jbSignIn;

  /// No description provided for @jbLoadFailed.
  ///
  /// In uz, this message translates to:
  /// **'E’lonlarni yuklab bo‘lmadi'**
  String get jbLoadFailed;
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
