// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get tagline => 'Koreyadagi musulmonlar uchun';

  @override
  String get greetingLabel => 'Assalomu alaykum';

  @override
  String get languageQuestion => 'Qaysi tilda davom etamiz?';

  @override
  String get languageNote => 'Barcha bo‘limlar mavjud';

  @override
  String get continueAction => 'Davom etish';

  @override
  String get saveAction => 'Saqlash';

  @override
  String get changeLaterHint =>
      'Tilni keyinroq sozlamalardan o‘zgartirish mumkin';

  @override
  String get changeLanguage => 'Tilni o‘zgartirish';

  @override
  String get prayerFajr => 'Bomdod';

  @override
  String get prayerSunrise => 'Quyosh';

  @override
  String get prayerDhuhr => 'Peshin';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Shom';

  @override
  String get prayerIsha => 'Xufton';

  @override
  String get untilFajr => 'Bomdodgacha';

  @override
  String get untilFajrEnds => 'Bomdod tugashiga';

  @override
  String get untilDhuhr => 'Peshingacha';

  @override
  String get untilAsr => 'Asrgacha';

  @override
  String get untilMaghrib => 'Shomgacha';

  @override
  String get untilIsha => 'Xuftongacha';

  @override
  String get locationPlaceholder => 'Joylashuv';

  @override
  String get locating => 'Aniqlanmoqda…';

  @override
  String get locationJustNow => 'Hozirgina';

  @override
  String locationMinutesAgo(int count) {
    return '$count daqiqa oldin';
  }

  @override
  String locationHoursAgo(int count) {
    return '$count soat oldin';
  }

  @override
  String locationDaysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String get locationFailedShort => 'Aniqlab bo‘lmadi';

  @override
  String get refreshLocation => 'Joylashuvni yangilash';

  @override
  String get locationNeededTitle => 'Namoz vaqtlari uchun joylashuv kerak';

  @override
  String get locationNeededBody =>
      'Vaqtlar shahringiz bo‘yicha hisoblanadi. Joylashuv faqat shu uchun ishlatiladi.';

  @override
  String get useMyLocation => 'Joylashuvni aniqlash';

  @override
  String get locationDeniedBody =>
      'Ilovaga joylashuvga ruxsat berilmagan. Uni ilova sozlamalarida yoqing.';

  @override
  String get openSettings => 'Sozlamalarni ochish';

  @override
  String get locationOffBody => 'Telefonda joylashuv (GPS) o‘chirilgan.';

  @override
  String get turnOnLocation => 'Yoqish';

  @override
  String get locationFailedBody => 'Joylashuvni aniqlab bo‘lmadi.';

  @override
  String get timesFailedBody =>
      'Namoz vaqtlarini yuklab bo‘lmadi. Internetni tekshiring.';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get newBadge => 'Yangi';

  @override
  String get uzOnlyHint => 'Faqat o‘zbek tilida';

  @override
  String get featurePrayers => 'Namoz vaqtlari';

  @override
  String get featureMosques => 'Masjidlar';

  @override
  String get featureRestaurants => 'Oshxonalar';

  @override
  String get featureShops => 'Do‘konlar';

  @override
  String get featureNotifications => 'Bildirishnomalar';

  @override
  String get featureQibla => 'Qibla';

  @override
  String get featureQna => 'Zikr ahlidan so‘rang';

  @override
  String get featureBarcode => 'Mahsulot tarkibini tekshirish';

  @override
  String get featureHousing => 'Uy-joy e’lonlari';

  @override
  String get featureCars => 'Vegukin Cars';

  @override
  String get featureHikorea => 'Immigratsiya xizmatlari';

  @override
  String get featureJobs => 'Ish e’lonlari';

  @override
  String get featureParcel => 'Pochta';

  @override
  String get featureLinks => 'Foydali linklar';

  @override
  String get featureDonation => 'Qo‘llab-quvvatlash';

  @override
  String get featureCommunity => 'Jamoa';

  @override
  String get featureBusiness => 'Biznes Katalogi';

  @override
  String get businessTagline => 'Koreyadagi o‘zbek bizneslari';

  @override
  String businessCount(int count) {
    return '$count ta biznes';
  }

  @override
  String categoryCount(int count) {
    return '$count ta yo‘nalish';
  }

  @override
  String get webLoadFailed => 'Sahifani ochib bo‘lmadi. Internetni tekshiring.';

  @override
  String get webReload => 'Yangilash';

  @override
  String get webOpenInBrowser => 'Brauzerda ochish';

  @override
  String get cameraDenied => 'Kameraga ruxsat berilmagan';

  @override
  String get widgetOpenApp => 'Namoz vaqtlari uchun ilovani oching';
}
