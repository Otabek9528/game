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

  @override
  String get qiblaTitle => 'Qibla direction';

  @override
  String get qiblaPreparing => 'Preparing compass...';

  @override
  String get qiblaHoldFlat => 'Hold your device flat';

  @override
  String get qiblaHoldFlatShort => 'Hold your phone flat';

  @override
  String get qiblaNoLocation =>
      'Your location is needed to work out the Qibla.';

  @override
  String get qiblaNoCompassTitle => 'No compass';

  @override
  String get qiblaNoCompass => 'This device does not have a compass sensor.';

  @override
  String get qiblaNorth => 'North';

  @override
  String get qiblaEast => 'East';

  @override
  String get qiblaSouth => 'South';

  @override
  String get qiblaWest => 'West';

  @override
  String get qiblaDirection => 'Direction';

  @override
  String get qiblaAngle => 'Qibla angle';

  @override
  String get qiblaLocation => 'Location';

  @override
  String get qiblaToMakkah => 'To Makkah';

  @override
  String get qiblaSignal => 'Compass signal';

  @override
  String get qiblaQualityExcellent => 'Excellent';

  @override
  String get qiblaQualityGood => 'Good';

  @override
  String get qiblaQualityMedium => 'Medium';

  @override
  String get qiblaQualityPoor => 'Poor';

  @override
  String get qiblaNeedsCalibration => 'Needs calibration';

  @override
  String get qiblaInterference => 'Metal or electronics nearby';

  @override
  String qiblaAccuracy(int degrees) {
    return '±$degrees°';
  }

  @override
  String qiblaDeclination(String degrees) {
    return 'Magnetic declination $degrees° applied';
  }

  @override
  String get qiblaTipsTitle => 'For better accuracy';

  @override
  String get qiblaTip1 => 'Hold the phone horizontally (flat)';

  @override
  String get qiblaTip2 => 'Stay away from metal objects';

  @override
  String get qiblaTip3 => 'Move away from electronics';

  @override
  String get qiblaTip4 => 'Use it in open areas';

  @override
  String get qiblaTip5 =>
      'In camera mode, hold the phone upright and bring the Kaaba mark to the centre';

  @override
  String get qiblaAligned => 'You are facing the Qibla!';

  @override
  String get qiblaSlightlyRight => 'Turn slightly right';

  @override
  String get qiblaSlightlyLeft => 'Turn slightly left';

  @override
  String get qiblaTurnRight => 'Turn right';

  @override
  String get qiblaTurnLeft => 'Turn left';

  @override
  String get qiblaModeCompass => 'Compass';

  @override
  String get qiblaModeCamera => 'Camera';

  @override
  String get qiblaHoldUpright => 'Hold the phone upright';

  @override
  String get qiblaCameraFailed => 'Couldn’t open the camera';

  @override
  String get qiblaSunTitle => 'Check with the sun';

  @override
  String qiblaSunRight(int sun, int angle) {
    return 'The sun is at $sun° now. Face the sun and turn $angle° right: that is the Qibla.';
  }

  @override
  String qiblaSunLeft(int sun, int angle) {
    return 'The sun is at $sun° now. Face the sun and turn $angle° left: that is the Qibla.';
  }

  @override
  String qiblaSunAhead(int sun) {
    return 'The sun is at $sun° now, right in the direction of the Qibla.';
  }

  @override
  String get qiblaSunDown =>
      'The sun is below the horizon. In daytime you can check the Qibla by the sun, which no magnet can disturb.';

  @override
  String qiblaSunOverKaaba(String when) {
    return 'The sun will stand right over the Kaaba on $when. At that minute, shadows point directly away from the Qibla.';
  }

  @override
  String get qiblaPhaseMove => 'Movement';

  @override
  String get qiblaPhaseHold => 'Stability';

  @override
  String get qiblaCalibrateTitle => 'Calibrate the compass';

  @override
  String get qiblaCalibrateMove =>
      'Turn the phone in a ∞ shape by twisting your wrist, not just sliding it.';

  @override
  String get qiblaCalibrateHold => 'Keep the bubble centred and hold still.';

  @override
  String qiblaMovements(int count, int total) {
    return '$count/$total movements';
  }

  @override
  String get qiblaCalMoving => 'Move the phone in a ∞ pattern...';

  @override
  String get qiblaCalGood => 'Good! Keep going...';

  @override
  String get qiblaCalHoldStill => 'Now hold your phone flat and still...';

  @override
  String get qiblaCalChecking => 'Checking stability...';

  @override
  String get qiblaCalDone => '✓ Calibration complete!';

  @override
  String get qiblaCalibrateShort => 'Calibrate';

  @override
  String get qiblaSkip => 'Skip';

  @override
  String get qiblaUndo => 'Undo';

  @override
  String get qiblaSunMarker => 'Sun';

  @override
  String get qiblaSunTapHint => 'Sun not in the ring? Tap the real sun';

  @override
  String get qiblaSunNotThere =>
      'Tap the sun itself: it sits on the dashed line';

  @override
  String qiblaSunCorrected(String degrees) {
    return 'Corrected by the sun: $degrees°';
  }

  @override
  String get qiblaSunCheckCamera => 'Check with the camera';

  @override
  String get parcelTitle => 'Send a parcel';

  @override
  String get parcelTagline => 'Find a courier to carry your parcel';

  @override
  String get parcelFrom => 'From';

  @override
  String get parcelTo => 'To';

  @override
  String get parcelSwap => 'Swap direction';

  @override
  String get parcelUzbekistan => 'Uzbekistan';

  @override
  String get parcelKorea => 'Korea';

  @override
  String get parcelUzbToKor => 'Uzbekistan to Korea';

  @override
  String get parcelKorToUzb => 'Korea to Uzbekistan';

  @override
  String get parcelByDate => 'By date';

  @override
  String get parcelByCity => 'By city';

  @override
  String parcelPostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String get parcelNoDates => 'No posts in this direction yet';

  @override
  String get parcelNoPosts => 'No posts found';

  @override
  String get parcelNoCities => 'No cities found';

  @override
  String parcelSeeOther(String route) {
    return 'Other direction: $route';
  }

  @override
  String get parcelError => 'Couldn’t load. Check your internet and try again.';

  @override
  String get parcelHowTitle => 'How it works';

  @override
  String get parcelHow1 => 'Choose a direction and how to search';

  @override
  String get parcelHow2 => 'Read a post and contact the courier';

  @override
  String get parcelHow3 => 'Send your parcel safely!';

  @override
  String get parcelWriteTelegram => 'Message on Telegram';

  @override
  String get parcelCall => 'Call';

  @override
  String get parcelContactInText => 'The courier’s contact is in the message';

  @override
  String get parcelShowMore => 'More';

  @override
  String get parcelShowLess => 'Less';

  @override
  String get parcelSearchCity => 'Search a city';

  @override
  String get parcelNoticeTitle => 'Be careful';

  @override
  String get parcelNotice =>
      'These posts are taken from Telegram groups. We are not connected with the couriers — we only show their posts. There may be scammers among them. We are not responsible for any damage.';

  @override
  String get parcelNoticeShort =>
      'Posts from Telegram groups. We’re not connected with the couriers.';

  @override
  String get parcelNoticeOk => 'I understand';

  @override
  String get parcelWaking => 'The server is waking up, one moment…';

  @override
  String get parcelOffline =>
      'No connection. Showing the posts loaded last time.';

  @override
  String get parcelSearch => 'Search';

  @override
  String get parcelSearchPosts => 'Search posts';

  @override
  String parcelSearching(int done, int total) {
    return 'Searching… $done/$total days';
  }

  @override
  String get parcelNothingFound => 'Nothing found';

  @override
  String get parcelSavedTitle => 'Saved posts';

  @override
  String get parcelSave => 'Save';

  @override
  String get parcelUnsave => 'Remove from saved';

  @override
  String get parcelSavedEmpty =>
      'No saved posts yet. Tap the bookmark on a post to keep it.';

  @override
  String get parcelRemoved => 'Removed';

  @override
  String get parcelUndo => 'Undo';

  @override
  String get parcelShare => 'Share';

  @override
  String get parcelEnd => 'No more posts';

  @override
  String parcelDraft(String route, String date) {
    return 'Hello! I’m writing about a parcel for your flight on $date ($route).';
  }

  @override
  String parcelDraftNoDate(String route) {
    return 'Hello! I’m writing about a parcel for your flight ($route).';
  }

  @override
  String get linksTitle => 'Useful links';

  @override
  String linksSubtitle(int count) {
    return '$count Telegram groups and channels';
  }

  @override
  String get linksSearch => 'Group, city or topic';

  @override
  String get linksJobs => 'Jobs';

  @override
  String get linksLife => 'Life in Korea';

  @override
  String get linksGroups => 'Groups';

  @override
  String get linksFavorites => 'Favourites';

  @override
  String get linksNearest => 'Nearest';

  @override
  String get linksByRegion => 'Regions';

  @override
  String linksYourPlace(String city) {
    return 'You are in $city';
  }

  @override
  String get linksLocate => 'Use your location to see the nearest groups first';

  @override
  String get linksLocateButton => 'Locate';

  @override
  String get linksNationwide => 'All of Korea';

  @override
  String get linksNearby => 'Nearby';

  @override
  String get linksFarther => 'Other cities';

  @override
  String get linksRegionCapital => 'Seoul & Gyeonggi';

  @override
  String get linksRegionChungcheong => 'Chungcheong';

  @override
  String get linksRegionJeolla => 'Jeolla';

  @override
  String get linksRegionGyeongsang => 'Gyeongsang';

  @override
  String get linksOther => 'Others';

  @override
  String get linksTopicOfficial => 'Official';

  @override
  String get linksTopicNews => 'News and information';

  @override
  String get linksTopicLegal => 'Law and visas';

  @override
  String get linksTopicInsurance => 'Insurance';

  @override
  String get linksTopicWork => 'Work and career';

  @override
  String get linksTopicEveryday => 'Everyday life';

  @override
  String get linksForEveryone => 'General';

  @override
  String get linksForWomen => 'For women';

  @override
  String get linksOurs => 'Our group, for suggestions and questions';

  @override
  String get linksSuggestTitle => 'Your group isn’t listed?';

  @override
  String get linksSuggestBody =>
      'Write to the Muslim Vegukin group and we’ll add it.';

  @override
  String get linksOpen => 'Open in Telegram';

  @override
  String get linksCopy => 'Copy link';

  @override
  String get linksCopied => 'Link copied';

  @override
  String get linksShare => 'Share';

  @override
  String get linksFavorite => 'Add to favourites';

  @override
  String get linksUnfavorite => 'Remove from favourites';

  @override
  String get linksNothing => 'Nothing found';

  @override
  String linksResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get donationTitle => 'Donation';

  @override
  String get donationHeroTitle => 'Support the project';

  @override
  String get donationHeroSubtitle => 'With your help the project will grow';

  @override
  String get donationMessage =>
      'If this bot has been useful to you and you would like to contribute to its operation and development, you can send any amount to the account below.';

  @override
  String get donationName => 'Name';

  @override
  String get donationAccount => 'Account number';

  @override
  String get donationCopied => 'Copied!';

  @override
  String get donationUsageTitle => 'Collected funds will be used for';

  @override
  String get donationUsage1 => 'Server and hosting costs';

  @override
  String get donationUsage2 => 'Technical maintenance and regular updates';

  @override
  String get donationUsage3 => 'Developer work and project development';

  @override
  String get donationThanksText =>
      'Any contribution from you is very important to us!';

  @override
  String get donationThanks => 'Thank you!';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityHeroTitle => 'Official Telegram Group';

  @override
  String get communityHeroSubtitle => 'Bot users community';

  @override
  String get communityJoinNow => 'Join now';

  @override
  String get communityPurposeTitle => 'Group purpose';

  @override
  String get communityPurposeText =>
      'This group is the official discussion platform for Muslim Vegukin Bot users. Here you can discuss all bot-related topics.';

  @override
  String get communityAllowedTitle => 'Group discussion topics';

  @override
  String get communityTopicPlaceTitle => 'Report new locations';

  @override
  String get communityTopicPlaceBody =>
      'If a new mosque, restaurant or shop needs to be added';

  @override
  String get communityTopicIdeaTitle => 'Suggestions and ideas';

  @override
  String get communityTopicIdeaBody => 'Your thoughts on improving the bot';

  @override
  String get communityTopicBugTitle => 'Bug reports';

  @override
  String get communityTopicBugBody => 'If you find a problem in the bot';

  @override
  String get communityTopicNewsTitle => 'Bot news';

  @override
  String get communityTopicNewsBody =>
      'Announcements about new features and changes';

  @override
  String get communityTopicBetaTitle => 'Beta version discussions';

  @override
  String get communityTopicBetaBody =>
      'Testing new features before public release';

  @override
  String get communityTopicQuestionTitle => 'Questions about the bot';

  @override
  String get communityTopicQuestionBody => 'How to use, about features';

  @override
  String get communityTopicPeopleTitle => 'Community interaction';

  @override
  String get communityTopicPeopleBody => 'Sharing experiences with other users';

  @override
  String get communityRulesTitle => 'Group rules';

  @override
  String get communityRulesWarning =>
      'The following types of messages will be deleted';

  @override
  String get communityBanned1Title => 'Ads and sales announcements';

  @override
  String get communityBanned1Body => 'Any buy or sell advertisements';

  @override
  String get communityBanned2Title => 'Course advertisements';

  @override
  String get communityBanned2Body => 'Language courses, learning centers, etc.';

  @override
  String get communityBanned3Title => 'Non-bot related questions';

  @override
  String get communityBanned3Body => 'Use other groups for general questions';

  @override
  String get communityBanned4Title => 'Spam and repetitive messages';

  @override
  String get communityBanned4Body => 'Sending the same messages repeatedly';

  @override
  String get communityBanned5Title => 'Off-topic discussions';

  @override
  String get communityBanned5Body => 'Conversations unrelated to the bot';

  @override
  String get communityPenaltyTitle => 'Warning';

  @override
  String get communityPenaltyText =>
      'Messages violating rules will be deleted. If repeated, the user will be restricted from sending messages.';

  @override
  String get communityCta =>
      'We invite you to join the group while following the rules!';

  @override
  String get donationTransfer => 'Bank transfer';

  @override
  String get donationBank => 'Bank';

  @override
  String get donationCopyAccount => 'Copy account number';

  @override
  String get donationCopyName => 'Copy name';

  @override
  String get donationOpenApp => 'Transfer in your bank app';

  @override
  String get donationOpenAppHint =>
      'The account number is copied — paste it in the app';

  @override
  String get donationPasteHint => 'Account number copied — paste it in the app';

  @override
  String get donationShare => 'Share the details';

  @override
  String get donationAsk => 'Questions and ideas: our group';

  @override
  String get communityCopyLink => 'Copy link';

  @override
  String get communityLinkCopied => 'Link copied';

  @override
  String get communityShare => 'Share';

  @override
  String get communityMore => 'Also in the group';

  @override
  String get communityTemplateHint =>
      'The template will be copied. Paste it in the group and fill it in.';

  @override
  String get communityTemplateGo => 'Copy and open the group';

  @override
  String get communityTemplateCopied =>
      'Template copied — paste it in the group';

  @override
  String get communityTemplatePlace =>
      '📍 New place\nName: \nType: mosque / restaurant / shop\nAddress: \nMap link: \nNotes: ';

  @override
  String communityTemplateBug(String phone, String version) {
    return '🐛 Bug\nWhere: \nWhat happened: \nWhat should have happened: \n\nPhone: $phone\nApp: $version';
  }

  @override
  String get barcodeTitle => 'Ingredient check';

  @override
  String get barcodeHint => 'Fit the barcode inside the frame';

  @override
  String get barcodeChecking => 'Checking…';

  @override
  String get barcodeTypeCode => 'Type the code';

  @override
  String get barcodeTorch => 'Flashlight';

  @override
  String get barcodeSwitchCamera => 'Switch camera';

  @override
  String get barcodeBackToCamera => 'Scan';

  @override
  String get barcodeCameraOffTitle => 'No camera access';

  @override
  String get barcodeCameraOffBody =>
      'Allow the camera to scan, or type the code in.';

  @override
  String get barcodeOpenSettings => 'Open settings';

  @override
  String get barcodeCameraError => 'Could not connect to the camera.';

  @override
  String get barcodeRetry => 'Retry';

  @override
  String get barcodeVerdictJoiz => 'Permissible';

  @override
  String get barcodeVerdictShubhali => 'Doubtful';

  @override
  String get barcodeVerdictNojoiz => 'Prohibited';

  @override
  String get barcodeVerdictJoizDesc => 'No prohibited ingredients found';

  @override
  String get barcodeVerdictShubhaliDesc =>
      'No prohibited substances, but it is made in the same factory, or some ingredients MIGHT come from animals.';

  @override
  String get barcodeVerdictNojoizDesc => 'Prohibited ingredients detected';

  @override
  String get barcodePork => 'Pork';

  @override
  String get barcodeAlcohol => 'Alcohol';

  @override
  String get barcodeMeat => 'Other meat';

  @override
  String get barcodeSeafood => 'Seafood';

  @override
  String get barcodeAbsent => 'none';

  @override
  String get barcodePresent => 'present';

  @override
  String get barcodeAmbiguous =>
      'Contains 트랜스지방, 쇼트닝, 향료 or 글리세린 — may be of plant or animal FAT origin.';

  @override
  String get barcodeFactoryWarn =>
      'Made on equipment that also makes prohibited products.';

  @override
  String get barcodeFactoryOk =>
      'No prohibited products are made on this equipment.';

  @override
  String get barcodeIngredients => 'Ingredients';

  @override
  String get barcodeDoubtfulLink => 'Can I eat doubtful products?';

  @override
  String get barcodeFoundIn => 'Found in:';

  @override
  String get barcodeGeneralDb => 'General database';

  @override
  String get barcodeStoreUnknown => 'Store not specified';

  @override
  String get barcodeAlsoAt => 'Also available at:';

  @override
  String get barcodeCopyCode => 'Copy the code';

  @override
  String get barcodeCopied => 'Copied';

  @override
  String get barcodeScanNext => 'Scan the next one';

  @override
  String get barcodeNotFound => 'Product not found';

  @override
  String get barcodeNotFoundDesc =>
      'This product is not in the database yet. It may be added later.';

  @override
  String get barcodeOfflineTitle => 'No connection';

  @override
  String get barcodeOfflineBody =>
      'Checking needs the internet. Check your connection and try again.';

  @override
  String get barcodeSaved => 'Saved result · offline';

  @override
  String get barcodeRecent => 'Recent checks';

  @override
  String get barcodeClear => 'Clear';

  @override
  String get barcodeTypeTitle => 'Enter the barcode';

  @override
  String get barcodeTypeHint => 'The digits under the bars: 8 to 14 of them.';

  @override
  String get barcodeSearch => 'Search';

  @override
  String get barcodeErrEmpty => 'Please enter a barcode.';

  @override
  String get barcodeErrNonDigit => 'Digits only.';

  @override
  String get barcodeErrLength => 'A barcode has 8 to 14 digits.';

  @override
  String get barcodeErrChecksum => 'Invalid barcode. Check the digits.';

  @override
  String get barcodeStores => 'Stores';

  @override
  String barcodeProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '$count product',
    );
    return '$_temp0';
  }

  @override
  String get barcodeSoon => 'Soon';

  @override
  String get barcodeStoresError => 'Could not load stores';

  @override
  String get barcodeAll => 'All';

  @override
  String get barcodeStoreEmpty => 'No products found';

  @override
  String get barcodeStoreEmptyDesc => 'Try another category or verdict.';

  @override
  String get barcodeProductsError => 'Couldn’t load products';

  @override
  String get barcodeCheckConnection => 'Check your connection and try again.';

  @override
  String get barcodeContribTitle => 'Help us build the halal database';

  @override
  String get barcodeContribBody =>
      'For those who can read product ingredients: together we collect a halal database for GS25, CU, 7-Eleven, Emart24, No Brand and Daiso. Every entry reaches thousands of people.';

  @override
  String get barcodeContribCta => 'Contact admin';

  @override
  String get barcodeDisclaimer =>
      'This information is based on product ingredients only and *may contain errors*. We do not issue official religious rulings (fatwa). If you find an error, please report it in our Telegram group.';

  @override
  String get barcodeCatDrinks => 'Drinks';

  @override
  String get barcodeCatSnacks => 'Snacks';

  @override
  String get barcodeCatSweets => 'Sweets';

  @override
  String get barcodeCatIceCream => 'Ice cream';

  @override
  String get barcodeCatBaked => 'Baked goods';

  @override
  String get barcodeCatNoodles => 'Noodles / Ramen';

  @override
  String get barcodeCatLunchbox => 'Cookies / Pastry';

  @override
  String get barcodeCatDairy => 'Dairy';

  @override
  String get barcodeCatCanned => 'Canned food';

  @override
  String get barcodeCatFrozen => 'Frozen food';

  @override
  String get barcodeCatSauces => 'Condiments / Sauces';

  @override
  String get barcodeCatFruits => 'Fruits / Vegetables';

  @override
  String get barcodeCatDried => 'Dried food';

  @override
  String get qnaLabel => 'Questions & answers';

  @override
  String get qnaVerseRef => 'Surah An-Nahl, verse 43';

  @override
  String get qnaSource =>
      'Answers by Shaykh Muhammad Sodiq Muhammad Yusuf and other scholars';

  @override
  String get qnaCount => '100,000+ questions';

  @override
  String get qnaAi => 'AI search';

  @override
  String get qnaSearchHint => 'Write your question in Uzbek…';

  @override
  String get qnaUzbekNote =>
      'Questions and answers are in Uzbek (Latin or Cyrillic).';

  @override
  String get qnaDaily => 'Today’s selection';

  @override
  String get qnaDailySub => 'New questions every day';

  @override
  String get qnaNewSet => 'New questions';

  @override
  String get qnaLoadError => 'Couldn’t load the questions';

  @override
  String get qnaCheckConnection => 'Check your connection and try again.';

  @override
  String get qnaRetry => 'Retry';

  @override
  String get qnaSaved => 'Saved answers';

  @override
  String get qnaSavedEmpty => 'Nothing saved yet';

  @override
  String get qnaSavedHint =>
      'Save answers with the bookmark button — they can be read offline.';

  @override
  String get qnaSave => 'Save';

  @override
  String get qnaUnsave => 'Remove from saved';

  @override
  String get qnaSavedNote => 'Saved';

  @override
  String get qnaRemovedNote => 'Removed from saved';

  @override
  String get qnaShare => 'Share';

  @override
  String get qnaTextSize => 'Text size';

  @override
  String get qnaQuestion => 'Question';

  @override
  String get qnaAnswer => 'Answer';

  @override
  String get qnaOpenSource => 'Open the source';

  @override
  String get qnaCopy => 'Copy';

  @override
  String get qnaCopied => 'Question and answer copied';

  @override
  String get qnaRelated => 'Similar questions';

  @override
  String get qnaAnswerError => 'Couldn’t load the answer';

  @override
  String get qnaOther => 'Other';

  @override
  String get qnaSearchTitle => 'Find a question';

  @override
  String get qnaSearchButton => 'Search';

  @override
  String get qnaMinLetters => 'Write at least 3 letters';

  @override
  String get qnaHowTitle => 'How it works';

  @override
  String get qnaHowBody =>
      'An Uzbek language model understands what you ask and finds the closest of thousands of questions and answers. The words needn’t match: the fuller and more correct your question, the better the result. Write in Uzbek, in Latin or Cyrillic letters.';

  @override
  String get qnaRecent => 'Recent searches';

  @override
  String get qnaClear => 'Clear';

  @override
  String get qnaRemove => 'Remove';

  @override
  String get qnaExamples => 'For example';

  @override
  String qnaResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '$count result',
    );
    return '$_temp0';
  }

  @override
  String get qnaNoResults => 'Nothing found';

  @override
  String get qnaNoResultsHint => 'Try asking it differently, in more words.';

  @override
  String get qnaOfflineTitle => 'No connection';

  @override
  String get qnaOfflineBody =>
      'Searching needs the internet. Saved answers open without it.';

  @override
  String get bizTitle => 'Business directory';

  @override
  String get bizTagline => 'Uzbek businesses in Korea, in one place';

  @override
  String get bizSearchTitle => 'Search';

  @override
  String get bizSearchHint => 'Find a business or service';

  @override
  String bizCountAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count businesses',
      one: '$count business',
    );
    return '$_temp0';
  }

  @override
  String bizCountFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count found',
    );
    return '$_temp0';
  }

  @override
  String get bizTileEmpty => 'Empty for now';

  @override
  String get bizDirectoryEmpty => 'The directory is empty for now';

  @override
  String get bizDirectoryEmptyBody =>
      'Uzbek businesses in Korea will gather here.';

  @override
  String get bizSaved => 'Saved';

  @override
  String get bizCategories => 'Categories';

  @override
  String get bizOrderNote => 'Customers’ favourites come first';

  @override
  String get bizCategoryEmpty => 'No businesses here yet';

  @override
  String get bizCategoryEmptyBody =>
      'New businesses will show here once they’re added. Have a look at the other categories too.';

  @override
  String get bizSeeAll => 'See all';

  @override
  String get bizNothingFound => 'Nothing found';

  @override
  String bizNothingFoundBody(String query) {
    return 'No business matches “$query”. Try other words, or browse the categories.';
  }

  @override
  String get bizLoadError => 'Couldn’t load';

  @override
  String get bizCheckConnection => 'Check your connection and try again.';

  @override
  String get bizRetry => 'Retry';

  @override
  String get bizUzbekNote => 'Business listings are written in Uzbek.';

  @override
  String get bizSave => 'Save';

  @override
  String get bizUnsave => 'Remove from saved';

  @override
  String get bizSavedNote => 'Saved — its contacts open even offline';

  @override
  String get bizRemovedNote => 'Removed from saved';

  @override
  String get bizShare => 'Share';

  @override
  String get bizShareFooter => 'From the Muslim Vegukin business directory';

  @override
  String bizViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Viewed $count times',
      one: 'Viewed once',
    );
    return '$_temp0';
  }

  @override
  String bizLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liked by $count people',
      one: 'Liked by $count person',
    );
    return '$_temp0';
  }

  @override
  String get bizLoadFailed => 'Couldn’t load the details.';

  @override
  String get bizLinks => 'More links';

  @override
  String get bizAbout => 'About';

  @override
  String get bizNoInfo => 'This business hasn’t filled in its details yet.';

  @override
  String get bizNoContact => 'No contacts given.';

  @override
  String get bizNoContactAsk => 'Ask the admin';

  @override
  String get bizReport => 'Wrong details? Tell the admin';

  @override
  String get bizCopyAddress => 'Copy';

  @override
  String get bizAddressCopied => 'Address copied';

  @override
  String get bizPhoneCopied => 'Number copied';

  @override
  String get bizActCall => 'Call';

  @override
  String get bizActTelegram => 'Send a message';

  @override
  String get bizActChannel => 'Open';

  @override
  String get bizActKakao => 'Send a message';

  @override
  String get bizActWebsite => 'Open website';

  @override
  String get bizActInstagram => 'View profile';

  @override
  String get bizActTiktok => 'View profile';

  @override
  String get bizActYoutube => 'Watch';

  @override
  String get bizActFacebook => 'View page';

  @override
  String get bizActPlay => 'Get the app';

  @override
  String get bizActAppStore => 'Get the app';

  @override
  String get bizActOpen => 'Open';

  @override
  String get bizChannelPhone => 'Phone';

  @override
  String get bizChannelGroup => 'Telegram channel / group';

  @override
  String get bizChannelWebsite => 'Website';

  @override
  String get bizPrivateGroup => 'Private group';

  @override
  String get bizMapNaver => 'Naver Map';

  @override
  String get bizMapKakao => 'Kakao Map';

  @override
  String get bizMapGoogle => 'Google Maps';

  @override
  String get bizOwnerTitle => 'Own a business?';

  @override
  String get bizOwnerBody =>
      'Add it to the directory — customers will find you here.';

  @override
  String get bizOwnerBodyEmpty => 'Be the first in this category.';

  @override
  String get bizOwnerEyebrow => 'For business owners';

  @override
  String get bizOwnerSheetTitle => 'Joining the directory';

  @override
  String get bizStep1Title => 'Apply';

  @override
  String get bizStep1Body => 'Give your logo, name, category and contacts.';

  @override
  String get bizStep2Title => 'Payment';

  @override
  String bizStep2Body(String amount) {
    return 'A one-off fee of $amount. You send the admin a screenshot of the payment.';
  }

  @override
  String get bizStep3Title => 'Listed';

  @override
  String get bizStep3Body =>
      'Once the payment is confirmed, your business appears in the directory.';

  @override
  String get bizOwnerFine =>
      'Order in the directory follows likes: the best-liked business stands at the top.';

  @override
  String get bizOwnerHow =>
      'Applications go through Telegram: write to the admin, who will help you add your business.';

  @override
  String get bizOwnerContact => 'Contact the admin';

  @override
  String bizCurrency(String amount) {
    return '$amount won';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInWhy =>
      'Watching places and notifications work without signing in. Sign in to write reviews, correct details and post announcements, so others know who wrote them.';

  @override
  String get signInTelegramNote =>
      'This section works through Telegram. Sign in with your Muslim Vegukin bot account — your posts from the bot show here too.';

  @override
  String get signInTelegram => 'Continue with Telegram';

  @override
  String get signInWhatsApp => 'Continue with WhatsApp';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String signInWaitingTitle(String app) {
    return 'Tap “Yes, log in” in $app';
  }

  @override
  String get signInWaitingBody =>
      'We’ll wait here. Confirm, then come back to the app.';

  @override
  String signInOpenAgain(String app) {
    return 'Open $app again';
  }

  @override
  String get signInCancel => 'Cancel';

  @override
  String get signInExpired =>
      'That timed out or was cancelled. Please try again.';

  @override
  String get signInFailed =>
      'That didn’t work. Check your connection and try again.';

  @override
  String get signInDone => 'You’re signed in';

  @override
  String signedInWith(String provider) {
    return 'Signed in with $provider';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteBody =>
      'Your watches, areas and reviews will be deleted for good. This can’t be undone.';

  @override
  String get accountDeleteTelegram =>
      'This includes those made in the Telegram bot.';

  @override
  String get accountDeleteConfirm => 'Delete';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get accountPushOn => 'Notifications come to this phone';

  @override
  String get accountPushOff =>
      'Alerts still reach your Inbox, but this phone won’t show them.';

  @override
  String get pushOpen => 'Open';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String inboxUnread(int count) {
    return '$count new';
  }

  @override
  String get inboxEmptyTitle => 'Nothing here yet';

  @override
  String get inboxEmptyBody =>
      'Notifications sent to you are kept here, including the ones you missed.';

  @override
  String get inboxFailed => 'Couldn’t load. Check your connection.';

  @override
  String get inboxEarlier => 'Show earlier';

  @override
  String get inboxPushOff =>
      'Notifications are off on this phone. New alerts still show up here.';

  @override
  String get inboxMessage => 'Message';

  @override
  String inboxOpenSection(String section) {
    return 'Open $section';
  }

  @override
  String inboxPhoto(int index, int total) {
    return 'Photo $index of $total';
  }

  @override
  String get hkLede =>
      'See the free days at your office. When everything is booked, set a watch and we’ll tell you the moment a slot opens.';

  @override
  String get hkSearchHint => 'Search for your office';

  @override
  String get hkMyWatches => 'My watches';

  @override
  String hkActiveWatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active watches',
      one: '1 active watch',
    );
    return '$_temp0';
  }

  @override
  String get hkLastViewed => 'Last viewed';

  @override
  String get hkStep1 => 'Find your office';

  @override
  String get hkStep2 => 'See the free days';

  @override
  String get hkStep3 => 'Book on HiKorea';

  @override
  String get hkAddressCardTitle => 'Not sure which office?';

  @override
  String get hkAddressCardBody => 'We’ll find it from your home address';

  @override
  String get hkOffices => 'Immigration offices';

  @override
  String hkCounters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count counters',
      one: '1 counter',
    );
    return '$_temp0';
  }

  @override
  String get hkNoMatch =>
      'No office matches. Try another word, or find it by your address.';

  @override
  String get hkLoadFailed => 'Couldn’t load. Check your connection.';

  @override
  String get hkAddressTitle => 'Find by address';

  @override
  String get hkAddressLede =>
      'Each office serves its own districts. Pick your province and type your home address in Korean.';

  @override
  String get hkProvince => '1. Province';

  @override
  String get hkAddress => '2. Home address (in Korean)';

  @override
  String get hkAddressHint =>
      'Include the city or district (-시, -구, -군), e.g. 안산시 단원구.';

  @override
  String get hkFindOffice => 'Find my office';

  @override
  String get hkNeedProvince => 'Pick your province first';

  @override
  String get hkNeedAddress => 'Type your address';

  @override
  String get hkYourOffice => 'Your office:';

  @override
  String get hkPickOne => 'Pick the one that fits:';

  @override
  String get hkAddressNoMatch =>
      'No office found for this address. Type it in full.';

  @override
  String get hkCountersTitle => 'Which counter do you need?';

  @override
  String get hkCountersLede =>
      'Counters do the same job but can differ in place, floor or opening time. Read the description before you pick.';

  @override
  String get hkFromAfternoon => 'Opens at 09:36';

  @override
  String get hkMore => 'More';

  @override
  String hkCounterN(int n) {
    return 'Counter $n';
  }

  @override
  String get hkCalendarHint =>
      'Tap a day to check its slots on HiKorea right now.';

  @override
  String get hkCheckedNow => 'Checked just now';

  @override
  String hkCheckedMinutes(int n) {
    return 'Checked $n min ago';
  }

  @override
  String hkCheckedHours(int n) {
    return 'Checked $n h ago';
  }

  @override
  String hkCheckedDays(int n) {
    return 'Checked $n d ago';
  }

  @override
  String get hkEarliest => 'Earliest free day';

  @override
  String get hkAllFull => 'Every day is booked right now';

  @override
  String get hkAllFullBody =>
      'Set a watch and we’ll tell you the moment a slot opens.';

  @override
  String get hkLegendOpen => 'Open';

  @override
  String get hkLegendSome => 'Filling up';

  @override
  String get hkLegendFull => 'Fully booked';

  @override
  String get hkLegendClosed => 'Closed';

  @override
  String get hkNoDates =>
      'No days are showing right now. Set a watch and we’ll tell you when one opens.';

  @override
  String get hkNotifyMe => 'Notify me when a slot opens';

  @override
  String get hkChecking => 'Checking HiKorea…';

  @override
  String get hkDayClosed => 'The office is closed this day';

  @override
  String get hkFullyBooked => 'Fully booked';

  @override
  String get hkLastOne => 'Just 1 slot left';

  @override
  String hkSlotsFree(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n slots open',
      one: '1 slot open',
    );
    return '$_temp0';
  }

  @override
  String get hkBookCue => 'You book on the HiKorea website.';

  @override
  String get hkFullCue =>
      'No slots now. Set a watch and we’ll tell you when one opens.';

  @override
  String hkBookedOf(int taken, int capacity) {
    return '$taken of $capacity booked';
  }

  @override
  String get hkMorning => 'Morning';

  @override
  String get hkAfternoon => 'Afternoon';

  @override
  String hkLeft(int n) {
    return '$n left';
  }

  @override
  String get hkSlotFull => 'Full';

  @override
  String get hkBook => 'Book on HiKorea';

  @override
  String get hkFetchFailed => 'Couldn’t reach HiKorea. Try again in a moment.';

  @override
  String get hkSessionExpired =>
      'Our connection to HiKorea is being renewed. Try again shortly.';

  @override
  String get hkWatchTitle => 'Which days should we watch?';

  @override
  String get hkWatchLede =>
      'When a slot opens on these days, we’ll send you a notification.';

  @override
  String hkNextDays(int n) {
    return 'Next $n days';
  }

  @override
  String get hkPickDates => 'Pick exact dates';

  @override
  String hkDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get hkStartWatching => 'Start watching';

  @override
  String get hkTooLong => 'You can watch at most 90 days';

  @override
  String get hkDuplicate => 'You’re already watching these days';

  @override
  String get hkMaxReached => 'You can have 10 watches. Stop one first.';

  @override
  String get hkCreateFailed => 'Couldn’t set the watch. Please try again.';

  @override
  String get hkDoneTitle => 'You’re watching';

  @override
  String get hkDoneBody =>
      'We check every 5 minutes. When a slot opens, you’ll get a notification.';

  @override
  String get hkPushOff =>
      'Notifications are off on this phone, so alerts will only show in your Inbox.';

  @override
  String get hkSendTest => 'Send a test notification';

  @override
  String get hkTestSent => 'Sent';

  @override
  String get hkTestFailed => 'Couldn’t send. Check that notifications are on.';

  @override
  String get hkSeeWatches => 'See my watches';

  @override
  String get hkWatchesEmpty => 'No watches yet';

  @override
  String get hkWatchesEmptyBody =>
      'Pick an office, look at its calendar and set a watch.';

  @override
  String get hkStatusActive => 'Active';

  @override
  String get hkStatusExpired => 'Ended';

  @override
  String get hkStatusCancelled => 'Stopped';

  @override
  String get hkStatusUndeliverable => 'Couldn’t deliver';

  @override
  String get hkStop => 'Stop';

  @override
  String get hkStopTitle => 'Stop this watch?';

  @override
  String get hkStopped => 'Watch stopped';

  @override
  String get hkStopFailed => 'Couldn’t stop it. Please try again.';

  @override
  String get hkCalendar => 'Calendar';

  @override
  String get hkPastWatches => 'Past watches';

  @override
  String get hkPickOffice => 'Pick an office';

  @override
  String get hkStep1Body => 'By its name, or by your home address';

  @override
  String get hkStep2Body =>
      'Every counter’s next 3 months, updated every 5 minutes';

  @override
  String get hkStep3Body =>
      'All booked? Set a watch and we’ll tell you when a slot opens';

  @override
  String get hkHowTitle => 'How it works';

  @override
  String get hkStartTitle => 'Which office is yours?';

  @override
  String get hkStartBody =>
      'It depends on where you live: each office serves its own districts.';

  @override
  String get hkStartOr => 'or pick it from the list below';

  @override
  String get hkYourWatches => 'Your watches';

  @override
  String hkSeeAll(int count) {
    return 'See all ($count)';
  }

  @override
  String hkWatchFree(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n free days in your dates',
      one: '1 free day in your dates',
    );
    return '$_temp0';
  }

  @override
  String get hkWatchFull => 'All booked — we’re watching';

  @override
  String hkEarliestShort(String day) {
    return 'Earliest free day: $day';
  }

  @override
  String get hkAllFullShort => 'Every day is booked now';

  @override
  String get hkOfficeMain => 'Immigration office';

  @override
  String get hkOfficeBranch => 'Branch office';

  @override
  String hkOfficeBranchOf(String office) {
    return 'Branch of $office';
  }

  @override
  String get hkAllOffices => 'All offices';

  @override
  String hkFreeDays(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n free days up to $date',
      one: '1 free day up to $date',
    );
    return '$_temp0';
  }

  @override
  String hkBookedUntil(String date) {
    return 'Booked up to $date. Set a watch and we’ll tell you the moment a slot opens.';
  }

  @override
  String get hkHowBooking =>
      'You book on the HiKorea website, with your own HiKorea account. Here you see which days are free.';

  @override
  String get hkLegendLater => 'Not open yet';

  @override
  String get hkWatchShort => 'Watch';

  @override
  String get hkStale =>
      'We couldn’t check this counter lately, so these days may be out of date.';

  @override
  String get accountGuest => 'Guest';

  @override
  String get accountGuestBody =>
      'Sign in so your name shows with your reviews, and your watches move with you to a new phone.';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountNoPhoto =>
      'WhatsApp doesn’t share profile photos with apps.';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String get accountPushOffTitle => 'Notifications are off';

  @override
  String get accountTurnOn => 'Turn on';

  @override
  String get accountWhatComes =>
      'Slots opening on HiKorea, news from places and areas you follow, and announcements.';

  @override
  String get accountTelegramToo =>
      'They also come from the Muslim Vegukin bot in Telegram.';

  @override
  String get accountTestPush => 'Send a test';

  @override
  String get accountTestSent => 'Sent — look at your phone';

  @override
  String get accountTestFailed =>
      'Couldn’t send. Please try again in a moment.';

  @override
  String get accountActivity => 'Your activity';

  @override
  String get accountInboxNone => 'No messages yet';

  @override
  String accountInboxAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get accountApp => 'App';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountDarkMode => 'Dark mode';

  @override
  String get accountManage => 'Manage account';

  @override
  String accountActive(int count) {
    return '$count active';
  }

  @override
  String get hkDormantTitle => 'HiKorea shows no days at this counter';

  @override
  String hkDormantBody(String date) {
    return 'Since $date HiKorea has listed no days here, free or booked. It does this when it replaces a counter with a new one. Look at this office’s other counters, or check on the HiKorea website.';
  }

  @override
  String get hkDormantBodyNoDate =>
      'HiKorea lists no days here, free or booked. It does this when it replaces a counter with a new one. Look at this office’s other counters, or check on the HiKorea website.';

  @override
  String get hkOtherCounters => 'This office’s other counters';

  @override
  String get hkCheckOnHikorea => 'Check on HiKorea';

  @override
  String get hkNoDaysShort => 'No days on HiKorea';

  @override
  String get hkLeafLegend => 'Date: the earliest free day';

  @override
  String get hkLeafFull => 'Full';

  @override
  String get hkWatchingHere => 'You watch a counter here';

  @override
  String get plNearest => 'Nearest';

  @override
  String plMetres(String n) {
    return '$n m';
  }

  @override
  String plKm(String n) {
    return '$n km';
  }

  @override
  String get plNoReviews => 'No reviews yet';

  @override
  String plReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get plShare => 'Share';

  @override
  String get plAddressNotFound =>
      'That address wasn’t found. Try writing it more precisely, in Korean.';

  @override
  String get plNothingFound => 'Nothing found';

  @override
  String get plLoadFailed => 'Couldn’t load the places. Check your connection.';

  @override
  String get plMissingTitle => 'Know a place that isn’t listed?';

  @override
  String get plMissingBody => 'Write to our group and we’ll add it.';

  @override
  String get plWatchingBadge => 'Watching';

  @override
  String plPhotoCount(String i, String n) {
    return '$i / $n';
  }

  @override
  String get plWatch => 'Watch';

  @override
  String plWatchers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people watching',
      one: '1 person watching',
    );
    return '$_temp0';
  }

  @override
  String get plWatchOn => 'News about it will come to this phone';

  @override
  String get plWatchOff => 'You stopped watching';

  @override
  String get plWatchNoPush => 'Notifications are off, so news won’t arrive';

  @override
  String get plWatchPushOn => 'Turn on';

  @override
  String get plAddress => 'Address';

  @override
  String get plNoAddress => 'No address given';

  @override
  String get plPhone => 'Phone';

  @override
  String get plMenu => 'Menu';

  @override
  String get plMenuOpen => 'Open the menu';

  @override
  String get plAddressCopied => 'Address copied';

  @override
  String get plCopyAddress => 'Copy the address';

  @override
  String get plMapAttribution => '© OpenStreetMap';

  @override
  String get plAbout => 'About the place';

  @override
  String get plAboutEmpty =>
      'Opening hours and days off have not been added yet.';

  @override
  String get plAboutAdd => 'Add information';

  @override
  String get plSuggestChange => 'Suggest a change';

  @override
  String get plSocial => 'Social media';

  @override
  String get plSocialEmpty => 'Do you know this place’s social media?';

  @override
  String get plSocialAdd => 'Add';

  @override
  String get plInviteLink => 'Link';

  @override
  String plPendingField(String what) {
    return '$what: a suggestion is waiting for review';
  }

  @override
  String get plNoteLabel => 'Information';

  @override
  String get plReviews => 'Reviews';

  @override
  String get plReviewsFirst => 'Be the first to review — it helps others.';

  @override
  String get plWriteReview => 'Write a review';

  @override
  String get plEditReview => 'Change your review';

  @override
  String get plYourReview => 'Your review';

  @override
  String plAllReviews(int count) {
    return 'Show all ($count)';
  }

  @override
  String get plNoText => 'Rating only';

  @override
  String get plCorrections =>
      'Wrong name, address or phone? Write to our group.';

  @override
  String get plLoadDetailFailed => 'Couldn’t load. Check your connection.';

  @override
  String get plGone => 'This place wasn’t found. It may have been removed.';

  @override
  String get plRateQuestion => 'How would you rate it?';

  @override
  String get plStar1 => 'Very bad';

  @override
  String get plStar2 => 'Bad';

  @override
  String get plStar3 => 'Okay';

  @override
  String get plStar4 => 'Good';

  @override
  String get plStar5 => 'Excellent';

  @override
  String get plReviewHintMosque =>
      'For example: prayer times, the door code, how to get there.';

  @override
  String get plReviewHintRestaurant =>
      'For example: the food, prices, service, opening hours.';

  @override
  String get plReviewHintShop =>
      'For example: what they sell, prices, opening hours.';

  @override
  String get plReviewPlaceholder => 'Your thoughts (optional)';

  @override
  String get plReviewPublic =>
      'Everyone sees the review; nobody sees your name.';

  @override
  String get plReviewSend => 'Publish';

  @override
  String get plReviewSave => 'Save';

  @override
  String get plReviewPick => 'Choose a rating first';

  @override
  String get plReviewPublished => 'Thank you! Your review is published.';

  @override
  String get plReviewUpdated => 'Your review is updated.';

  @override
  String get plReviewDelete => 'Delete the review';

  @override
  String get plReviewDeleteAsk => 'Delete your review?';

  @override
  String get plReviewDeleted => 'Your review is deleted.';

  @override
  String get plDelete => 'Delete';

  @override
  String get plCancel => 'Cancel';

  @override
  String get plSend => 'Send';

  @override
  String get plSuggestPick => 'What would you like to add?';

  @override
  String plSuggestAddLink(String platform) {
    return 'Add $platform link';
  }

  @override
  String plSuggestEditLink(String platform) {
    return 'Change $platform link';
  }

  @override
  String get plSuggestAddNote => 'Add information';

  @override
  String get plSuggestEditNote => 'Change information';

  @override
  String plSuggestCurrent(String value) {
    return 'Now: $value';
  }

  @override
  String get plHintTelegram => '@username or a t.me link';

  @override
  String get plHintTiktok => '@username or a tiktok.com link';

  @override
  String get plHintInstagram => '@username or an instagram.com link';

  @override
  String get plHintNote => 'Opening hours, days off or an announcement.';

  @override
  String get plNotePlaceholder =>
      'For example:\nMon–Fri: 11:00 – 22:00\nSaturday: closed';

  @override
  String get plModeration => 'It appears once an admin has checked it.';

  @override
  String get plSuggestSent => 'Thank you! Your suggestion is under review.';

  @override
  String get plAnnounceMosque => 'Write an announcement';

  @override
  String get plAnnounceOwner => 'Send an announcement';

  @override
  String get plAnnounceWhyMosque =>
      'Eid prayer times, say: it goes to the people who watch this place.';

  @override
  String get plAnnounceWhyOwner =>
      'Send news to the people who watch this place.';

  @override
  String plAnnouncePending(int count) {
    return '$count awaiting review';
  }

  @override
  String get plAnnounceTitle => 'Announcement';

  @override
  String get plAnnouncePlaceholderOwner =>
      'For example: We’re closed on 25 December.';

  @override
  String get plAnnouncePlaceholderMosque =>
      'For example: Eid prayer at 07:00, 08:00 and 09:00.';

  @override
  String plAnnounceReach(int count) {
    return 'Once an admin approves it, about $count people will get it.';
  }

  @override
  String get plAnnounceSend => 'Send for review';

  @override
  String get plAnnounceSent => 'Sent for review';

  @override
  String get plTextEmpty => 'Write something first.';

  @override
  String get plClaimPrompt => 'Do you own this place?';

  @override
  String get plClaimWhy =>
      'The owner can send news to the people who watch it.';

  @override
  String get plClaimConfirm =>
      'Your name and contact go to the admin, who will get in touch to check that you own it. Continue?';

  @override
  String get plClaimContinue => 'Continue';

  @override
  String get plClaimSent => 'Request sent. The admin will get in touch.';

  @override
  String get plClaimPending => 'Your ownership request is being reviewed.';

  @override
  String get plYouOwn => 'You own this place';

  @override
  String get plErrNetwork => 'No internet connection. Please try again.';

  @override
  String get plErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get plErrSignIn => 'Sign in to do this.';

  @override
  String get plErrTooManyReviews =>
      'You’ve left too many reviews today. Please try again tomorrow.';

  @override
  String get plErrTooLong => 'That is too long.';

  @override
  String get plErrTooShort => 'That is too short.';

  @override
  String get plErrWrongHost =>
      'That link points to a different site. Please enter the right one.';

  @override
  String get plErrHandle =>
      'That username is not valid. Letters, digits and underscores only.';

  @override
  String get plErrUrl => 'That does not look like a link.';

  @override
  String get plErrIncomplete => 'That link is incomplete.';

  @override
  String get plErrNotProfile =>
      'That is a link to a post. Please send the profile link.';

  @override
  String get plErrPending => 'A change to this is already waiting for review.';

  @override
  String get plErrSame => 'That is already what is saved.';

  @override
  String get plErrRateLimited =>
      'You have reached today’s limit. Please try again tomorrow.';

  @override
  String get plErrGone => 'This place no longer exists.';

  @override
  String get plErrNotOwner =>
      'Only the confirmed owner can post news for this place.';

  @override
  String get plErrHasOwner => 'This place already has a confirmed owner.';

  @override
  String get plErrTooManyPending =>
      'You have too many requests waiting for review. Please wait until they’re handled.';

  @override
  String get plPhotoFailed => 'Couldn’t load the photo';

  @override
  String get plMosque => 'Mosque';

  @override
  String get plRestaurant => 'Restaurant';

  @override
  String get plShop => 'Shop';

  @override
  String get plNearMe => 'Search near me';

  @override
  String get plByAddress => 'Search near an address';

  @override
  String get plAddressTip =>
      'Write the address in KOREAN: city, district, street. Copying it from a map works too.';

  @override
  String get plSearchButton => 'Search';

  @override
  String get plRecentAddresses => 'Recent addresses';

  @override
  String get plChooseTitle => 'Where shall we look?';

  @override
  String get plChooseBody =>
      'Choose one of the buttons above: around you or around another address. We show the 5 nearest.';

  @override
  String plNearestMosques(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count nearest mosques',
      one: 'The nearest mosque',
    );
    return '$_temp0';
  }

  @override
  String plNearestRestaurants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count nearest restaurants',
      one: 'The nearest restaurant',
    );
    return '$_temp0';
  }

  @override
  String plNearestShops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count nearest shops',
      one: 'The nearest shop',
    );
    return '$_temp0';
  }

  @override
  String get plNearestToAddress => 'Nearest to the address';

  @override
  String plHereNow(String city, String when) {
    return 'You’re in $city · $when';
  }

  @override
  String plHereNowNoCity(String when) {
    return 'Located · $when';
  }

  @override
  String plSavedNote(String city, String when) {
    return 'Couldn’t get your current location — showing for $city ($when)';
  }

  @override
  String plSavedNoteNoCity(String when) {
    return 'Couldn’t get your current location — showing for the earlier one ($when)';
  }

  @override
  String get plLocatingYou => 'Finding your location…';

  @override
  String get plLoadingPlaces => 'Loading places…';

  @override
  String get plDeniedBody =>
      'Allow location to find the nearest places, or search by address.';

  @override
  String get plAllow => 'Allow';

  @override
  String get plBlockedBody =>
      'Location access is off in the settings. Turn it on, or search by address.';

  @override
  String get plOffBody =>
      'Location is off on the phone. Turn it on, or search by address.';

  @override
  String get plFailedBody =>
      'Couldn’t get your location. Try again, or search by address.';

  @override
  String get plUseAddress => 'Search by address';

  @override
  String get plDetails => 'Details';

  @override
  String plKmFromYou(String km) {
    return '$km from you';
  }

  @override
  String plKmFromAddress(String km) {
    return '$km from the address';
  }

  @override
  String get themeToDay => 'Day mode';

  @override
  String get themeToNight => 'Night mode';

  @override
  String get plSocialMore => 'Know a page on another network?';

  @override
  String get plCallNumber => 'Call';

  @override
  String get plShareFooter => 'Found in the Muslim Vegukin app';

  @override
  String get plPhotoLoading => 'Loading the photo…';

  @override
  String get plPhotoLoadingSpeed =>
      'How fast depends on your internet connection';

  @override
  String get plGettingThere => 'Getting there';

  @override
  String get plContact => 'Contact';

  @override
  String get plNewsTitle => 'News';
}
