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
