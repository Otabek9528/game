// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'For Muslims in Korea';

  @override
  String get greetingLabel => 'Peace be upon you';

  @override
  String get languageQuestion => 'Which language suits you?';

  @override
  String get languageNote => 'Some sections are in Uzbek only for now';

  @override
  String get continueAction => 'Continue';

  @override
  String get saveAction => 'Save';

  @override
  String get changeLaterHint => 'You can change this later in Settings';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get untilFajr => 'Until Fajr';

  @override
  String get untilFajrEnds => 'Until Fajr ends';

  @override
  String get untilDhuhr => 'Until Dhuhr';

  @override
  String get untilAsr => 'Until Asr';

  @override
  String get untilMaghrib => 'Until Maghrib';

  @override
  String get untilIsha => 'Until Isha';

  @override
  String get locationPlaceholder => 'Location';

  @override
  String get locating => 'Locating…';

  @override
  String get locationJustNow => 'Just now';

  @override
  String locationMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String locationHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String locationDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get locationFailedShort => 'Couldn’t locate';

  @override
  String get refreshLocation => 'Update location';

  @override
  String get locationNeededTitle => 'Prayer times need your location';

  @override
  String get locationNeededBody =>
      'Times are calculated for your city. Your location is used only for this.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get locationDeniedBody =>
      'This app isn’t allowed to use your location. Turn it on in the app settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get locationOffBody => 'Location (GPS) is turned off on your phone.';

  @override
  String get turnOnLocation => 'Turn on';

  @override
  String get locationFailedBody => 'Couldn’t find your location.';

  @override
  String get timesFailedBody =>
      'Couldn’t load prayer times. Check your connection.';

  @override
  String get retry => 'Try again';

  @override
  String get newBadge => 'New';

  @override
  String get uzOnlyHint => 'Uzbek only';

  @override
  String get featurePrayers => 'Prayer times';

  @override
  String get featureMosques => 'Mosques';

  @override
  String get featureRestaurants => 'Restaurants';

  @override
  String get featureShops => 'Shops';

  @override
  String get featureNotifications => 'Notifications';

  @override
  String get featureQibla => 'Qibla';

  @override
  String get featureQna => 'Ask the scholars';

  @override
  String get featureBarcode => 'Ingredient check';

  @override
  String get featureHousing => 'Housing';

  @override
  String get featureCars => 'Vegukin Cars';

  @override
  String get featureHikorea => 'Immigration services';

  @override
  String get featureJobs => 'Jobs';

  @override
  String get featureParcel => 'Parcels';

  @override
  String get featureLinks => 'Useful links';

  @override
  String get featureDonation => 'Support us';

  @override
  String get featureCommunity => 'Community';

  @override
  String get featureBusiness => 'Business Directory';

  @override
  String get businessTagline => 'Uzbek businesses in Korea';

  @override
  String businessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count businesses',
      one: '1 business',
    );
    return '$_temp0';
  }

  @override
  String categoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String get webLoadFailed => 'Couldn’t open this page. Check your connection.';

  @override
  String get webReload => 'Reload';

  @override
  String get webOpenInBrowser => 'Open in browser';

  @override
  String get cameraDenied => 'Camera access is off for this app';

  @override
  String get widgetOpenApp => 'Open the app to see prayer times';

  @override
  String get exactAlarmsTitle => 'Keep the widget on time';

  @override
  String get exactAlarmsBody =>
      'To let the widget switch to the next prayer right on time, turn on “Alarms & reminders”.';

  @override
  String get exactAlarmsAllow => 'Turn on';

  @override
  String get exactAlarmsLater => 'Not now';
}
