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

  @override
  String get exactAlarmsTitle => 'Aniq vaqt uchun ruxsat';

  @override
  String get exactAlarmsBody =>
      'Namoz eslatmalari va bosh ekrandagi vidjet aynan o‘z vaqtida ishlashi uchun keyingi sahifada «Signal va eslatmalar»ni yoqing.';

  @override
  String get exactAlarmsAllow => 'Davom etish';

  @override
  String get exactAlarmsLater => 'Keyinroq';

  @override
  String get prayersTitle => 'Namoz vaqtlari';

  @override
  String get nextPrayer => 'Keyingi namoz';

  @override
  String get remaining => 'qoldi';

  @override
  String get suhoorLabel => 'Saharlik (oxiri)';

  @override
  String get iftarLabel => 'Iftorlik';

  @override
  String get chipNow => 'hozir';

  @override
  String get chipNext => 'keyingi';

  @override
  String get fastWindow => 'Ro‘za vaqti · Saharlikdan Iftorlikkacha';

  @override
  String get dayToday => 'Bugun';

  @override
  String get dayTomorrow => 'Ertaga';

  @override
  String get dayYesterday => 'Kecha';

  @override
  String get previousDay => 'Oldingi kun';

  @override
  String get nextDay => 'Keyingi kun';

  @override
  String get backToToday => 'Bugunga qaytish';

  @override
  String get dayLoading => 'Yuklanmoqda...';

  @override
  String get dayLoadFailed => 'Yuklab bo‘lmadi';

  @override
  String get commentFajr => 'Xufton vaqti tugaydi';

  @override
  String get commentSunrise => 'Bomdod vaqti tugaydi';

  @override
  String get commentAsr => 'Peshin vaqti tugaydi';

  @override
  String get commentMaghrib => 'Asr vaqti tugaydi';

  @override
  String get commentIsha => 'Shom vaqti tugaydi';

  @override
  String get settingsShort => 'Sozlamalar';

  @override
  String get settingsTitle => 'Namoz sozlamalari';

  @override
  String get settingsSubtitle => 'Hisoblash usuli va mazhabingizni tanlang';

  @override
  String get methodLabel => 'Hisoblash usuli';

  @override
  String get madhabLabel => 'Mazhab (Asr vaqti uchun)';

  @override
  String get schoolHanafi => 'Hanafiy';

  @override
  String get schoolShafii => 'Shofe’iy / Molikiy / Hanbaliy';

  @override
  String get schoolShafiiShort => 'Shofe’iy';

  @override
  String get hanafiNote => 'Soya = 2x uzunlik';

  @override
  String get shafiiNote => 'Soya = 1x uzunlik';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodKarachi => 'Karachi';

  @override
  String get methodMakkah => 'Makka';

  @override
  String get methodEgypt => 'Misr';

  @override
  String get methodIsna => 'ISNA';

  @override
  String get methodMwlHint => 'Bomdod 18°, Xufton 17°';

  @override
  String get methodKarachiHint => 'Bomdod 18°, Xufton 18°';

  @override
  String get methodMakkahHint =>
      'Bomdod 18.5°, Xufton - Shomdan 90 daqiqa keyin';

  @override
  String get methodEgyptHint => 'Bomdod 19.5°, Xufton 17.5°';

  @override
  String get methodIsnaHint => 'Bomdod 15°, Xufton 15°';

  @override
  String get naflTitle => 'Nafl namoz vaqtlari';

  @override
  String get tahajjudName => 'Tahajjud namozi';

  @override
  String get tahajjudText =>
      'Xuftondan keyin, uyqudan so‘ng o‘qiladigan nafl namoz. Ozi 2 rakat, ko‘pi 8 rakat. Eng afzal vaqti - kechaning oxirgi uchdan biri. Duolar qabul bo‘ladigan vaqt.';

  @override
  String get tahajjudQuote =>
      'U Robbingizga qurbatdir, yomonliklarga kafforotdir, gunohlarni qaytaruvchidir.';

  @override
  String get tahajjudSource => 'Manba: Termiziy - Abu Umoma (r.a.)';

  @override
  String get ishraqName => 'Shuruq (Ishroq) namozi';

  @override
  String get ishraqQuote =>
      'Kim bomdodni jamoat bilan o‘qisa, so‘ngra quyosh chiqquncha Allohni zikr qilib o‘tirsa, keyin ikki rakat namoz o‘qisa, uning uchun haj va umraning ajridek bo‘lur.';

  @override
  String get ishraqSource =>
      'Manba: Termiziy - Muoz ibn Anas al-Juhaniy (r.a.)';

  @override
  String get duhaName => 'Zuho (Choshgoh) namozi';

  @override
  String get duhaText =>
      'Quyosh bir nayza bo‘yi ko‘tarilganda kirib, zavolga bir soat qolguncha davom etadi. Afzali 4 rakat o‘qish. Eng afzal vaqti - nahorning to‘rtdan biri o‘tgandan keyin.';

  @override
  String get duhaQuote =>
      'Kim choshgoh namozini bardavom o‘qisa, uning gunohlari dengiz ko‘pigicha bo‘lsa ham mag‘firat qilinadi.';

  @override
  String get duhaSource => 'Manba: Termiziy - Abu Hurayra (r.a.)';

  @override
  String get statusNow => 'Ayni vaqti';

  @override
  String get statusUpcoming => 'Kutilmoqda';

  @override
  String get statusPassed => 'Vaqti o‘tdi';

  @override
  String get statusOtherDay => 'Boshqa kun';

  @override
  String get reminderHint =>
      'Har bir namoz uchun eslatmani qo‘ng‘iroqcha orqali sozlang';

  @override
  String reminderFor(String name) {
    return '$name: eslatma';
  }

  @override
  String reminderToday(String range) {
    return 'Bugun: $range';
  }

  @override
  String get reminderHow => 'Qanday eslatilsin';

  @override
  String get reminderWhen => 'Qachon';

  @override
  String get reminderOff => 'O‘chiq';

  @override
  String get reminderOffHint => 'Eslatmasin';

  @override
  String get reminderSilent => 'Jim';

  @override
  String get reminderSilentHint => 'Faqat bildirishnoma';

  @override
  String get reminderVibrate => 'Tebranish';

  @override
  String get reminderVibrateHint => 'Ovozsiz, tebranadi';

  @override
  String get reminderSound => 'Ovoz';

  @override
  String get reminderSoundHint => 'Qisqa, yoqimli ohang';

  @override
  String get reminderPlay => 'Eshitib ko‘rish';

  @override
  String get reminderAt => 'Eslatma vaqti';

  @override
  String get reminderDone => 'Tayyor';

  @override
  String get offsetOnTime => 'Vaqtida';

  @override
  String offsetBefore(String duration) {
    return '$duration oldin';
  }

  @override
  String offsetAfter(String duration) {
    return '$duration keyin';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes daq';
  }

  @override
  String durationHours(int hours) {
    return '$hours soat';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours soat $minutes daq';
  }

  @override
  String get notificationsOff =>
      'Bildirishnomalar o‘chiq — eslatmalar kelmaydi';

  @override
  String get notificationsTurnOn => 'Yoqish';

  @override
  String notifyAt(String name) {
    return '$name vaqti kirdi';
  }

  @override
  String notifyBefore(String name, String duration) {
    return '$name vaqtiga $duration qoldi';
  }

  @override
  String notifyAfter(String name, String duration) {
    return '$name vaqti kirganiga $duration bo‘ldi';
  }

  @override
  String get notifySunriseAt => 'Quyosh chiqdi — Bomdod vaqti tugadi';

  @override
  String notifySunriseBefore(String duration) {
    return 'Bomdod vaqti tugashiga $duration qoldi';
  }

  @override
  String notifySunriseAfter(String duration) {
    return 'Quyosh chiqqaniga $duration bo‘ldi';
  }

  @override
  String get notifyImsakAt => 'Saharlik vaqti tugadi';

  @override
  String notifyImsakBefore(String duration) {
    return 'Saharlik tugashiga $duration qoldi';
  }

  @override
  String notifyImsakAfter(String duration) {
    return 'Saharlik tugaganiga $duration bo‘ldi';
  }

  @override
  String notifyBody(String name, String start, String end, String city) {
    return '$name: $start – $end · $city';
  }

  @override
  String get suhoorShort => 'Saharlik';
}
