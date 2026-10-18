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
  String get exactAlarmsTitle => 'Exact timing';

  @override
  String get exactAlarmsBody =>
      'So prayer reminders and the home-screen widget fire right on time, turn on “Alarms & reminders” on the next page.';

  @override
  String get exactAlarmsAllow => 'Continue';

  @override
  String get exactAlarmsLater => 'Not now';

  @override
  String get prayersTitle => 'Prayer times';

  @override
  String get nextPrayer => 'Next prayer';

  @override
  String get remaining => 'remaining';

  @override
  String get suhoorLabel => 'Suhoor (ends)';

  @override
  String get iftarLabel => 'Iftar';

  @override
  String get chipNow => 'now';

  @override
  String get chipNext => 'next';

  @override
  String get fastWindow => 'Fasting window · suhoor to iftar';

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get backToToday => 'Back to today';

  @override
  String get dayLoading => 'Loading...';

  @override
  String get dayLoadFailed => 'Could not load';

  @override
  String get commentFajr => 'Isha time ends';

  @override
  String get commentSunrise => 'Fajr time ends';

  @override
  String get commentAsr => 'Dhuhr time ends';

  @override
  String get commentMaghrib => 'Asr time ends';

  @override
  String get commentIsha => 'Maghrib time ends';

  @override
  String get settingsShort => 'Settings';

  @override
  String get settingsTitle => 'Prayer settings';

  @override
  String get settingsSubtitle => 'Choose your calculation method and madhab';

  @override
  String get methodLabel => 'Calculation method';

  @override
  String get madhabLabel => 'Madhab (for Asr time)';

  @override
  String get schoolHanafi => 'Hanafi';

  @override
  String get schoolShafii => 'Shafi’i / Maliki / Hanbali';

  @override
  String get schoolShafiiShort => 'Shafi’i';

  @override
  String get hanafiNote => 'Shadow = 2x length';

  @override
  String get shafiiNote => 'Shadow = 1x length';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodKarachi => 'Karachi';

  @override
  String get methodMakkah => 'Makkah';

  @override
  String get methodEgypt => 'Egypt';

  @override
  String get methodIsna => 'ISNA';

  @override
  String get methodMwlHint => 'Fajr 18°, Isha 17°';

  @override
  String get methodKarachiHint => 'Fajr 18°, Isha 18°';

  @override
  String get methodMakkahHint => 'Fajr 18.5°, Isha - 90 min after Maghrib';

  @override
  String get methodEgyptHint => 'Fajr 19.5°, Isha 17.5°';

  @override
  String get methodIsnaHint => 'Fajr 15°, Isha 15°';

  @override
  String get naflTitle => 'Times of voluntary (nafl) prayers';

  @override
  String get tahajjudName => 'Tahajjud prayer';

  @override
  String get tahajjudText =>
      'Performed after the Isha prayer, following sleep. Its minimum is 2 rak‘ahs and its maximum is 8 rak‘ahs. The most virtuous time is the last third of the night - a time when supplications are accepted.';

  @override
  String get tahajjudQuote =>
      'It brings one closer to your Lord, expiates bad deeds, and prevents sins.';

  @override
  String get tahajjudSource => 'Source: Tirmidhi - from Abu Umoma (r.a.)';

  @override
  String get ishraqName => 'Shuruq (Ishraq) prayer';

  @override
  String get ishraqQuote =>
      'Whoever prays Fajr in congregation, remains in remembrance of Allah until sunrise, then prays two rak‘ahs - receives the full reward of Hajj and Umrah.';

  @override
  String get ishraqSource =>
      'Source: Tirmidhi - from Mu‘adh ibn Anas al-Juhani (r.a.)';

  @override
  String get duhaName => 'Duha prayer';

  @override
  String get duhaText =>
      'When the sun rises to the height of a spear, it begins and continues until one hour remains before noon. It is most virtuous to pray 4 rak‘ahs. The most preferable time is after one quarter of the morning has passed.';

  @override
  String get duhaQuote =>
      'Whoever consistently performs the Duha (forenoon) prayer, his sins will be forgiven even if they are as abundant as the foam of the sea.';

  @override
  String get duhaSource => 'Source: Tirmidhi - from Abu Hurayra (r.a.)';

  @override
  String get statusNow => 'Now';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusPassed => 'Passed';

  @override
  String get statusOtherDay => 'Other day';

  @override
  String get reminderHint => 'Tap a bell to set that prayer’s reminder';

  @override
  String reminderFor(String name) {
    return '$name reminder';
  }

  @override
  String reminderToday(String range) {
    return 'Today: $range';
  }

  @override
  String get reminderHow => 'How to remind';

  @override
  String get reminderWhen => 'When';

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderOffHint => 'No reminder';

  @override
  String get reminderSilent => 'Silent';

  @override
  String get reminderSilentHint => 'Notification only';

  @override
  String get reminderVibrate => 'Vibrate';

  @override
  String get reminderVibrateHint => 'No sound';

  @override
  String get reminderSound => 'Sound';

  @override
  String get reminderSoundHint => 'A short, soft chime';

  @override
  String get reminderPlay => 'Play';

  @override
  String get reminderAt => 'Reminder at';

  @override
  String get reminderDone => 'Done';

  @override
  String get offsetOnTime => 'On time';

  @override
  String offsetBefore(String duration) {
    return '$duration before';
  }

  @override
  String offsetAfter(String duration) {
    return '$duration after';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get notificationsOff =>
      'Notifications are off, so reminders won’t arrive';

  @override
  String get notificationsTurnOn => 'Turn on';

  @override
  String notifyAt(String name) {
    return 'It’s time for $name';
  }

  @override
  String notifyBefore(String name, String duration) {
    return '$name in $duration';
  }

  @override
  String notifyAfter(String name, String duration) {
    return '$name began $duration ago';
  }

  @override
  String get notifySunriseAt => 'Sunrise: Fajr time has ended';

  @override
  String notifySunriseBefore(String duration) {
    return 'Fajr ends in $duration';
  }

  @override
  String notifySunriseAfter(String duration) {
    return 'Sunrise was $duration ago';
  }

  @override
  String get notifyImsakAt => 'Suhoor time has ended';

  @override
  String notifyImsakBefore(String duration) {
    return 'Suhoor ends in $duration';
  }

  @override
  String notifyImsakAfter(String duration) {
    return 'Suhoor ended $duration ago';
  }

  @override
  String notifyBody(String name, String start, String end, String city) {
    return '$name: $start – $end · $city';
  }

  @override
  String get suhoorShort => 'Suhoor';
}
