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
      'If Muslim Vegukin has been useful to you and you would like to contribute to its operation and development, you can send any amount to the account below.';

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
  String get communityHeroSubtitle => 'Users’ community';

  @override
  String get communityJoinNow => 'Join now';

  @override
  String get communityPurposeTitle => 'Group purpose';

  @override
  String get communityPurposeText =>
      'This group is the official discussion platform for Muslim Vegukin users. Here you can discuss everything about the project.';

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
  String get communityTopicIdeaBody =>
      'Your ideas for improving Muslim Vegukin';

  @override
  String get communityTopicBugTitle => 'Bug reports';

  @override
  String get communityTopicBugBody => 'If you find a problem';

  @override
  String get communityTopicNewsTitle => 'Project news';

  @override
  String get communityTopicNewsBody =>
      'Announcements about new features and changes';

  @override
  String get communityTopicBetaTitle => 'Beta version discussions';

  @override
  String get communityTopicBetaBody =>
      'Testing new features before public release';

  @override
  String get communityTopicQuestionTitle => 'Questions about Muslim Vegukin';

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
  String get communityBanned3Title => 'Questions unrelated to the project';

  @override
  String get communityBanned3Body => 'Use other groups for general questions';

  @override
  String get communityBanned4Title => 'Spam and repetitive messages';

  @override
  String get communityBanned4Body => 'Sending the same messages repeatedly';

  @override
  String get communityBanned5Title => 'Off-topic discussions';

  @override
  String get communityBanned5Body => 'Conversations unrelated to the project';

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
  String get accountTestFailed =>
      'Couldn’t send. Please try again in a moment.';

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

  @override
  String get carMarket => 'Car Market';

  @override
  String get carTabBrowse => 'Browse';

  @override
  String get carTabSearch => 'Search';

  @override
  String get carTabSaved => 'Saved';

  @override
  String carListings(String count) {
    return '$count listings';
  }

  @override
  String carAvailableSold(String available, String sold) {
    return '$available for sale · $sold sold';
  }

  @override
  String get carSearchSub => 'By details';

  @override
  String carSavedSub(String count) {
    return '$count saved';
  }

  @override
  String get carLoading => 'Loading…';

  @override
  String get carMedianPrice => 'average price';

  @override
  String get carNoneOnSale => 'None for sale right now';

  @override
  String carSoldCount(String count) {
    return '$count sold';
  }

  @override
  String get carSortNew => 'Newest';

  @override
  String get carSortValue => 'Best value';

  @override
  String get carSortPriceUp => 'Price ↑';

  @override
  String get carSortPriceDown => 'Price ↓';

  @override
  String get carSortMileage => 'Mileage ↑';

  @override
  String get carSortYear => 'Year ↓';

  @override
  String get carAll => 'All';

  @override
  String get carAvailable => 'For sale';

  @override
  String get carSold => 'Sold';

  @override
  String get carEmptyAllTitle => 'No listings yet';

  @override
  String get carEmptyAllBody => 'New cars are added soon';

  @override
  String get carEmptyModelTitle => 'No listings for this model';

  @override
  String get carEmptyModelBody => 'Pick another model at the top';

  @override
  String get carChannelTitle => 'Vegukin Avto — channel';

  @override
  String get carChannelBody => 'Every new listing appears there first';

  @override
  String get carOpen => 'Open';

  @override
  String get carLoadFailed => 'Couldn’t load';

  @override
  String get carCheckInternet => 'Check your internet connection';

  @override
  String get carDeal => 'Good price';

  @override
  String get carNegotiable => 'Negotiable';

  @override
  String get carNoPrice => 'No price given';

  @override
  String get carFewDetails => 'Few details';

  @override
  String get carSeen => 'Seen';

  @override
  String get carSave => 'Save';

  @override
  String get carUnsave => 'Remove from saved';

  @override
  String get carFuelPetrol => 'Petrol';

  @override
  String get carFuelDiesel => 'Diesel';

  @override
  String get carFuelLpg => 'LPG';

  @override
  String get carFuelHybrid => 'Hybrid';

  @override
  String get carAutomatic => 'Automatic';

  @override
  String get carManual => 'Manual';

  @override
  String get carNotGiven => 'Not given';

  @override
  String get carPickModel => 'Choose a make and model';

  @override
  String get carPriceMax => 'Price up to, ₩';

  @override
  String get carMileageMax => 'Mileage up to, km';

  @override
  String get carYearFrom => 'Year from';

  @override
  String get carFuel => 'Fuel';

  @override
  String get carStatus => 'Status';

  @override
  String carResults(String count) {
    return '$count results';
  }

  @override
  String get carNothingFound => 'Nothing found';

  @override
  String get carWidenFilters => 'Try wider filters';

  @override
  String get carClearFilters => 'Clear';

  @override
  String get carSavedEmptyTitle => 'Nothing saved yet';

  @override
  String get carSavedEmptyBody => 'Save the cars you like with ❤';

  @override
  String get carStartBrowsing => 'Start browsing';

  @override
  String get carPickBrand => 'Choose a make';

  @override
  String get carAnyBrand => 'Any';

  @override
  String get carAllBrands => 'all makes';

  @override
  String carBrandListings(String count) {
    return '$count listings';
  }

  @override
  String carAllOf(String brand) {
    return 'All $brand';
  }

  @override
  String get carSearchHint => 'Search…';

  @override
  String get carCatalogFailed =>
      'Couldn’t load the makes. Check your connection and try again.';

  @override
  String carViews(String count) {
    return '$count views';
  }

  @override
  String get carNotice =>
      'These details were read from the post automatically and may be wrong. Read the post for the exact price and details.';

  @override
  String get carPostText => 'The post';

  @override
  String get carNoText => 'No text';

  @override
  String get carReadMore => 'Read more';

  @override
  String get carReadLess => 'Show less';

  @override
  String carSource(String name) {
    return 'From the $name channel';
  }

  @override
  String get carPriceAnalysis => 'Price check';

  @override
  String get carVeryCheap => 'Very cheap';

  @override
  String get carCheap => 'Cheap';

  @override
  String get carAtMarket => 'At market price';

  @override
  String get carPricier => 'A bit pricey';

  @override
  String get carExpensive => 'Expensive';

  @override
  String get carNearAverage => 'close to average';

  @override
  String carBelowAverage(String percent) {
    return '$percent% below average';
  }

  @override
  String carAboveAverage(String percent) {
    return '$percent% above average';
  }

  @override
  String carFewComparables(String count) {
    return 'only $count to compare with';
  }

  @override
  String carScaleCheap(String price) {
    return 'cheapest $price';
  }

  @override
  String carScaleDear(String price) {
    return 'priciest $price';
  }

  @override
  String carNearYearBasis(String year, String count, String median) {
    return '$count from around $year · average $median';
  }

  @override
  String carModelBasis(String count, String median) {
    return '$count for sale · average $median';
  }

  @override
  String carSoldBasis(String count, String median) {
    return '$count sold · $median';
  }

  @override
  String get carDetails => 'Details';

  @override
  String get carGeneration => 'Generation';

  @override
  String get carYear => 'Year';

  @override
  String get carMileage => 'Mileage';

  @override
  String get carGearbox => 'Gearbox';

  @override
  String get carLegal => 'Papers';

  @override
  String get carLegalOk => 'Legal';

  @override
  String get carLegalNoReg => 'Not registered';

  @override
  String get carRegistration => 'Transfer of ownership';

  @override
  String get carRequired => 'Required';

  @override
  String get carNotRequired => 'Not required';

  @override
  String get carPosted => 'Posted';

  @override
  String get carSourceLabel => 'Source';

  @override
  String get carContact => 'Contact';

  @override
  String get carSellerPhone => 'Seller’s phone';

  @override
  String get carCall => 'Call';

  @override
  String get carCopy => 'Copy';

  @override
  String get carCopied => 'Number copied';

  @override
  String get carWriteOnTelegram => 'Message on Telegram';

  @override
  String get carWrite => 'Message';

  @override
  String get carNumberInText => 'The number is in the post';

  @override
  String get carSimilar => 'Similar cars';

  @override
  String get carSimilarSub => 'by price';

  @override
  String get carNoComparables => 'Nothing to compare with';

  @override
  String get carListingFailed => 'Couldn’t load the listing';

  @override
  String carVideoSize(String size) {
    return 'Video · $size MB';
  }

  @override
  String get carListing => 'Listing';

  @override
  String get carTabAlerts => 'Alerts';

  @override
  String get carTabSell => 'Sell';

  @override
  String get carAlertsTitle => 'Alerts';

  @override
  String carAlertsActive(String count) {
    return '$count active';
  }

  @override
  String get carNewAlert => 'New alert';

  @override
  String get carAnyCar => 'Any car';

  @override
  String get carCreateAlert => 'Create alert';

  @override
  String get carMyAlerts => 'My alerts';

  @override
  String get carNoAlertsTitle => 'No alerts yet';

  @override
  String get carNoAlertsBody => 'We’ll tell you when a matching car is posted';

  @override
  String get carAllListings => 'All listings';

  @override
  String get carAlertNeedsFilter =>
      'Choose at least one filter (model, price, mileage, year or fuel).';

  @override
  String get carAlertDuplicate => 'You already have this alert.';

  @override
  String get carAlertLimit => 'You’ve reached the alert limit.';

  @override
  String get carAlertCreated =>
      'Done: matching listings will come to your phone.';

  @override
  String get carAlertDeleted => 'Alert deleted';

  @override
  String get carSignInAlertsTitle => 'Hear about the right car first';

  @override
  String get carSignInAlertsBody =>
      'Sign in for alerts. Browsing and saving need no account.';

  @override
  String get carSignInButton => 'Sign in';

  @override
  String get carPushOff => 'Notifications are off, so alerts won’t arrive.';

  @override
  String get carPushOn => 'Turn on';

  @override
  String get carErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get carMyPosts => 'My listings';

  @override
  String get carNewPost => 'New listing';

  @override
  String get carNewPostSub => 'Sell your car';

  @override
  String get carNoPostsTitle => 'No listings yet';

  @override
  String get carNoPostsBody =>
      'Post your first listing with the button above — it takes a few minutes.';

  @override
  String get carStatePending => 'Under review';

  @override
  String get carStateApproved => 'Live';

  @override
  String get carStateRejected => 'Rejected';

  @override
  String get carStateChanges => 'Changes needed';

  @override
  String get carStateDraft => 'Draft';

  @override
  String get carEdit => 'Edit';

  @override
  String get carMarkSold => 'Sold';

  @override
  String get carDelete => 'Delete';

  @override
  String get carSoldConfirmTitle => 'Mark as sold?';

  @override
  String get carSoldConfirmBody => 'The listing will show as sold.';

  @override
  String get carSoldConfirmYes => 'Yes, sold';

  @override
  String get carMarkedSold => 'Marked as sold';

  @override
  String get carDeleteConfirmTitle => 'Delete the listing?';

  @override
  String get carDeleteConfirmBody => 'This can’t be undone.';

  @override
  String get carDeleted => 'Deleted';

  @override
  String get carCancel => 'Cancel';

  @override
  String get carSignInSellTitle => 'Sell your car';

  @override
  String get carSignInSellBody => 'Sign in to post a listing.';

  @override
  String get carNewPostTitle => 'New listing';

  @override
  String get carEditPostTitle => 'Edit listing';

  @override
  String get carPhotos => 'Photos and video';

  @override
  String get carPhotosHint =>
      'The first is the cover. Up to 10, each video ≤ 50MB.';

  @override
  String get carPhotosLocked => 'Photos can’t be changed once sent.';

  @override
  String get carAddMedia => 'Add';

  @override
  String get carCover => 'Cover';

  @override
  String get carCarSection => 'The car';

  @override
  String get carBrand => 'Make';

  @override
  String get carModel => 'Model';

  @override
  String get carPickBrandFirst => 'Choose the make first';

  @override
  String get carPickModelTitle => 'Choose the model';

  @override
  String get carOtherModel => 'Another model (type it)';

  @override
  String get carModelHint => 'e.g. Sonata';

  @override
  String get carPickYear => 'Choose the year';

  @override
  String get carGenerationOptional => 'Generation (optional)';

  @override
  String get carMileageLabel => 'Mileage (km)';

  @override
  String get carFuelType => 'Fuel';

  @override
  String get carPriceSection => 'Price and papers';

  @override
  String get carPriceLabel => 'Price (₩)';

  @override
  String get carNegotiableSub => 'Open to offers';

  @override
  String get carLegalLabel => 'Registration status';

  @override
  String get carLegalNo => 'Not legal';

  @override
  String get carRegQuestion => 'Transfer of ownership needed?';

  @override
  String get carRegYes => 'Yes';

  @override
  String get carPhoneLabel => 'Phone number';

  @override
  String get carContactHint => 'Fill in at least one.';

  @override
  String get carDescription => 'Description';

  @override
  String get carDescriptionHint =>
      'Condition, replaced parts, why you’re selling...';

  @override
  String get carSubmit => 'Send for review';

  @override
  String get carSaveChanges => 'Save';

  @override
  String get carRequiredMissing => 'Fill in the required fields';

  @override
  String get carChangesSaved => 'Saved';

  @override
  String get carSubmitted => 'Sent! Your listing goes live once checked.';

  @override
  String carUploading(String done, String total) {
    return 'Uploading: $done / $total';
  }

  @override
  String get carVideoTooBig => 'The video is over 50MB';

  @override
  String get carMediaLimit => 'Up to 10';

  @override
  String get carNeedPhoto => 'Add at least one photo';

  @override
  String get carDupTitle => 'This car is already listed';

  @override
  String get carDupBody =>
      'A listing with the same number and car exists. It can’t be posted twice.';

  @override
  String get carDupOwn => 'Your listing';

  @override
  String get carOk => 'OK';

  @override
  String get carChannelNudge => 'Join @vegukin_car to see new listings first';

  @override
  String get hsTabBoard => 'E’lonlar';

  @override
  String get hsTabMine => 'E’lonlarim';

  @override
  String get hsTabAlerts => 'Xabarnoma';

  @override
  String get hsTabPost => 'Joylash';

  @override
  String get hsSearchHint =>
      'Koreys tilida manzil yozsangiz, e’lonlar shu joyga yaqinligi bo‘yicha saralanadi.';

  @override
  String get hsSearch => 'Izlash';

  @override
  String get hsRecent => 'Eng yangi e’lonlar';

  @override
  String get hsNearest => 'Yaqinlik bo‘yicha';

  @override
  String hsCount(String count) {
    return '$count ta';
  }

  @override
  String get hsCancel => 'Bekor qilish';

  @override
  String get hsMore => 'Yana yuklash';

  @override
  String get hsAllShown => 'Barcha e’lonlar ko‘rsatildi';

  @override
  String get hsNew => 'Yangi';

  @override
  String get hsYours => 'Sizniki';

  @override
  String get hsSeeNumber => 'Raqamni ko‘rish';

  @override
  String get hsViaTelegram => 'Telegram orqali bog‘lanish';

  @override
  String get hsNoContact => 'Aloqa ma’lumoti yo‘q';

  @override
  String get hsEmptyTitle => 'Hozircha e’lon yo‘q';

  @override
  String get hsEmptyBody =>
      'Birinchi bo‘lib e’lon joylang — pastdagi «Joylash» tugmasini bosing.';

  @override
  String get hsPostAd => 'E’lon joylash';

  @override
  String get hsGeoTitle => 'Manzil topilmadi';

  @override
  String get hsGeoBody => 'Manzilni koreys tilida, to‘liqroq yozib ko‘ring:';

  @override
  String get hsRetry => 'Qayta urinish';

  @override
  String get hsLoadFailedTitle => 'E’lonlarni yuklab bo‘lmadi';

  @override
  String get hsLoadFailedBody =>
      'Internet aloqasini tekshiring va qayta urinib ko‘ring.';

  @override
  String get hsOpenFailedTitle => 'Ochib bo‘lmadi';

  @override
  String get hsOpenFailedBody =>
      'Bu e’lon o‘chirilgan yoki muddati tugagan bo‘lishi mumkin.';

  @override
  String get hsCopy => 'Nusxalash';

  @override
  String get hsNoPhone => 'Tel raqam ko‘rsatilmagan.';

  @override
  String get hsEdit => 'Tahrirlash';

  @override
  String get hsDelete => 'O‘chirish';

  @override
  String get hsCopied => 'Raqam nusxalab olindi';

  @override
  String get hsDeleteConfirm => 'E’lon o‘chirilsinmi? Buni qaytarib bo‘lmaydi.';

  @override
  String get hsDeleted => 'E’lon o‘chirildi';

  @override
  String get hsMineTitle => 'Mening e’lonlarim';

  @override
  String get hsMineSub =>
      'E’lonlar 30 kundan keyin ro‘yxatdan olinadi. Muddat tugashidan oldin shu yerdan uzaytiring.';

  @override
  String get hsActive => 'Faol';

  @override
  String get hsExpired => 'Muddati tugagan';

  @override
  String hsDaysLeft(String count) {
    return '$count kun qoldi';
  }

  @override
  String get hsHidden => 'Ro‘yxatda ko‘rinmaydi';

  @override
  String get hsExtend => 'Uzaytirish';

  @override
  String hsExtended(String count) {
    return 'Muddat yana $count kunga uzaytirildi';
  }

  @override
  String get hsMineEmptyTitle => 'Sizda e’lon yo‘q';

  @override
  String get hsMineEmptyBody => 'Joylagan e’lonlaringiz shu yerda ko‘rinadi.';

  @override
  String get hsFailedTitle => 'Yuklab bo‘lmadi';

  @override
  String get hsFailedBody => 'Qayta urinib ko‘ring.';

  @override
  String get hsNewTitle => 'Yangi e’lon';

  @override
  String get hsEditTitle => 'E’lonni tahrirlash';

  @override
  String get hsComposeSub => 'Manzil, telefon raqami va qisqa tavsif kifoya';

  @override
  String get hsAddress => 'Manzil';

  @override
  String get hsRequired => 'majburiy';

  @override
  String get hsAddressHint =>
      'Koreys tilida yozing. Manzil keyin o‘zgartirilmaydi.';

  @override
  String get hsAddressLocked =>
      'Manzilni o‘zgartirib bo‘lmaydi. Xato bo‘lsa, e’lonni o‘chirib, yangisini joylang.';

  @override
  String get hsPhone => 'Bog‘lanish uchun telefon raqam';

  @override
  String get hsContactHint =>
      'Telefon raqami yoki Telegram — kamida bittasi ko‘rsatilishi shart.';

  @override
  String get hsTelegramOptIn => 'Telegram orqali bog‘lanish';

  @override
  String hsYourUsername(String name) {
    return 'Sizning username: $name';
  }

  @override
  String get hsBody => 'E’lon matni';

  @override
  String get hsBodyHint =>
      'Ijara haqi, depozit, boshlanish sanasi, muddati va boshqa shartlarni yozing. Masalan: oyiga 500,000 won, depozit 5,000,000 won, avgust oyidan boshlab, kamida olti oyga. Kommunal alohida.';

  @override
  String get hsSubmit => 'E’lonni joylash';

  @override
  String get hsSave => 'O‘zgarishlarni saqlash';

  @override
  String get hsSaved => 'O‘zgarishlar saqlandi';

  @override
  String get hsPosted => 'E’loningiz joylandi';

  @override
  String get hsErrUsername =>
      '5-32 belgi: harflar, raqamlar va pastki chiziq. Harf bilan boshlansin.';

  @override
  String get hsErrContactRequired =>
      'Telefon raqami yoki Telegram — kamida bittasini ko‘rsating.';

  @override
  String get hsErrAddress => 'Manzilni koreys tilida, to‘liq yozing.';

  @override
  String get hsErrPhone => 'Telefon raqamini to‘g‘ri yozing.';

  @override
  String get hsErrBody => 'Matn kamida 20 ta belgidan iborat bo‘lsin.';

  @override
  String get hsErrUsernameEmpty =>
      'Username yozing yoki belgini olib tashlang.';

  @override
  String get hsErrGeocode => 'Manzil topilmadi. To‘liqroq yozib ko‘ring.';

  @override
  String get hsAlertsTitle => 'Bildirishnomalar';

  @override
  String get hsAlertsSub =>
      'Manzil va qidiruv radiusini kiriting. Shu radius ichida yangi e’lon qo‘yilsa, darhol xabar beramiz.';

  @override
  String get hsRadius => 'Qidiruv radiusi: shu masofadagi barcha e’lonlar';

  @override
  String get hsRadiusCustom => 'Yoki o‘zingiz kiriting';

  @override
  String get hsAdd => 'Qo‘shish';

  @override
  String get hsErrRadius => 'Doira 1 km dan 500 km gacha bo‘lsin.';

  @override
  String get hsAlertOff => 'O‘chirilgan — botni bloklagansiz';

  @override
  String hsAlertSent(String count) {
    return '$count ta xabar yuborilgan';
  }

  @override
  String get hsAlertDeleteConfirm => 'Bu bildirishnoma o‘chirilsinmi?';

  @override
  String get hsAlertAdded => 'Bildirishnoma qo‘shildi';

  @override
  String get hsAlertDeleted => 'Bildirishnoma o‘chirildi';

  @override
  String get hsAlertsEmptyTitle => 'Hozircha bildirishnoma yo‘q';

  @override
  String get hsAlertsEmptyBody =>
      'Yuqorida manzil yozib, qidiruv radiusini tanlang. Istalgancha bildirishnoma qo‘shishingiz mumkin.';

  @override
  String get hsSignInPostTitle => 'E’lon joylash uchun akkauntga kiring';

  @override
  String get hsSignInPostBody =>
      'E’lonlarni ko‘rish va raqamlarni ochish uchun kirish shart emas.';

  @override
  String get hsSignInAlertsTitle => 'Yangi e’lon chiqsa, xabar beramiz';

  @override
  String get hsSignInAlertsBody =>
      'Bildirishnoma uchun akkauntga kiring. Telefoningizga keladi.';

  @override
  String get hsSignIn => 'Akkauntga kirish';

  @override
  String get hsErrForbidden => 'Bu e’lon sizniki emas.';

  @override
  String get hsErrNotFound => 'E’lon topilmadi.';

  @override
  String get hsErrGone => 'E’lon o‘chirilgan yoki muddati tugagan.';

  @override
  String get hsErrGeoUnavailable =>
      'Manzil xizmati javob bermayapti. Birozdan keyin urinib ko‘ring.';

  @override
  String get hsErrUnavailable => 'Xizmat vaqtincha ishlamayapti.';

  @override
  String get hsErrServer => 'Serverda xatolik yuz berdi.';

  @override
  String hsErrRateSeconds(String count) {
    return 'Juda ko‘p urinish. $count soniyadan keyin qayta urining.';
  }

  @override
  String hsErrRateMinutes(String count) {
    return 'Juda ko‘p urinish. $count daqiqadan keyin qayta urining.';
  }

  @override
  String get hsErrNetwork => 'Serverga ulanib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get hsErrGeneric => 'Xatolik yuz berdi.';

  @override
  String get hsSending => 'Yuborilmoqda…';

  @override
  String get jbTitle => 'Ish e’lonlari guruhi';

  @override
  String get jbSubtitle =>
      'Muslim Vegukin foydalanuvchilari uchun maxsus xizmat';

  @override
  String get jbBotDoes => 'Muslim Vegukin tomonidan:';

  @override
  String get jbPoint1 =>
      '50 dan ortiq ish e’lon guruhlari sizning o‘rningizga kunda 24 soat kuzatib boriladi';

  @override
  String get jbPoint2 =>
      'Faqat ish bilan bog‘liq bo‘lgan e’lonlar ajratib olinadi';

  @override
  String get jbPoint3 =>
      'Barcha ajratib olingan e’lonlar shu zahoti “Ish e’lonlari” guruhida e’lon qilib boriladi';

  @override
  String get jbGetLink => 'Guruh linkini olish';

  @override
  String get jbLinkNote =>
      'Havola faqat siz uchun yaratiladi va 15 soniya amal qiladi';

  @override
  String get jbLinkLoading => 'Link yaratilmoqda…';

  @override
  String get jbSecondsLeft => 'soniya qoldi';

  @override
  String get jbYourLink => 'Sizning havolangiz:';

  @override
  String get jbJoin => 'Guruhga qo‘shilish';

  @override
  String get jbLinkWarning =>
      'Diqqat! Havola faqat 15 soniya davomida amal qiladi. Shoshiling!';

  @override
  String get jbExpiredTitle => 'Havola muddati tugadi';

  @override
  String get jbExpiredBody =>
      'Yangi havola olish uchun quyidagi tugmani bosing';

  @override
  String get jbRetry => 'Qayta urinish';

  @override
  String get jbErrorTitle => 'Xatolik yuz berdi';

  @override
  String get jbLinkError => 'Link yaratishda xatolik.';

  @override
  String get jbCopied => 'Nusxa olindi';

  @override
  String get jbPost => 'E’lon joylash';

  @override
  String get jbMyPosts => 'E’lonlarim';

  @override
  String get jbNewPost => 'Yangi e’lon';

  @override
  String get jbHowTitle => 'Bu qanday ishlaydi?';

  @override
  String get jbHow1 => 'Ish e’loningizni yozing va komissiya turini tanlang';

  @override
  String get jbHow2 =>
      'E’loningiz faqat Muslim Vegukin guruhiga joylanadi. Foydalanuvchilar siz bilan tez orada bog‘lanishadi';

  @override
  String get jbHow3 => 'Odam topilgach, e’lonni “Band” deb belgilang';

  @override
  String get jbHowCommission =>
      'Komissiya ixtiyoriy — o‘zingiz tanlaysiz. Tanlasangiz, ishni olgan har bir kishi sizga bir martalik 10,000 KRW to‘laydi';

  @override
  String get jbHowRule =>
      'Sharti: E’lon faqat Muslim Vegukin guruhida e’lon qilinib, boshqa guruhlarga joylanmasligi kerak';

  @override
  String get jbHowWait =>
      'Agar 2-3 soat ichida odam topilmasa, boshqa guruhlarda e’lon qilishingiz mumkin';

  @override
  String get jbEditing => 'E’lonni tahrirlash';

  @override
  String get jbCancel => 'Bekor qilish';

  @override
  String get jbText => 'E’lon matni';

  @override
  String get jbContact => 'Bog‘lanish uchun';

  @override
  String get jbRequired => 'majburiy';

  @override
  String get jbContactManual => 'Yoki telefon raqamni kiritish';

  @override
  String get jbContactBack => 'Telegram username ishlatish';

  @override
  String get jbContactHint => 'Tel raqam yoki Telegram username kiriting';

  @override
  String get jbCommission => 'Komissiya';

  @override
  String get jbCommissionPick => 'tanlang';

  @override
  String get jbWithCommission => 'Komissiyali';

  @override
  String get jbWithCommissionBody =>
      'Ishni olgan har bir kishi sizga bir martalik 10,000 KRW to‘laydi.';

  @override
  String get jbNoCommission => 'Komissiyasiz';

  @override
  String get jbFree => 'Bepul';

  @override
  String get jbNoCommissionBody =>
      'Hech qanday to‘lov talab qilinmaydi — faqat e’lon joylanadi.';

  @override
  String get jbPreview => 'E’lon ostida shunday ko‘rinadi:';

  @override
  String get jbFootYes =>
      '👉 Bu e’lon faqat shu guruhga qo‘yildi.\n👉 Ishga qatnashgan har bir kishi ish egasiga bir martalik komissiyani: 10,000 KRW ish haqini olish vaqtida to‘laydi.\n👉 E’lon egasiga murojaat qilish orqali siz ushbu to‘lovga rozilik bildirasiz.';

  @override
  String get jbFootNo =>
      '👉 Bu e’lon faqat shu guruhga qo‘yildi.\n👉 Bu e’lon uchun hech qanday komissiya olinmaydi.';

  @override
  String get jbAgree =>
      'Ushbu xabar ish bilan bog‘liq e’lonligini tasdiqlayman va boshqa Telegram guruhlarga 2-3 soat ichida joylamayman.';

  @override
  String get jbSubmit => 'E’lonni joylash';

  @override
  String get jbSave => 'O‘zgarishlarni saqlash';

  @override
  String get jbBanWarning =>
      'Reklama, shaxsiy xabarlar yoki ish bilan bog‘liq bo‘lmagan e’lonlar davomiy qo‘ygan foydalanuvchi bloklanadi.';

  @override
  String get jbSending => 'E’lon yuborilmoqda…';

  @override
  String get jbSaving => 'O‘zgarishlar saqlanmoqda…';

  @override
  String get jbSentTitle => 'E’lon yuborildi!';

  @override
  String get jbSentBody => 'E’loningiz guruhga muvaffaqiyatli joylandi.';

  @override
  String get jbSavedTitle => 'E’lon yangilandi!';

  @override
  String get jbSavedBody => 'O‘zgarishlar guruhdagi xabarga ham qo‘llanildi.';

  @override
  String get jbChipCommission => 'Komissiyali e’lon — 10,000 KRW';

  @override
  String get jbChipFree => 'Komissiyasiz e’lon';

  @override
  String get jbPostAgain => 'Yana e’lon joylash';

  @override
  String get jbPostError => 'E’lon yuborishda xatolik.';

  @override
  String get jbEmptyTitle => 'Hali e’lon joylamadingiz';

  @override
  String get jbEmptyAction => 'Birinchi e’lonni joylash';

  @override
  String get jbHintText => 'E’lon matni kamida 10 belgi bo‘lishi kerak';

  @override
  String get jbHintContact => 'Bog‘lanish uchun kontakt ma’lumotini kiriting';

  @override
  String get jbHintCommission => 'Komissiya turini tanlang';

  @override
  String get jbHintAgree => 'Qoidalarga rozilik belgisini qo‘ying';

  @override
  String get jbActive => 'Faol';

  @override
  String get jbReserved => 'Band';

  @override
  String get jbFinished => 'Bajarildi';

  @override
  String get jbReserve => 'Band qilish';

  @override
  String get jbReopen => 'Faol qilish';

  @override
  String get jbFinish => 'Yakunlash';

  @override
  String get jbDone => 'Ish bajarildi';

  @override
  String get jbEdit => 'Tahrirlash';

  @override
  String get jbDelete => 'O‘chirish';

  @override
  String jbFinishIn(int hours, int minutes) {
    return 'Yakunlash uchun: $hours soat $minutes daq. qoldi';
  }

  @override
  String get jbReserveText =>
      'Ishchi topildimi? E’lonni band sifatida belgilashni xohlaysizmi?';

  @override
  String get jbReopenTitle => 'Qayta faollashtirish';

  @override
  String get jbReopenText => 'E’lonni qayta faol holatga o‘tkazmoqchimisiz?';

  @override
  String get jbFinishText =>
      'Ish bajarildi deb belgilamoqchimisiz? Bu qaytarib bo‘lmaydi.';

  @override
  String get jbDeleteTitle => 'E’lonni o‘chirish';

  @override
  String get jbDeleteText =>
      'E’lon guruhdan ham, ro‘yxatingizdan ham butunlay o‘chiriladi. Davom etasizmi?';

  @override
  String get jbYes => 'Ha';

  @override
  String get jbJustNow => 'hozirgina';

  @override
  String jbMinutesAgo(int n) {
    return '$n daq. oldin';
  }

  @override
  String jbHoursAgo(int n) {
    return '$n soat oldin';
  }

  @override
  String jbDaysAgo(int n) {
    return '$n kun oldin';
  }

  @override
  String get jbErrNetwork => 'Tarmoq xatosi. Qayta urinib ko‘ring.';

  @override
  String get jbSignInTitle => 'E’lon joylash uchun kiring';

  @override
  String get jbSignInBody =>
      'E’lonlaringiz akkauntingizga bog‘lanadi: keyin ularni band qilish, tahrirlash yoki o‘chirish mumkin.';

  @override
  String get jbSignIn => 'Kirish';

  @override
  String get jbLoadFailed => 'E’lonlarni yuklab bo‘lmadi';

  @override
  String homeVisitsToday(String count) {
    return 'Today’s visits: $count';
  }

  @override
  String get ntTitle => 'Notifications';

  @override
  String get ntLoadError => 'Couldn’t load your subscriptions.';

  @override
  String get ntRetry => 'Try again';

  @override
  String get ntHelloSent => 'A test message is on its way. Check the bot.';

  @override
  String get ntBlocked =>
      'The bot can’t message you, so nothing reaches you in Telegram. Open the bot, tap “Start”, then check.';

  @override
  String get ntOpenBot => 'Open the bot';

  @override
  String get ntCheck => 'Check';

  @override
  String get ntEmptyTitle => 'Don’t miss a thing';

  @override
  String get ntEmptyBody => 'Be the first to know about changes.';

  @override
  String get ntEmptyAreaTitle => 'Watch an area';

  @override
  String get ntEmptyAreaBody =>
      'When places open, close or change around an address or your location';

  @override
  String get ntEmptyPlaceTitle => 'Watch a place';

  @override
  String get ntEmptyPlaceBody => 'Tap “Watch” on any place’s page';

  @override
  String get ntWhenTitle => 'When do messages arrive?';

  @override
  String get ntWhenNew => 'A new place opens';

  @override
  String get ntWhenClosed => 'A place closes';

  @override
  String get ntWhenPhone => 'Phone number changes';

  @override
  String get ntWhenName => 'Name changes';

  @override
  String get ntWhenOwner => 'The owner posts news';

  @override
  String get ntWhenMosque => 'A mosque posts news';

  @override
  String get ntAreasTitle => 'Areas';

  @override
  String get ntAreasAdd => 'Add area';

  @override
  String get ntCurrentLocation => 'My current location';

  @override
  String ntRadiusKm(int km) {
    return '$km km radius';
  }

  @override
  String get ntFromLocation => 'From my location';

  @override
  String ntInside(int n) {
    return '$n places now';
  }

  @override
  String get ntEdit => 'Edit';

  @override
  String get ntDelete => 'Delete';

  @override
  String get ntDeleteConfirm => 'Stop messages for this area?';

  @override
  String get ntAreaSaved => 'Area saved';

  @override
  String get ntAreaUpdated => 'Area updated';

  @override
  String get ntAreaDeleted => 'Area deleted';

  @override
  String get ntWatchTitle => 'Watched places';

  @override
  String get ntWatchHint => 'To watch a place, tap “Watch” on its page.';

  @override
  String get ntWatchRemoved => 'Removed from watched places';

  @override
  String get ntWatchStop => 'Stop watching';

  @override
  String get ntSheetAdd => 'Watch an area';

  @override
  String get ntSheetEdit => 'Edit area';

  @override
  String get ntMyLocation => 'My location';

  @override
  String get ntAddress => 'Address';

  @override
  String get ntAddressHint =>
      'The full address in Korean, with the building number';

  @override
  String get ntLocated => 'Located just now';

  @override
  String get ntLocating => 'Finding your location…';

  @override
  String get ntSavedCenter => 'Saved centre';

  @override
  String get ntRelocate => 'Update';

  @override
  String get ntFind => 'Find';

  @override
  String get ntFinding => 'Looking up the address…';

  @override
  String get ntNothingInside => 'No places in this radius yet';

  @override
  String get ntLocationFailed =>
      'Couldn’t get your location. Enter an address or try again.';

  @override
  String get ntRadius => 'Radius';

  @override
  String ntCountMosque(int n) {
    return 'Mosques: $n';
  }

  @override
  String ntCountRestaurant(int n) {
    return 'Restaurants: $n';
  }

  @override
  String ntCountShop(int n) {
    return 'Shops: $n';
  }

  @override
  String get ntWhich => 'Which places?';

  @override
  String get ntPickOne => 'Choose at least one type.';

  @override
  String get ntNote =>
      'You’ll hear when a place opens, closes, changes its phone or name, or posts news.';

  @override
  String get ntSave => 'Save';

  @override
  String get ntErrAddressNotFound =>
      'That address wasn’t found. Try writing it more precisely, in Korean.';

  @override
  String get ntErrRateLimited =>
      'Too many requests. Please try again in a minute.';

  @override
  String get ntErrTooManyAreas =>
      'Too many areas. Delete the ones you don’t need.';

  @override
  String get ntErrAreaBudget =>
      'Your areas cover too much ground. Make one smaller or delete one.';

  @override
  String get ntErrTooManyChanges =>
      'Too many area changes today. Try again tomorrow.';

  @override
  String get ntErrTooManyPreviews =>
      'Too many different places looked at today. Try again tomorrow.';

  @override
  String get ntErrOffline => 'Couldn’t connect. Please try again.';

  @override
  String get ntErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get ntWhereTitle => 'Where do messages arrive?';

  @override
  String get ntViaApp => 'In the app';

  @override
  String get ntViaAppBody => 'A notification on your phone';

  @override
  String get ntViaBot => 'In the Telegram bot';

  @override
  String get ntViaBotBody => 'A message from the Muslim Vegukin bot';

  @override
  String get ntViaOne => 'Keep at least one on.';

  @override
  String get ntAppOnly => 'Messages arrive in this app as notifications.';

  @override
  String get ntAppOnlyHint =>
      'Sign in with Telegram to get them in the bot too.';

  @override
  String get ntPushOff =>
      'Notifications are off on this phone — you won’t see the messages.';

  @override
  String get ntPushOn => 'Turn on';

  @override
  String get ntStoppedPlace => 'Messages for this place are off.';

  @override
  String get ntStoppedArea => 'Messages for this area are off.';

  @override
  String get ntUndo => 'Undo';

  @override
  String get ntTypeMosque => 'Mosque';

  @override
  String get ntTypeRestaurant => 'Restaurant';

  @override
  String get ntTypeShop => 'Shop';

  @override
  String get ntTypesMosque => 'Mosques';

  @override
  String get ntTypesRestaurant => 'Restaurants';

  @override
  String get ntTypesShop => 'Shops';

  @override
  String get ntErrAddressNotExact =>
      'Enter the full address with the building or house number, e.g. 서울 동대문구 회기로 56';

  @override
  String get ntFound => 'Found';

  @override
  String get ntDeliveryTooltip => 'Where messages arrive';

  @override
  String get accountMine => 'Messages & watches';

  @override
  String get accountPlacesWatches => 'Places & areas';

  @override
  String accountAreas(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count areas',
      one: '1 area',
    );
    return '$_temp0';
  }

  @override
  String accountPlaces(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get accountNoneYet => 'None yet';

  @override
  String get accountHikoreaWatches => 'HiKorea watches';

  @override
  String get accountOnPhone => 'On this phone';

  @override
  String get accountOn => 'On';

  @override
  String get accountOff => 'Off';

  @override
  String get accountReminders => 'Prayer reminders';

  @override
  String accountRemindersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prayers',
      one: '1 prayer',
    );
    return '$_temp0';
  }

  @override
  String get accountTestTitle => 'Test message';

  @override
  String get accountTestToPhone => 'Goes to this phone.';

  @override
  String get accountTestToBoth => 'Goes to this phone and to the Telegram bot.';

  @override
  String get accountTestSend => 'Send';

  @override
  String get accountTestWaiting => 'Waiting for it on this phone…';

  @override
  String get accountTestArrived => 'Arrived on this phone';

  @override
  String get accountTestNotArrived => 'Didn’t arrive on this phone';

  @override
  String get accountTestNotArrivedHelp =>
      'In the phone’s settings, check that Muslim Vegukin’s notifications are on and battery saving doesn’t restrict the app.';

  @override
  String get accountTestCheckShade => 'Look in the phone’s notification panel';

  @override
  String get accountTestNoToken =>
      'This phone isn’t registered yet. Check the internet and reopen the app.';

  @override
  String get accountTestServerFailed =>
      'The server couldn’t send it. Try again in a moment.';

  @override
  String get accountTestBotSent => 'Sent to the Telegram bot';

  @override
  String get accountTestBotBlocked =>
      'The bot can’t write to you: open it and tap Start.';

  @override
  String get accountTestBotFailed => 'Couldn’t send to the Telegram bot';

  @override
  String get accountOpenBot => 'Open the bot';

  @override
  String get accountSettings => 'Settings';

  @override
  String get accountAlarmsTitle => 'Prayer reminders may come late';

  @override
  String get accountAlarmsBody =>
      'Allow “Alarms & reminders” so they come right on time.';

  @override
  String get accountAllow => 'Allow';

  @override
  String get accountShare => 'Share the app';

  @override
  String accountShareText(Object link) {
    return 'Muslim Vegukin — for Muslims in Korea: prayer times, qibla, halal places, HiKorea appointments and more.\n$link';
  }

  @override
  String get accountFeedback => 'Suggest an idea or report a bug';

  @override
  String accountVersion(Object version) {
    return 'Version $version';
  }
}
