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

  @override
  String get qiblaTitle => 'Qibla yo‘nalishi';

  @override
  String get qiblaPreparing => 'Kompas tayyorlanmoqda...';

  @override
  String get qiblaHoldFlat => 'Qurilmangizni tekis ushlang';

  @override
  String get qiblaHoldFlatShort => 'Telefonni tekis ushlang';

  @override
  String get qiblaNoLocation =>
      'Qibla yo‘nalishini hisoblash uchun joylashuvingiz kerak.';

  @override
  String get qiblaNoCompassTitle => 'Kompas topilmadi';

  @override
  String get qiblaNoCompass => 'Bu qurilmada kompas sensori mavjud emas.';

  @override
  String get qiblaNorth => 'Shimol';

  @override
  String get qiblaEast => 'Sharq';

  @override
  String get qiblaSouth => 'Janub';

  @override
  String get qiblaWest => 'G‘arb';

  @override
  String get qiblaDirection => 'Yo‘nalish';

  @override
  String get qiblaAngle => 'Qibla burchagi';

  @override
  String get qiblaLocation => 'Joylashuv';

  @override
  String get qiblaToMakkah => 'Makkagacha';

  @override
  String get qiblaSignal => 'Kompas signali';

  @override
  String get qiblaQualityExcellent => 'A’lo';

  @override
  String get qiblaQualityGood => 'Yaxshi';

  @override
  String get qiblaQualityMedium => 'O‘rtacha';

  @override
  String get qiblaQualityPoor => 'Yomon';

  @override
  String get qiblaNeedsCalibration => 'Kalibratsiya kerak';

  @override
  String get qiblaInterference => 'Yaqinda metall yoki elektronika bor';

  @override
  String qiblaAccuracy(int degrees) {
    return '±$degrees°';
  }

  @override
  String qiblaDeclination(String degrees) {
    return 'Magnit og‘ishi $degrees° hisobga olingan';
  }

  @override
  String get qiblaTipsTitle => 'Aniqroq natija uchun';

  @override
  String get qiblaTip1 => 'Telefonni gorizontal (tekis) ushlang';

  @override
  String get qiblaTip2 => 'Metall buyumlardan uzoqroq turing';

  @override
  String get qiblaTip3 => 'Elektron qurilmalardan uzoqlashing';

  @override
  String get qiblaTip4 => 'Ochiq maydonlarda ishlating';

  @override
  String get qiblaTip5 =>
      'Kamera rejimida telefonni tik ushlang va Ka’ba belgisini markazga keltiring';

  @override
  String get qiblaAligned => 'Qiblaga to‘g‘ri yuzlangansiz!';

  @override
  String get qiblaSlightlyRight => 'Biroz o‘ngga buriling';

  @override
  String get qiblaSlightlyLeft => 'Biroz chapga buriling';

  @override
  String get qiblaTurnRight => 'O‘ngga buriling';

  @override
  String get qiblaTurnLeft => 'Chapga buriling';

  @override
  String get qiblaModeCompass => 'Kompas';

  @override
  String get qiblaModeCamera => 'Kamera';

  @override
  String get qiblaHoldUpright => 'Telefonni tik ushlang';

  @override
  String get qiblaCameraFailed => 'Kamerani ochib bo‘lmadi';

  @override
  String get qiblaSunTitle => 'Quyosh bo‘yicha tekshirish';

  @override
  String qiblaSunRight(int sun, int angle) {
    return 'Quyosh hozir $sun° da. Quyoshga yuzlanib, $angle° o‘ngga burilsangiz — Qibla.';
  }

  @override
  String qiblaSunLeft(int sun, int angle) {
    return 'Quyosh hozir $sun° da. Quyoshga yuzlanib, $angle° chapga burilsangiz — Qibla.';
  }

  @override
  String qiblaSunAhead(int sun) {
    return 'Quyosh hozir $sun° da — aynan Qibla tomonda.';
  }

  @override
  String get qiblaSunDown =>
      'Quyosh ufqdan pastda. Kunduzi Qiblani quyosh bo‘yicha ham tekshirish mumkin — magnitlar unga ta’sir qilmaydi.';

  @override
  String qiblaSunOverKaaba(String when) {
    return 'Quyosh Ka’ba ustida bo‘ladi: $when. O‘sha daqiqada soyalar Qibladan teskari tomonga tushadi.';
  }

  @override
  String get qiblaPhaseMove => 'Harakat';

  @override
  String get qiblaPhaseHold => 'Barqarorlik';

  @override
  String get qiblaCalibrateTitle => 'Kompasni kalibratsiya qiling';

  @override
  String get qiblaCalibrateMove =>
      'Telefonni bilakni burab ∞ shaklida aylantiring — faqat surmang.';

  @override
  String get qiblaCalibrateHold =>
      'Pufakchani markazda ushlab, qimirlamay turing.';

  @override
  String qiblaMovements(int count, int total) {
    return '$count/$total harakat';
  }

  @override
  String get qiblaCalMoving => 'Telefonni ∞ shaklida harakatlantiring...';

  @override
  String get qiblaCalGood => 'Yaxshi! Davom eting...';

  @override
  String get qiblaCalHoldStill =>
      'Endi telefonni tekis ushlab, qimirlatmang...';

  @override
  String get qiblaCalChecking => 'Barqarorlik tekshirilmoqda...';

  @override
  String get qiblaCalDone => '✓ Kalibratsiya tayyor!';

  @override
  String get qiblaCalibrateShort => 'Kalibrlash';

  @override
  String get qiblaSkip => 'O‘tkazib yuborish';

  @override
  String get qiblaUndo => 'Bekor qilish';

  @override
  String get qiblaSunMarker => 'Quyosh';

  @override
  String get qiblaSunTapHint =>
      'Quyosh doirada emasmi? Haqiqiy quyoshga bosing';

  @override
  String get qiblaSunNotThere =>
      'Quyoshning o‘ziga bosing: u punktir chiziqda turadi';

  @override
  String qiblaSunCorrected(String degrees) {
    return 'Quyosh bo‘yicha tuzatildi: $degrees°';
  }

  @override
  String get qiblaSunCheckCamera => 'Kamerada tekshirish';

  @override
  String get parcelTitle => 'Pochta yuborish';

  @override
  String get parcelTagline => 'Kuryer topib, pochtangizni yetkazing';

  @override
  String get parcelFrom => 'Qayerdan';

  @override
  String get parcelTo => 'Qayerga';

  @override
  String get parcelSwap => 'Yo‘nalishni almashtirish';

  @override
  String get parcelUzbekistan => 'O‘zbekiston';

  @override
  String get parcelKorea => 'Koreya';

  @override
  String get parcelUzbToKor => 'O‘zbekistondan Koreyaga';

  @override
  String get parcelKorToUzb => 'Koreyadan O‘zbekistonga';

  @override
  String get parcelByDate => 'Sana bo‘yicha';

  @override
  String get parcelByCity => 'Shahar bo‘yicha';

  @override
  String parcelPostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta e’lon',
    );
    return '$_temp0';
  }

  @override
  String get parcelNoDates => 'Bu yo‘nalishda hozircha e’lonlar yo‘q';

  @override
  String get parcelNoPosts => 'E’lonlar topilmadi';

  @override
  String get parcelNoCities => 'Shaharlar topilmadi';

  @override
  String parcelSeeOther(String route) {
    return 'Boshqa yo‘nalish: $route';
  }

  @override
  String get parcelError =>
      'Ma’lumotni yuklab bo‘lmadi. Internetni tekshirib, qaytadan urinib ko‘ring.';

  @override
  String get parcelHowTitle => 'Qanday ishlaydi?';

  @override
  String get parcelHow1 => 'Yo‘nalish va qidiruv usulini tanlang';

  @override
  String get parcelHow2 => 'E’lonni ko‘rib chiqing va kuryer bilan bog‘laning';

  @override
  String get parcelHow3 => 'Pochtangizni xavfsiz yetkazing!';

  @override
  String get parcelWriteTelegram => 'Telegramda yozish';

  @override
  String get parcelCall => 'Qo‘ng‘iroq qilish';

  @override
  String get parcelContactInText => 'Kuryer kontakti xabarda ko‘rsatilgan';

  @override
  String get parcelShowMore => 'Ko‘proq';

  @override
  String get parcelShowLess => 'Yig‘ish';

  @override
  String get parcelSearchCity => 'Shaharni qidirish';

  @override
  String get parcelNoticeTitle => 'Ehtiyot bo‘ling';

  @override
  String get parcelNotice =>
      'Bu e’lonlar Telegram guruhlaridan olinadi. Biz kuryerlar bilan bog‘liq emasmiz — faqat ularning e’lonlarini ko‘rsatamiz. Orada firibgarlar ham bo‘lishi mumkin. Yuzaga kelgan har qanday zarar uchun javobgar emasmiz.';

  @override
  String get parcelNoticeShort =>
      'E’lonlar Telegram guruhlaridan. Biz kuryerlar bilan bog‘liq emasmiz.';

  @override
  String get parcelNoticeOk => 'Tushundim';

  @override
  String get parcelWaking => 'Server ishga tushmoqda, biroz kuting…';

  @override
  String get parcelOffline =>
      'Internet aloqasi yo‘q. Oxirgi yuklangan e’lonlar ko‘rsatilmoqda.';

  @override
  String get parcelSearch => 'Qidirish';

  @override
  String get parcelSearchPosts => 'E’lonlardan qidirish';

  @override
  String parcelSearching(int done, int total) {
    return 'Qidirilmoqda… $done/$total kun';
  }

  @override
  String get parcelNothingFound => 'Hech narsa topilmadi';

  @override
  String get parcelSavedTitle => 'Saqlangan e’lonlar';

  @override
  String get parcelSave => 'Saqlash';

  @override
  String get parcelUnsave => 'Saqlanganlardan olib tashlash';

  @override
  String get parcelSavedEmpty =>
      'Hozircha saqlangan e’lon yo‘q. E’londagi belgini bosib saqlang.';

  @override
  String get parcelRemoved => 'Olib tashlandi';

  @override
  String get parcelUndo => 'Bekor qilish';

  @override
  String get parcelShare => 'Ulashish';

  @override
  String get parcelEnd => 'Boshqa e’lonlar yo‘q';

  @override
  String parcelDraft(String route, String date) {
    return 'Assalomu alaykum! $route reysingiz ($date) bo‘yicha pochta haqida yozyapman.';
  }

  @override
  String parcelDraftNoDate(String route) {
    return 'Assalomu alaykum! $route reysingiz bo‘yicha pochta haqida yozyapman.';
  }

  @override
  String get linksTitle => 'Foydali linklar';

  @override
  String linksSubtitle(int count) {
    return '$count ta Telegram guruh va kanal';
  }

  @override
  String get linksSearch => 'Guruh, shahar yoki mavzu';

  @override
  String get linksJobs => 'Ish';

  @override
  String get linksLife => 'Koreya hayoti';

  @override
  String get linksGroups => 'Guruhlar';

  @override
  String get linksFavorites => 'Sevimlilar';

  @override
  String get linksNearest => 'Yaqinlik';

  @override
  String get linksByRegion => 'Hududlar';

  @override
  String linksYourPlace(String city) {
    return 'Joylashuvingiz: $city';
  }

  @override
  String get linksLocate =>
      'Joylashuvni aniqlang — yaqin guruhlar birinchi chiqadi';

  @override
  String get linksLocateButton => 'Aniqlash';

  @override
  String get linksNationwide => 'Butun Koreya';

  @override
  String get linksNearby => 'Yaqin atrofda';

  @override
  String get linksFarther => 'Boshqa shaharlar';

  @override
  String get linksRegionCapital => 'Seul va Gyeonggi';

  @override
  String get linksRegionChungcheong => 'Chungcheong';

  @override
  String get linksRegionJeolla => 'Jeolla';

  @override
  String get linksRegionGyeongsang => 'Gyeongsang';

  @override
  String get linksOther => 'Boshqalar';

  @override
  String get linksTopicOfficial => 'Rasmiy';

  @override
  String get linksTopicNews => 'Yangiliklar va ma’lumot';

  @override
  String get linksTopicLegal => 'Huquq va vizalar';

  @override
  String get linksTopicInsurance => 'Sug‘urta';

  @override
  String get linksTopicWork => 'Ish va karyera';

  @override
  String get linksTopicEveryday => 'Kundalik hayot';

  @override
  String get linksForEveryone => 'Umumiy';

  @override
  String get linksForWomen => 'Ayollar uchun';

  @override
  String get linksOurs => 'Bizning guruh: taklif va savollar uchun';

  @override
  String get linksSuggestTitle => 'Guruhingiz ro‘yxatda yo‘qmi?';

  @override
  String get linksSuggestBody => 'Muslim Vegukin guruhiga yozing, qo‘shamiz.';

  @override
  String get linksOpen => 'Telegramda ochish';

  @override
  String get linksCopy => 'Havolani nusxalash';

  @override
  String get linksCopied => 'Havola nusxalandi';

  @override
  String get linksShare => 'Ulashish';

  @override
  String get linksFavorite => 'Sevimlilarga qo‘shish';

  @override
  String get linksUnfavorite => 'Sevimlilardan olib tashlash';

  @override
  String get linksNothing => 'Hech narsa topilmadi';

  @override
  String linksResults(int count) {
    return '$count ta natija';
  }

  @override
  String get donationTitle => 'Xayriya';

  @override
  String get donationHeroTitle => 'Loyiha faoliyatini qo‘llab-quvvatlang';

  @override
  String get donationHeroSubtitle =>
      'Yordamingiz bilan loyiha yanada rivojlanadi';

  @override
  String get donationMessage =>
      'Agar Muslim Vegukin sizga foydali bo‘layotgan bo‘lsa va uning ishlashi hamda rivojlanishiga o‘z hissangizni qo‘shmoqchi bo‘lsangiz, quyidagi hisob raqamga istalgan miqdorda moddiy mablag‘laringizni yuborishingiz mumkin.';

  @override
  String get donationName => 'Ism';

  @override
  String get donationAccount => 'Hisob raqam';

  @override
  String get donationCopied => 'Nusxa olindi!';

  @override
  String get donationUsageTitle =>
      'Yig‘ilgan mablag‘lar quyidagilar uchun ishlatiladi';

  @override
  String get donationUsage1 => 'Server va hosting xarajatlari';

  @override
  String get donationUsage2 => 'Texnik xizmat va muntazam yangilanishlar';

  @override
  String get donationUsage3 =>
      'Dasturchilar mehnati va loyihani rivojlantirish';

  @override
  String get donationThanksText =>
      'Sizning har qanday hissangiz biz uchun katta ahamiyatga ega!';

  @override
  String get donationThanks => 'Rahmat!';

  @override
  String get communityTitle => 'Jamoa';

  @override
  String get communityHeroTitle => 'Rasmiy Telegram Guruhi';

  @override
  String get communityHeroSubtitle => 'Foydalanuvchilar jamiyati';

  @override
  String get communityJoinNow => 'Hoziroq qo‘shiling';

  @override
  String get communityPurposeTitle => 'Guruh maqsadi';

  @override
  String get communityPurposeText =>
      'Ushbu guruh Muslim Vegukin foydalanuvchilari uchun rasmiy muhokama maydonidir. Bu yerda loyiha bilan bog‘liq barcha masalalarni muhokama qilishingiz mumkin.';

  @override
  String get communityAllowedTitle => 'Guruh muhokama mavzulari';

  @override
  String get communityTopicPlaceTitle => 'Yangi manzillar haqida xabar berish';

  @override
  String get communityTopicPlaceBody =>
      'Yangi masjid, restoran yoki do‘kon qo‘shilishi kerak bo‘lsa';

  @override
  String get communityTopicIdeaTitle => 'Takliflar va g‘oyalar';

  @override
  String get communityTopicIdeaBody =>
      'Muslim Vegukinni yaxshilash uchun fikrlaringiz';

  @override
  String get communityTopicBugTitle => 'Xatolar haqida xabar berish';

  @override
  String get communityTopicBugBody => 'Agar biror muammo topsangiz';

  @override
  String get communityTopicNewsTitle => 'Loyiha yangiliklari';

  @override
  String get communityTopicNewsBody =>
      'Yangi funksiyalar va o‘zgarishlar haqida e’lonlar';

  @override
  String get communityTopicBetaTitle => 'Beta versiyalar muhokamasi';

  @override
  String get communityTopicBetaBody =>
      'Yangi funksiyalarni ommaga chiqarishdan oldin sinab ko‘rish';

  @override
  String get communityTopicQuestionTitle => 'Muslim Vegukin haqida savollar';

  @override
  String get communityTopicQuestionBody =>
      'Qanday ishlatish, funksiyalar haqida';

  @override
  String get communityTopicPeopleTitle => 'Jamiyat bilan muloqot';

  @override
  String get communityTopicPeopleBody =>
      'Boshqa foydalanuvchilar bilan tajriba almashish';

  @override
  String get communityRulesTitle => 'Guruh qoidalari';

  @override
  String get communityRulesWarning =>
      'Quyidagi turdagi xabarlar o‘chirib tashlanadi';

  @override
  String get communityBanned1Title => 'Reklama va savdo e’lonlari';

  @override
  String get communityBanned1Body =>
      'Har qanday turdagi sotish yoki xarid e’lonlari';

  @override
  String get communityBanned2Title => 'O‘quv kurslari reklamasi';

  @override
  String get communityBanned2Body =>
      'Til kurslari, o‘quv markazlari va boshqalar';

  @override
  String get communityBanned3Title => 'Loyihaga aloqasi yo‘q savollar';

  @override
  String get communityBanned3Body =>
      'Umumiy savollar uchun boshqa guruhlardan foydalaning';

  @override
  String get communityBanned4Title => 'Spam va takroriy xabarlar';

  @override
  String get communityBanned4Body => 'Bir xil xabarlarni qayta-qayta yozish';

  @override
  String get communityBanned5Title => 'Mavzudan tashqari munozaralar';

  @override
  String get communityBanned5Body => 'Loyihaga aloqasi bo‘lmagan suhbatlar';

  @override
  String get communityPenaltyTitle => 'Ogohlantirish';

  @override
  String get communityPenaltyText =>
      'Qoidalarga zid xabarlar o‘chiriladi. Agar o‘chirilgan xabar qayta yozilsa, foydalanuvchi guruhda yozish huquqidan cheklanadi (restrict).';

  @override
  String get communityCta =>
      'Qoidalarga rioya qilgan holda guruhga qo‘shilishingizni so‘rab qolamiz!';

  @override
  String get donationTransfer => 'Pul o‘tkazish';

  @override
  String get donationBank => 'Bank';

  @override
  String get donationCopyAccount => 'Hisob raqamni nusxalash';

  @override
  String get donationCopyName => 'Ismni nusxalash';

  @override
  String get donationOpenApp => 'Bank ilovasida o‘tkazish';

  @override
  String get donationOpenAppHint => 'Hisob raqam nusxalanadi — ilovada joylang';

  @override
  String get donationPasteHint => 'Hisob raqam nusxalandi — ilovada joylang';

  @override
  String get donationShare => 'Rekvizitlarni ulashish';

  @override
  String get donationAsk => 'Savol va takliflar uchun — guruhimiz';

  @override
  String get communityCopyLink => 'Havolani nusxalash';

  @override
  String get communityLinkCopied => 'Havola nusxalandi';

  @override
  String get communityShare => 'Ulashish';

  @override
  String get communityMore => 'Guruhda yana';

  @override
  String get communityTemplateHint =>
      'Shablon nusxalanadi. Guruhda joylab, bo‘sh joylarni to‘ldiring.';

  @override
  String get communityTemplateGo => 'Nusxalash va guruhni ochish';

  @override
  String get communityTemplateCopied => 'Shablon nusxalandi — guruhda joylang';

  @override
  String get communityTemplatePlace =>
      '📍 Yangi joy\nNomi: \nTuri: masjid / oshxona / do‘kon\nManzil: \nXaritadagi havola: \nQo‘shimcha: ';

  @override
  String communityTemplateBug(String phone, String version) {
    return '🐛 Xato\nQaysi bo‘limda: \nNima bo‘ldi: \nNima bo‘lishi kerak edi: \n\nTelefon: $phone\nIlova: $version';
  }

  @override
  String get barcodeTitle => 'Tarkib tekshirish';

  @override
  String get barcodeHint => 'Shtrix kodni ramkaga to‘g‘rilang';

  @override
  String get barcodeChecking => 'Tekshirilmoqda…';

  @override
  String get barcodeTypeCode => 'Kodni kiritish';

  @override
  String get barcodeTorch => 'Chiroq';

  @override
  String get barcodeSwitchCamera => 'Kamerani almashtirish';

  @override
  String get barcodeBackToCamera => 'Skanerlash';

  @override
  String get barcodeCameraOffTitle => 'Kameraga ruxsat berilmagan';

  @override
  String get barcodeCameraOffBody =>
      'Skanerlash uchun kameraga ruxsat bering yoki kodni qo‘lda kiriting.';

  @override
  String get barcodeOpenSettings => 'Sozlamalarni ochish';

  @override
  String get barcodeCameraError => 'Kameraga ulanib bo‘lmadi.';

  @override
  String get barcodeRetry => 'Qayta urinish';

  @override
  String get barcodeVerdictJoiz => 'Joiz';

  @override
  String get barcodeVerdictShubhali => 'Shubhali';

  @override
  String get barcodeVerdictNojoiz => 'Joiz emas';

  @override
  String get barcodeVerdictJoizDesc =>
      'Tarkibida ta’qiqlangan ingredientlar topilmadi';

  @override
  String get barcodeVerdictShubhaliDesc =>
      'Ta’qiqlangan moddalar yo‘q, lekin bir zavodda ishlab chiqarilgan yoki ayrim ingredientlar o‘zagi HAYVONlardan olingan bo‘lishi mumkin.';

  @override
  String get barcodeVerdictNojoizDesc =>
      'Tarkibida ta’qiqlangan ingredientlar aniqlandi';

  @override
  String get barcodePork => 'Cho‘chqa';

  @override
  String get barcodeAlcohol => 'Alkogol';

  @override
  String get barcodeMeat => 'Boshqa go‘sht';

  @override
  String get barcodeSeafood => 'Dengiz mahsulotlari';

  @override
  String get barcodeAbsent => 'yo‘q';

  @override
  String get barcodePresent => 'bor';

  @override
  String get barcodeAmbiguous =>
      'Tarkibida 트랜스지방, 쇼트닝, 향료 yoki 글리세린 bor — o‘simlik yoki HAYVON YOG‘idan olinishi mumkin.';

  @override
  String get barcodeFactoryWarn =>
      'Mahsulot ta’qiqlangan ingredientlar tayyorlanadigan zavod/uskunalarda ishlab chiqarilgan.';

  @override
  String get barcodeFactoryOk =>
      'Mahsulot ishlab chiqarilgan zavod/uskunalarda ta’qiqlangan mahsulotlar ishlatilmaydi.';

  @override
  String get barcodeIngredients => 'Tarkibi';

  @override
  String get barcodeDoubtfulLink => 'Shubhali mahsulotni yesa bo‘ladimi?';

  @override
  String get barcodeFoundIn => 'Topildi:';

  @override
  String get barcodeGeneralDb => 'Umumiy ma’lumotlar bazasi';

  @override
  String get barcodeStoreUnknown => 'Do‘kon belgilanmagan';

  @override
  String get barcodeAlsoAt => 'Boshqa do‘konlarda ham bor:';

  @override
  String get barcodeCopyCode => 'Kodni nusxalash';

  @override
  String get barcodeCopied => 'Nusxalandi';

  @override
  String get barcodeScanNext => 'Keyingisini skanerlash';

  @override
  String get barcodeNotFound => 'Mahsulot topilmadi';

  @override
  String get barcodeNotFoundDesc =>
      'Ushbu mahsulot hozircha bazada yo‘q. Tez orada qo‘shilishi mumkin.';

  @override
  String get barcodeOfflineTitle => 'Internet yo‘q';

  @override
  String get barcodeOfflineBody =>
      'Mahsulotni tekshirish uchun internet kerak. Ulanishni tekshirib, qayta urinib ko‘ring.';

  @override
  String get barcodeSaved => 'Avval saqlangan natija · internet yo‘q';

  @override
  String get barcodeRecent => 'So‘nggi tekshiruvlar';

  @override
  String get barcodeClear => 'Tozalash';

  @override
  String get barcodeTypeTitle => 'Shtrix-kodni kiriting';

  @override
  String get barcodeTypeHint =>
      'Shtrixlar ostidagi raqamlar: 8 tadan 14 tagacha.';

  @override
  String get barcodeSearch => 'Qidirish';

  @override
  String get barcodeErrEmpty => 'Shtrix-kod kiriting.';

  @override
  String get barcodeErrNonDigit => 'Faqat raqamlar kiriting.';

  @override
  String get barcodeErrLength =>
      'Shtrix-kod 8 dan 14 tagacha raqamdan iborat bo‘lishi kerak.';

  @override
  String get barcodeErrChecksum =>
      'Shtrix-kod noto‘g‘ri. Raqamlarni tekshiring.';

  @override
  String get barcodeStores => 'Do‘konlar';

  @override
  String barcodeProducts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta mahsulot',
    );
    return '$_temp0';
  }

  @override
  String get barcodeSoon => 'Yaqinda';

  @override
  String get barcodeStoresError => 'Do‘konlar yuklanmadi';

  @override
  String get barcodeAll => 'Hammasi';

  @override
  String get barcodeStoreEmpty => 'Mahsulot topilmadi';

  @override
  String get barcodeStoreEmptyDesc => 'Boshqa turkum yoki hukmni tanlang.';

  @override
  String get barcodeProductsError => 'Mahsulotlar yuklanmadi';

  @override
  String get barcodeCheckConnection =>
      'Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get barcodeContribTitle => 'Halol baza yig‘ishga sherik bo‘ling';

  @override
  String get barcodeContribBody =>
      'Mahsulotlar tarkibini o‘qiy oladiganlar uchun: GS25, CU, 7-Eleven, Emart24, No Brand va Daiso do‘konlaridagi halol mahsulotlar bazasini birgalikda yig‘amiz. Har bir yozuv minglab yurtdoshlarimizga yetib boradi — ortingizdan sadaqa-i joriyangizni qoldiring.';

  @override
  String get barcodeContribCta => 'Adminga yozish';

  @override
  String get barcodeDisclaimer =>
      'Bu ma’lumotlar faqat mahsulot tarkibi asosida taqdim etilgan bo‘lib, *xatoliklar bo‘lishi mumkin*. Biz rasmiy diniy hukm (fatvo) bermaymiz. Xatolik topsangiz, Telegram guruhimizga xabar bering.';

  @override
  String get barcodeCatDrinks => 'Ichimliklar';

  @override
  String get barcodeCatSnacks => 'Yengil ovqatlar';

  @override
  String get barcodeCatSweets => 'Shirinliklar';

  @override
  String get barcodeCatIceCream => 'Muzqaymoq';

  @override
  String get barcodeCatBaked => 'Non mahsulotlari';

  @override
  String get barcodeCatNoodles => 'Lag‘mon/Ramen';

  @override
  String get barcodeCatLunchbox => 'Pechenya/Pishiriqlar';

  @override
  String get barcodeCatDairy => 'Sut mahsulotlari';

  @override
  String get barcodeCatCanned => 'Konserva';

  @override
  String get barcodeCatFrozen => 'Muzlatilgan';

  @override
  String get barcodeCatSauces => 'Ziravor/Souslar';

  @override
  String get barcodeCatFruits => 'Meva/Sabzavot';

  @override
  String get barcodeCatDried => 'Quritilgan';

  @override
  String get qnaLabel => 'Savol-javob markazi';

  @override
  String get qnaVerseRef => 'Nahl surasi, 43-oyat';

  @override
  String get qnaSource =>
      'Shayx Muhammad Sodiq Muhammad Yusuf va boshqa ustozlarning javoblari';

  @override
  String get qnaCount => '100 000+ savol';

  @override
  String get qnaAi => 'Sun’iy intellekt qidiruvi';

  @override
  String get qnaSearchHint => 'Savolingizni o‘z so‘zlaringiz bilan yozing…';

  @override
  String get qnaUzbekNote => 'Savollar va javoblar o‘zbek tilida.';

  @override
  String get qnaDaily => 'Kunlik tanlov';

  @override
  String get qnaDailySub => 'Har kuni yangi savollar';

  @override
  String get qnaNewSet => 'Yangi savollar';

  @override
  String get qnaLoadError => 'Savollar yuklanmadi';

  @override
  String get qnaCheckConnection =>
      'Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get qnaRetry => 'Qayta urinish';

  @override
  String get qnaSaved => 'Saqlangan javoblar';

  @override
  String get qnaSavedEmpty => 'Hali hech narsa saqlanmagan';

  @override
  String get qnaSavedHint =>
      'Javobni belgi tugmasi bilan saqlang — internet bo‘lmasa ham o‘qiysiz.';

  @override
  String get qnaSave => 'Saqlash';

  @override
  String get qnaUnsave => 'Saqlanganlardan olib tashlash';

  @override
  String get qnaSavedNote => 'Saqlandi';

  @override
  String get qnaRemovedNote => 'Saqlanganlardan olib tashlandi';

  @override
  String get qnaShare => 'Ulashish';

  @override
  String get qnaTextSize => 'Matn o‘lchami';

  @override
  String get qnaQuestion => 'Savol';

  @override
  String get qnaAnswer => 'Javob';

  @override
  String get qnaOpenSource => 'Manbaga o‘tish';

  @override
  String get qnaCopy => 'Nusxalash';

  @override
  String get qnaCopied => 'Savol va javob nusxalandi';

  @override
  String get qnaRelated => 'O‘xshash savollar';

  @override
  String get qnaAnswerError => 'Javob yuklanmadi';

  @override
  String get qnaOther => 'Boshqa';

  @override
  String get qnaSearchTitle => 'Savol qidirish';

  @override
  String get qnaSearchButton => 'Qidirish';

  @override
  String get qnaMinLetters => 'Kamida 3 ta harf yozing';

  @override
  String get qnaHowTitle => 'Qanday ishlaydi?';

  @override
  String get qnaHowBody =>
      'Sun’iy intellekt o‘zbek til modeli savolingizning ma’nosini tushunib, minglab savol-javoblar ichidan eng o‘xshashlarini topadi. So‘zma-so‘z mos kelishi shart emas: savolingizni to‘liq va grammatik to‘g‘ri yozsangiz, javob aniqroq bo‘ladi. Lotin yoki kirill yozuvida yozishingiz mumkin.';

  @override
  String get qnaRecent => 'So‘nggi qidiruvlar';

  @override
  String get qnaClear => 'Tozalash';

  @override
  String get qnaRemove => 'O‘chirish';

  @override
  String get qnaExamples => 'Masalan';

  @override
  String qnaResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta natija',
    );
    return '$_temp0';
  }

  @override
  String get qnaNoResults => 'Hech narsa topilmadi';

  @override
  String get qnaNoResultsHint =>
      'Savolni boshqacharoq, to‘liqroq yozib ko‘ring.';

  @override
  String get qnaOfflineTitle => 'Internet yo‘q';

  @override
  String get qnaOfflineBody =>
      'Qidiruv uchun internet kerak. Saqlangan javoblar internetsiz ham ochiladi.';

  @override
  String get bizTitle => 'Biznes katalogi';

  @override
  String get bizTagline => 'Koreyadagi o‘zbek bizneslari — bir joyda';

  @override
  String get bizSearchTitle => 'Qidiruv';

  @override
  String get bizSearchHint => 'Biznes yoki xizmatni qidiring';

  @override
  String bizCountAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta biznes',
    );
    return '$_temp0';
  }

  @override
  String bizCountFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta topildi',
    );
    return '$_temp0';
  }

  @override
  String get bizTileEmpty => 'Hozircha bo‘sh';

  @override
  String get bizDirectoryEmpty => 'Katalog hozircha bo‘sh';

  @override
  String get bizDirectoryEmptyBody =>
      'Bu yerda Koreyadagi o‘zbek bizneslari to‘planadi.';

  @override
  String get bizSaved => 'Saqlanganlar';

  @override
  String get bizCategories => 'Yo‘nalishlar';

  @override
  String get bizOrderNote => 'Mijozlar eng ko‘p yoqtirgan bizneslar yuqorida';

  @override
  String get bizCategoryEmpty => 'Bu yo‘nalishda hali biznes yo‘q';

  @override
  String get bizCategoryEmptyBody =>
      'Yangi bizneslar qo‘shilgach shu yerda ko‘rinadi. Boshqa yo‘nalishlarga ham qarab ko‘ring.';

  @override
  String get bizSeeAll => 'Barchasi';

  @override
  String get bizNothingFound => 'Hech narsa topilmadi';

  @override
  String bizNothingFoundBody(String query) {
    return '“$query” bo‘yicha biznes topilmadi. Boshqacha yozib ko‘ring yoki yo‘nalishlardan qidiring.';
  }

  @override
  String get bizLoadError => 'Yuklab bo‘lmadi';

  @override
  String get bizCheckConnection =>
      'Internet aloqasini tekshirib, qayta urinib ko‘ring.';

  @override
  String get bizRetry => 'Qayta urinish';

  @override
  String get bizUzbekNote => 'Bizneslar haqidagi ma’lumotlar o‘zbek tilida.';

  @override
  String get bizSave => 'Saqlash';

  @override
  String get bizUnsave => 'Saqlanganlardan olib tashlash';

  @override
  String get bizSavedNote =>
      'Saqlandi — aloqa ma’lumotlari internetsiz ham ochiladi';

  @override
  String get bizRemovedNote => 'Saqlanganlardan olib tashlandi';

  @override
  String get bizShare => 'Ulashish';

  @override
  String get bizShareFooter => 'Muslim Vegukin biznes katalogidan';

  @override
  String bizViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marta ko‘rilgan',
    );
    return '$_temp0';
  }

  @override
  String bizLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kishiga yoqdi',
    );
    return '$_temp0';
  }

  @override
  String get bizLoadFailed => 'Ma’lumotni yuklab bo‘lmadi.';

  @override
  String get bizLinks => 'Boshqa havolalar';

  @override
  String get bizAbout => 'Biznes haqida';

  @override
  String get bizNoInfo => 'Bu biznes hali to‘liq ma’lumot kiritmagan.';

  @override
  String get bizNoContact => 'Aloqa ma’lumotlari ko‘rsatilmagan.';

  @override
  String get bizNoContactAsk => 'Admin orqali so‘rash';

  @override
  String get bizReport => 'Ma’lumot noto‘g‘rimi? Adminga xabar bering';

  @override
  String get bizCopyAddress => 'Nusxalash';

  @override
  String get bizAddressCopied => 'Manzil nusxalandi';

  @override
  String get bizPhoneCopied => 'Raqam nusxalandi';

  @override
  String get bizActCall => 'Qo‘ng‘iroq qilish';

  @override
  String get bizActTelegram => 'Telegramda yozish';

  @override
  String get bizActChannel => 'Telegramda ochish';

  @override
  String get bizActKakao => 'KakaoTalkda yozish';

  @override
  String get bizActWebsite => 'Saytni ochish';

  @override
  String get bizActInstagram => 'Instagramda ko‘rish';

  @override
  String get bizActTiktok => 'TikTokda ko‘rish';

  @override
  String get bizActYoutube => 'YouTube’da ko‘rish';

  @override
  String get bizActFacebook => 'Facebookda ochish';

  @override
  String get bizActPlay => 'Google Play’da ochish';

  @override
  String get bizActAppStore => 'App Store’da ochish';

  @override
  String get bizActOpen => 'Ochish';

  @override
  String get bizChannelPhone => 'Telefon';

  @override
  String get bizChannelGroup => 'Telegram kanal / guruh';

  @override
  String get bizChannelWebsite => 'Veb-sayt';

  @override
  String get bizPrivateGroup => 'Yopiq guruh';

  @override
  String get bizMapNaver => 'Naver xarita';

  @override
  String get bizMapKakao => 'Kakao xarita';

  @override
  String get bizMapGoogle => 'Google xarita';

  @override
  String get bizOwnerTitle => 'Biznes egasimisiz?';

  @override
  String get bizOwnerBody =>
      'Biznesingizni katalogga qo‘shing — mijozlar sizni shu yerdan topadi.';

  @override
  String get bizOwnerBodyEmpty => 'Bu yo‘nalishga birinchi bo‘lib qo‘shiling.';

  @override
  String get bizOwnerEyebrow => 'Biznes egalari uchun';

  @override
  String get bizOwnerSheetTitle => 'Katalogga qo‘shilish';

  @override
  String get bizStep1Title => 'Ariza yuborish';

  @override
  String get bizStep1Body =>
      'Biznes logosi, nomi, yo‘nalishi va aloqa ma’lumotlarini kiriting.';

  @override
  String get bizStep2Title => 'To‘lov';

  @override
  String bizStep2Body(String amount) {
    return 'Bir martalik to‘lov — $amount. Adminga to‘lov skrinshotini yuborasiz.';
  }

  @override
  String get bizStep3Title => 'Katalogda';

  @override
  String get bizStep3Body =>
      'To‘lov tasdiqlangach biznesingiz katalogda ko‘rina boshlaydi.';

  @override
  String get bizOwnerFine =>
      'Katalogda ko‘rinish tartibi biznesga bosilgan klass soniga qarab belgilanadi: eng ko‘p yoqtirilgan biznes yuqorida turadi.';

  @override
  String get bizOwnerHow =>
      'Ariza Telegram orqali yuboriladi: adminga yozing, u biznesingizni qo‘shishda yordam beradi.';

  @override
  String get bizOwnerContact => 'Admin bilan bog‘lanish';

  @override
  String bizCurrency(String amount) {
    return '$amount won';
  }

  @override
  String get accountTitle => 'Akkaunt';

  @override
  String get signInTitle => 'Akkauntingizga kiring';

  @override
  String get signInWhy =>
      'Joylarni kuzatish va bildirishnomalar kirmasdan ham ishlaydi. Izoh yozish, ma’lumotni tuzatish va e’lon berish uchun kiring — boshqalar kim yozganini bilsin.';

  @override
  String get signInTelegramNote =>
      'Bu bo‘lim Telegram orqali ishlaydi. Muslim Vegukin botidagi akkauntingiz bilan kiring — botda joylagan e’lonlaringiz shu yerda ham ko‘rinadi.';

  @override
  String get signInTelegram => 'Telegram orqali kirish';

  @override
  String get signInWhatsApp => 'WhatsApp orqali kirish';

  @override
  String get signInGoogle => 'Google orqali kirish';

  @override
  String signInWaitingTitle(String app) {
    return '${app}da «Ha, kirish»ni bosing';
  }

  @override
  String get signInWaitingBody =>
      'Shu yerda kutib turamiz. Tasdiqlagach, ilovaga qayting.';

  @override
  String signInOpenAgain(String app) {
    return '${app}ni qayta ochish';
  }

  @override
  String get signInCancel => 'Bekor qilish';

  @override
  String get signInExpired =>
      'Vaqt tugadi yoki bekor qilindi. Qaytadan urinib ko‘ring.';

  @override
  String get signInFailed =>
      'Bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get signInDone => 'Kirdingiz';

  @override
  String signedInWith(String provider) {
    return '$provider orqali kirilgan';
  }

  @override
  String get signOut => 'Chiqish';

  @override
  String get accountDelete => 'Akkauntni o‘chirish';

  @override
  String get accountDeleteTitle => 'Akkaunt o‘chirilsinmi?';

  @override
  String get accountDeleteBody =>
      'Kuzatuvlaringiz, hududlaringiz va izohlaringiz butunlay o‘chiriladi. Buni qaytarib bo‘lmaydi.';

  @override
  String get accountDeleteTelegram => 'Telegram botda qilinganlari ham.';

  @override
  String get accountDeleteConfirm => 'O‘chirish';

  @override
  String get accountDeleted => 'Akkaunt o‘chirildi';

  @override
  String get accountPushOn => 'Bildirishnomalar shu telefonga keladi';

  @override
  String get accountPushOff =>
      'Xabarlar baribir «Kelgan xabarlar»ga tushadi, lekin telefon ularni ko‘rsatmaydi.';

  @override
  String get pushOpen => 'Ochish';

  @override
  String get inboxTitle => 'Kelgan xabarlar';

  @override
  String inboxUnread(int count) {
    return '$count ta yangi';
  }

  @override
  String get inboxEmptyTitle => 'Hozircha xabar yo‘q';

  @override
  String get inboxEmptyBody =>
      'Sizga yuborilgan bildirishnomalar shu yerda saqlanadi — o‘tkazib yuborganlaringiz ham.';

  @override
  String get inboxFailed => 'Yuklab bo‘lmadi. Internetni tekshiring.';

  @override
  String get inboxEarlier => 'Avvalgilarini ko‘rsatish';

  @override
  String get inboxPushOff =>
      'Bu telefonda bildirishnomalar o‘chiq. Yangi xabarlar baribir shu yerda chiqadi.';

  @override
  String get inboxMessage => 'Xabar';

  @override
  String inboxOpenSection(String section) {
    return '«$section» bo‘limini ochish';
  }

  @override
  String inboxPhoto(int index, int total) {
    return '$total ta rasmdan $index-si';
  }

  @override
  String get hkLede =>
      'Ofisingizdagi bo‘sh kunlarni ko‘ring. Hammasi band bo‘lsa, kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.';

  @override
  String get hkSearchHint => 'Ofis nomini izlang';

  @override
  String get hkMyWatches => 'Kuzatuvlarim';

  @override
  String hkActiveWatches(int count) {
    return '$count ta faol kuzatuv';
  }

  @override
  String get hkLastViewed => 'Oxirgi ko‘rilgan';

  @override
  String get hkStep1 => 'Ofisingizni toping';

  @override
  String get hkStep2 => 'Bo‘sh kunlarni ko‘ring';

  @override
  String get hkStep3 => 'HiKorea\'da bron qiling';

  @override
  String get hkAddressCardTitle => 'Ofisingizni bilmaysizmi?';

  @override
  String get hkAddressCardBody => 'Uy manzilingiz bo‘yicha topib beramiz';

  @override
  String get hkOffices => 'Immigratsiya ofislari';

  @override
  String hkCounters(int count) {
    return '$count ta bo‘lim';
  }

  @override
  String get hkNoMatch =>
      'Bunday ofis topilmadi. Boshqa so‘z bilan izlang yoki manzil bo‘yicha toping.';

  @override
  String get hkLoadFailed => 'Yuklab bo‘lmadi. Internetni tekshiring.';

  @override
  String get hkAddressTitle => 'Manzil bo‘yicha topish';

  @override
  String get hkAddressLede =>
      'Har bir ofis o‘z tumanlariga xizmat qiladi. Viloyatingizni tanlang va uy manzilingizni koreyscha yozing.';

  @override
  String get hkProvince => '1. Viloyat';

  @override
  String get hkAddress => '2. Uy manzili (koreyscha)';

  @override
  String get hkAddressHint =>
      'Manzilda shahar yoki tuman nomi bo‘lsin (-시, -구, -군), masalan 안산시 단원구.';

  @override
  String get hkFindOffice => 'Ofisni topish';

  @override
  String get hkNeedProvince => 'Avval viloyatni tanlang';

  @override
  String get hkNeedAddress => 'Manzilni yozing';

  @override
  String get hkYourOffice => 'Sizning ofisingiz:';

  @override
  String get hkPickOne => 'Mosini tanlang:';

  @override
  String get hkAddressNoMatch =>
      'Bu manzil uchun ofis topilmadi. Manzilni to‘liq yozing.';

  @override
  String get hkCountersTitle => 'Qaysi bo‘lim kerak?';

  @override
  String get hkCountersLede =>
      'Bo‘limlar bir xil ishni bajaradi, lekin joyi, qavati yoki qabul vaqti farq qilishi mumkin. Tanlashdan oldin tavsifini o‘qing.';

  @override
  String get hkFromAfternoon => 'Qabul 09:36 dan';

  @override
  String get hkMore => 'Batafsil';

  @override
  String hkCounterN(int n) {
    return '$n-bo‘lim';
  }

  @override
  String get hkCalendarHint =>
      'Kunni bosing — joylarni HiKorea\'dan hozir tekshiramiz.';

  @override
  String get hkCheckedNow => 'Hozirgina tekshirildi';

  @override
  String hkCheckedMinutes(int n) {
    return '$n daqiqa oldin tekshirildi';
  }

  @override
  String hkCheckedHours(int n) {
    return '$n soat oldin tekshirildi';
  }

  @override
  String hkCheckedDays(int n) {
    return '$n kun oldin tekshirildi';
  }

  @override
  String get hkEarliest => 'Eng yaqin bo‘sh kun';

  @override
  String get hkAllFull => 'Hozir hamma kunlar band';

  @override
  String get hkAllFullBody =>
      'Kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.';

  @override
  String get hkLegendOpen => 'Bo‘sh';

  @override
  String get hkLegendSome => 'Bandlik bor';

  @override
  String get hkLegendFull => 'To‘la band';

  @override
  String get hkLegendClosed => 'Yopiq';

  @override
  String get hkNoDates =>
      'Hozir hech qanday kun ko‘rinmayapti. Kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.';

  @override
  String get hkNotifyMe => 'Joy ochilganda xabar berish';

  @override
  String get hkChecking => 'HiKorea tekshirilmoqda…';

  @override
  String get hkDayClosed => 'Bu kuni ofis ishlamaydi';

  @override
  String get hkFullyBooked => 'To‘la band';

  @override
  String get hkLastOne => 'Faqat 1 ta joy qoldi';

  @override
  String hkSlotsFree(int n) {
    return '$n ta bo‘sh joy';
  }

  @override
  String get hkBookCue => 'Bron qilish HiKorea saytida bo‘ladi.';

  @override
  String get hkFullCue =>
      'Bo‘sh joy yo‘q. Kuzatuv o‘rnatsangiz, joy ochilishi bilan xabar beramiz.';

  @override
  String hkBookedOf(int taken, int capacity) {
    return '$capacity tadan $taken tasi band';
  }

  @override
  String get hkMorning => 'Ertalab';

  @override
  String get hkAfternoon => 'Tushdan keyin';

  @override
  String hkLeft(int n) {
    return '$n ta qoldi';
  }

  @override
  String get hkSlotFull => 'Band';

  @override
  String get hkBook => 'HiKorea\'da bron qilish';

  @override
  String get hkFetchFailed =>
      'HiKorea\'ga ulanib bo‘lmadi. Birozdan so‘ng qayta urinib ko‘ring.';

  @override
  String get hkSessionExpired =>
      'HiKorea bilan aloqamiz yangilanmoqda. Birozdan so‘ng urinib ko‘ring.';

  @override
  String get hkWatchTitle => 'Qaysi kunlarni kuzataylik?';

  @override
  String get hkWatchLede =>
      'Shu kunlarda joy ochilishi bilan bildirishnoma yuboramiz.';

  @override
  String hkNextDays(int n) {
    return 'Keyingi $n kun';
  }

  @override
  String get hkPickDates => 'Aniq sanalarni tanlash';

  @override
  String hkDays(int n) {
    return '$n kun';
  }

  @override
  String get hkStartWatching => 'Kuzatishni boshlash';

  @override
  String get hkTooLong => 'Ko‘pi bilan 90 kun kuzatish mumkin';

  @override
  String get hkDuplicate => 'Bu kunlar allaqachon kuzatilmoqda';

  @override
  String get hkMaxReached =>
      'Ko‘pi bilan 10 ta kuzatuv. Avval bittasini to‘xtating.';

  @override
  String get hkCreateFailed =>
      'Kuzatuvni o‘rnatib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get hkDoneTitle => 'Kuzatuv o‘rnatildi';

  @override
  String get hkDoneBody =>
      'Har 5 daqiqada tekshiramiz. Joy ochilishi bilan bildirishnoma keladi.';

  @override
  String get hkPushOff =>
      'Bu telefonda bildirishnomalar o‘chiq — xabarlar faqat «Kelgan xabarlar»da ko‘rinadi.';

  @override
  String get hkSendTest => 'Sinov bildirishnomasi';

  @override
  String get hkTestSent => 'Yuborildi';

  @override
  String get hkTestFailed =>
      'Yuborib bo‘lmadi. Bildirishnomalar yoqilganini tekshiring.';

  @override
  String get hkSeeWatches => 'Kuzatuvlarimni ko‘rish';

  @override
  String get hkWatchesEmpty => 'Hali kuzatuv yo‘q';

  @override
  String get hkWatchesEmptyBody =>
      'Ofisni tanlang, kalendarini ko‘ring va kuzatuv o‘rnating.';

  @override
  String get hkStatusActive => 'Faol';

  @override
  String get hkStatusExpired => 'Muddati tugagan';

  @override
  String get hkStatusCancelled => 'To‘xtatilgan';

  @override
  String get hkStatusUndeliverable => 'Yetkazib bo‘lmadi';

  @override
  String get hkStop => 'To‘xtatish';

  @override
  String get hkStopTitle => 'Kuzatuv to‘xtatilsinmi?';

  @override
  String get hkStopped => 'Kuzatuv to‘xtatildi';

  @override
  String get hkStopFailed => 'To‘xtatib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get hkCalendar => 'Kalendar';

  @override
  String get hkPastWatches => 'Tugaganlar';

  @override
  String get hkPickOffice => 'Ofisni tanlash';

  @override
  String get hkStep1Body => 'Nomi yoki uy manzilingiz bo‘yicha';

  @override
  String get hkStep2Body =>
      'Har bir bo‘limning keyingi 3 oyi, har 5 daqiqada yangilanadi';

  @override
  String get hkStep3Body =>
      'Hammasi band bo‘lsa — kuzatuv o‘rnating, joy ochilganda xabar beramiz';

  @override
  String get hkHowTitle => 'Qanday ishlaydi';

  @override
  String get hkStartTitle => 'Sizning ofisingiz qaysi?';

  @override
  String get hkStartBody =>
      'Bu yashash joyingizga bog‘liq: har bir ofis o‘z tumanlariga xizmat qiladi.';

  @override
  String get hkStartOr => 'yoki quyidagi ro‘yxatdan tanlang';

  @override
  String get hkYourWatches => 'Kuzatuvlaringiz';

  @override
  String hkSeeAll(int count) {
    return 'Hammasi ($count)';
  }

  @override
  String hkWatchFree(int n) {
    return 'Sanalaringizda $n ta bo‘sh kun bor';
  }

  @override
  String get hkWatchFull => 'Hammasi band — kuzatyapmiz';

  @override
  String hkEarliestShort(String day) {
    return 'Eng yaqin bo‘sh kun: $day';
  }

  @override
  String get hkAllFullShort => 'Hozir hamma kunlar band';

  @override
  String get hkOfficeMain => 'Immigratsiya ofisi';

  @override
  String get hkOfficeBranch => 'Filial';

  @override
  String hkOfficeBranchOf(String office) {
    return '$office filiali';
  }

  @override
  String get hkAllOffices => 'Barcha ofislar';

  @override
  String hkFreeDays(int n, String date) {
    return '${date}gacha $n ta bo‘sh kun';
  }

  @override
  String hkBookedUntil(String date) {
    return '${date}gacha band. Kuzatuv o‘rnating — joy ochilishi bilan xabar beramiz.';
  }

  @override
  String get hkHowBooking =>
      'Bron qilish HiKorea saytida, o‘z HiKorea akkauntingiz bilan bo‘ladi. Bu yerda bo‘sh kunlarni ko‘rasiz.';

  @override
  String get hkLegendLater => 'Hali ochilmagan';

  @override
  String get hkWatchShort => 'Kuzatish';

  @override
  String get hkStale =>
      'Bu bo‘limni oxirgi paytda tekshira olmadik — kunlar eskirgan bo‘lishi mumkin.';

  @override
  String get accountGuest => 'Mehmon';

  @override
  String get accountGuestBody =>
      'Kirsangiz, izohlaringizda ismingiz ko‘rinadi, kuzatuvlaringiz esa yangi telefonga ham o‘tadi.';

  @override
  String get accountSignIn => 'Kirish';

  @override
  String get accountNoPhoto => 'WhatsApp profil rasmini ilovalarga bermaydi.';

  @override
  String get accountNotifications => 'Bildirishnomalar';

  @override
  String get accountPushOffTitle => 'Bildirishnomalar o‘chiq';

  @override
  String get accountTurnOn => 'Yoqish';

  @override
  String get accountWhatComes =>
      'HiKorea\'da joy ochilishi, kuzatayotgan joy va hududlaringiz yangiliklari, e’lonlar.';

  @override
  String get accountTelegramToo =>
      'Ular Telegram\'dagi Muslim Vegukin botidan ham keladi.';

  @override
  String get accountTestPush => 'Sinov bildirishnomasi';

  @override
  String get accountTestSent => 'Yuborildi — telefoningizda ko‘ring';

  @override
  String get accountTestFailed =>
      'Yuborib bo‘lmadi. Birozdan so‘ng qayta urinib ko‘ring.';

  @override
  String get accountActivity => 'Faoliyatingiz';

  @override
  String get accountInboxNone => 'Hozircha xabar yo‘q';

  @override
  String accountInboxAll(int count) {
    return '$count ta xabar';
  }

  @override
  String get accountApp => 'Ilova';

  @override
  String get accountLanguage => 'Til';

  @override
  String get accountDarkMode => 'Tungi rejim';

  @override
  String get accountManage => 'Akkauntni boshqarish';

  @override
  String accountActive(int count) {
    return '$count ta faol';
  }

  @override
  String get hkDormantTitle =>
      'HiKorea bu bo‘limda hech qanday kun ko‘rsatmayapti';

  @override
  String hkDormantBody(String date) {
    return '${date}dan beri HiKorea bu yerda hech qanday kun ko‘rsatmayapti — na bo‘sh, na band. HiKorea bo‘limni yangisiga almashtirganda shunday bo‘ladi. Ofisning boshqa bo‘limlarini ko‘ring yoki HiKorea saytida tekshiring.';
  }

  @override
  String get hkDormantBodyNoDate =>
      'HiKorea bu yerda hech qanday kun ko‘rsatmayapti — na bo‘sh, na band. HiKorea bo‘limni yangisiga almashtirganda shunday bo‘ladi. Ofisning boshqa bo‘limlarini ko‘ring yoki HiKorea saytida tekshiring.';

  @override
  String get hkOtherCounters => 'Ofisning boshqa bo‘limlari';

  @override
  String get hkCheckOnHikorea => 'HiKorea\'da tekshirish';

  @override
  String get hkNoDaysShort => 'HiKorea\'da kun ko‘rinmayapti';

  @override
  String get hkLeafLegend => 'Sana — eng yaqin bo‘sh kun';

  @override
  String get hkLeafFull => 'Band';

  @override
  String get hkWatchingHere => 'Shu yerda kuzatuvingiz bor';

  @override
  String get plNearest => 'Eng yaqin';

  @override
  String plMetres(String n) {
    return '$n m';
  }

  @override
  String plKm(String n) {
    return '$n km';
  }

  @override
  String get plNoReviews => 'Hali izoh yo‘q';

  @override
  String plReviewCount(int count) {
    return '$count ta izoh';
  }

  @override
  String get plAddressNotFound =>
      'Bu manzil topilmadi. Koreys tilida, aniqroq yozib ko‘ring.';

  @override
  String get plNothingFound => 'Hech narsa topilmadi';

  @override
  String get plLoadFailed => 'Joylarni yuklab bo‘lmadi. Internetni tekshiring.';

  @override
  String get plMissingTitle => 'Ro‘yxatda yo‘q joyni bilasizmi?';

  @override
  String get plMissingBody => 'Guruhimizga yozing — qo‘shib qo‘yamiz.';

  @override
  String get plWatchingBadge => 'Kuzatilmoqda';

  @override
  String plPhotoCount(String i, String n) {
    return '$i / $n';
  }

  @override
  String get plWatch => 'Kuzatish';

  @override
  String plWatchers(int count) {
    return '$count kishi kuzatmoqda';
  }

  @override
  String get plWatchOn => 'Yangiliklari shu telefonga keladi';

  @override
  String get plWatchOff => 'Kuzatish to‘xtatildi';

  @override
  String get plWatchNoPush => 'Bildirishnomalar o‘chiq — yangiliklar kelmaydi';

  @override
  String get plWatchPushOn => 'Yoqish';

  @override
  String get plAddress => 'Manzil';

  @override
  String get plNoAddress => 'Manzil ko‘rsatilmagan';

  @override
  String get plPhone => 'Telefon';

  @override
  String get plMenu => 'Menyu';

  @override
  String get plMenuOpen => 'Menyuni ochish';

  @override
  String get plAddressCopied => 'Manzil nusxalandi';

  @override
  String get plCopyAddress => 'Manzilni nusxalash';

  @override
  String get plMapAttribution => '© OpenStreetMap';

  @override
  String get plAbout => 'Muassasa haqida';

  @override
  String get plAboutEmpty =>
      'Ish vaqti va dam olish kunlari hali qo‘shilmagan.';

  @override
  String get plAboutAdd => 'Ma’lumot qo‘shish';

  @override
  String get plSuggestChange => 'O‘zgartirishni taklif qilish';

  @override
  String get plSocial => 'Ijtimoiy tarmoqlarda';

  @override
  String get plSocialEmpty => 'Bu joy ijtimoiy tarmoqlarda bormi?';

  @override
  String get plSocialAdd => 'Qo‘shish';

  @override
  String get plInviteLink => 'Havola';

  @override
  String plPendingField(String what) {
    return '$what: taklifingiz ko‘rib chiqilmoqda';
  }

  @override
  String get plNoteLabel => 'Ma’lumot';

  @override
  String get plReviews => 'Izohlar';

  @override
  String get plReviewsFirst =>
      'Birinchi bo‘lib izoh qoldiring — boshqalarga yordam bo‘ladi.';

  @override
  String get plWriteReview => 'Izoh qoldirish';

  @override
  String get plEditReview => 'Izohingizni o‘zgartirish';

  @override
  String get plYourReview => 'Sizning izohingiz';

  @override
  String plAllReviews(int count) {
    return 'Hammasini ko‘rish ($count)';
  }

  @override
  String get plNoText => 'Faqat baho';

  @override
  String get plCorrections =>
      'Nomi, manzili yoki telefoni noto‘g‘rimi? Guruhimizga yozing.';

  @override
  String get plLoadDetailFailed =>
      'Ma’lumotlarni yuklab bo‘lmadi. Internetni tekshiring.';

  @override
  String get plGone =>
      'Bu joy topilmadi — ro‘yxatdan olib tashlangan bo‘lishi mumkin.';

  @override
  String get plRateQuestion => 'Qanday baholaysiz?';

  @override
  String get plStar1 => 'Juda yomon';

  @override
  String get plStar2 => 'Yomon';

  @override
  String get plStar3 => 'O‘rtacha';

  @override
  String get plStar4 => 'Yaxshi';

  @override
  String get plStar5 => 'A’lo';

  @override
  String get plReviewHintMosque =>
      'Masalan: namoz vaqtlari, kirish eshigidagi parol, qanday borish mumkin.';

  @override
  String get plReviewHintRestaurant =>
      'Masalan: taomlar, narxlar, xizmat, ish vaqti.';

  @override
  String get plReviewHintShop =>
      'Masalan: nimalar sotiladi, narxlar, ish vaqti.';

  @override
  String get plReviewPlaceholder => 'Fikringizni yozing (ixtiyoriy)';

  @override
  String get plReviewPublic =>
      'Izoh hammaga ko‘rinadi, ismingiz esa ko‘rinmaydi.';

  @override
  String get plReviewSend => 'Chop etish';

  @override
  String get plReviewSave => 'Saqlash';

  @override
  String get plReviewPick => 'Avval yulduzchani tanlang';

  @override
  String get plReviewPublished => 'Rahmat! Izohingiz chop etildi.';

  @override
  String get plReviewUpdated => 'Izohingiz yangilandi.';

  @override
  String get plReviewDelete => 'Izohni o‘chirish';

  @override
  String get plReviewDeleteAsk => 'Izohingiz o‘chirilsinmi?';

  @override
  String get plReviewDeleted => 'Izohingiz o‘chirildi.';

  @override
  String get plDelete => 'O‘chirish';

  @override
  String get plCancel => 'Bekor qilish';

  @override
  String get plSend => 'Yuborish';

  @override
  String get plSuggestPick => 'Nimani qo‘shmoqchisiz?';

  @override
  String plSuggestAddLink(String platform) {
    return '$platform havolasini qo‘shish';
  }

  @override
  String plSuggestEditLink(String platform) {
    return '$platform havolasini o‘zgartirish';
  }

  @override
  String get plSuggestAddNote => 'Ma’lumot qo‘shish';

  @override
  String get plSuggestEditNote => 'Ma’lumotni o‘zgartirish';

  @override
  String plSuggestCurrent(String value) {
    return 'Hozirgi: $value';
  }

  @override
  String get plHintTelegram => '@username yoki t.me havolasi';

  @override
  String get plHintTiktok => '@username yoki tiktok.com havolasi';

  @override
  String get plHintInstagram => '@username yoki instagram.com havolasi';

  @override
  String get plHintNote => 'Ish vaqti, dam olish kunlari yoki e’lon.';

  @override
  String get plNotePlaceholder =>
      'Masalan:\nDu–Ju: 11:00 – 22:00\nShanba: yopiq';

  @override
  String get plModeration => 'Admin tekshirgach chop etiladi.';

  @override
  String get plSuggestSent => 'Rahmat! Taklifingiz ko‘rib chiqilmoqda.';

  @override
  String get plAnnounceMosque => 'E’lon yozish';

  @override
  String get plAnnounceOwner => 'E’lon yuborish';

  @override
  String get plAnnounceWhyMosque =>
      'Masalan, hayit namozi vaqti — kuzatayotganlarga yuboriladi.';

  @override
  String get plAnnounceWhyOwner => 'Kuzatayotganlarga yangilik yuboring.';

  @override
  String plAnnouncePending(int count) {
    return '$count ta e’lon tekshiruvda';
  }

  @override
  String get plAnnounceTitle => 'E’lon';

  @override
  String get plAnnouncePlaceholderOwner =>
      'Masalan: 25-dekabr kuni oshxonamiz yopiq bo‘ladi.';

  @override
  String get plAnnouncePlaceholderMosque =>
      'Masalan: Hayit namozi 07:00, 08:00 va 09:00 da o‘qiladi.';

  @override
  String plAnnounceReach(int count) {
    return 'Admin tasdiqlagach, taxminan $count kishiga yuboriladi.';
  }

  @override
  String get plAnnounceSend => 'Tekshiruvga yuborish';

  @override
  String get plAnnounceSent => 'E’lon tekshiruvga yuborildi';

  @override
  String get plTextEmpty => 'Avval matn yozing.';

  @override
  String get plClaimPrompt => 'Bu joy egasimisiz?';

  @override
  String get plClaimWhy => 'Egasi kuzatayotganlarga e’lon yubora oladi.';

  @override
  String get plClaimConfirm =>
      'Ismingiz va aloqa ma’lumotingiz administratorga yuboriladi. U egalikni tekshirish uchun siz bilan bog‘lanadi. Davom etasizmi?';

  @override
  String get plClaimContinue => 'Davom etish';

  @override
  String get plClaimSent =>
      'So‘rov yuborildi. Administrator siz bilan bog‘lanadi.';

  @override
  String get plClaimPending => 'Egalik so‘rovingiz ko‘rib chiqilmoqda.';

  @override
  String get plYouOwn => 'Siz bu joyning egasisiz';

  @override
  String get plErrNetwork =>
      'Internetga ulanib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get plErrGeneric => 'Xatolik yuz berdi. Qayta urinib ko‘ring.';

  @override
  String get plErrSignIn => 'Buning uchun akkauntga kiring.';

  @override
  String get plErrTooManyReviews =>
      'Bugun juda ko‘p izoh qoldirdingiz. Ertaga urinib ko‘ring.';

  @override
  String get plErrTooLong => 'Matn juda uzun.';

  @override
  String get plErrTooShort => 'Juda qisqa.';

  @override
  String get plErrWrongHost =>
      'Bu havola boshqa saytga tegishli. To‘g‘ri havolani kiriting.';

  @override
  String get plErrHandle =>
      'Username noto‘g‘ri. Faqat harflar, raqamlar va pastki chiziq.';

  @override
  String get plErrUrl => 'Bu havolaga o‘xshamaydi.';

  @override
  String get plErrIncomplete => 'Havola to‘liq emas.';

  @override
  String get plErrNotProfile => 'Bu post havolasi. Profil havolasini yuboring.';

  @override
  String get plErrPending =>
      'Bu bo‘yicha taklif allaqachon ko‘rib chiqilmoqda.';

  @override
  String get plErrSame => 'Bu allaqachon saqlangan.';

  @override
  String get plErrRateLimited =>
      'Bugungi takliflar limitiga yetdingiz. Ertaga urinib ko‘ring.';

  @override
  String get plErrGone => 'Bu joy endi mavjud emas.';

  @override
  String get plErrNotOwner =>
      'Bu joy uchun faqat tasdiqlangan egasi e’lon yubora oladi.';

  @override
  String get plErrHasOwner => 'Bu joyning egasi allaqachon tasdiqlangan.';

  @override
  String get plErrTooManyPending =>
      'Tekshiruvni kutayotgan so‘rovlaringiz ko‘p. Avval ular ko‘rib chiqilsin.';

  @override
  String get plPhotoFailed => 'Rasmni yuklab bo‘lmadi';

  @override
  String get plMosque => 'Masjid';

  @override
  String get plRestaurant => 'Oshxona';

  @override
  String get plShop => 'Do‘kon';

  @override
  String get plNearMe => 'O‘z atrofimdan izlash';

  @override
  String get plByAddress => 'Boshqa manzil atrofidan izlash';

  @override
  String get plAddressTip =>
      'Manzilni KOREYS tilida yozing: shahar, tuman, ko‘cha. Xaritadan nusxa olsangiz ham bo‘ladi.';

  @override
  String get plSearchButton => 'Qidirish';

  @override
  String get plRecentAddresses => 'Oldingi manzillar';

  @override
  String get plChooseTitle => 'Qayerdan izlaymiz?';

  @override
  String get plChooseBody =>
      'Yuqoridagi tugmalardan birini tanlang: o‘z atrofingizdan yoki boshqa manzil atrofidan — eng yaqin 5 ta joy chiqadi.';

  @override
  String plNearestMosques(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sizga eng yaqin $count ta masjid',
      one: 'Sizga eng yaqin masjid',
    );
    return '$_temp0';
  }

  @override
  String plNearestRestaurants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sizga eng yaqin $count ta oshxona',
      one: 'Sizga eng yaqin oshxona',
    );
    return '$_temp0';
  }

  @override
  String plNearestShops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sizga eng yaqin $count ta do‘kon',
      one: 'Sizga eng yaqin do‘kon',
    );
    return '$_temp0';
  }

  @override
  String get plNearestToAddress => 'Manzilga eng yaqinlari';

  @override
  String plHereNow(String city, String when) {
    return 'Joylashuvingiz: $city · $when';
  }

  @override
  String plHereNowNoCity(String when) {
    return 'Joylashuvingiz aniqlandi · $when';
  }

  @override
  String plSavedNote(String city, String when) {
    return 'Hozirgi joylashuvni aniqlab bo‘lmadi — ${city}dagi oldingi joylashuv bo‘yicha ($when)';
  }

  @override
  String plSavedNoteNoCity(String when) {
    return 'Hozirgi joylashuvni aniqlab bo‘lmadi — oldingi joylashuv bo‘yicha ($when)';
  }

  @override
  String get plLocatingYou => 'Joylashuvingiz aniqlanmoqda…';

  @override
  String get plLoadingPlaces => 'Joylar yuklanmoqda…';

  @override
  String get plDeniedBody =>
      'Eng yaqin joylarni topish uchun joylashuvga ruxsat bering — yoki manzil bo‘yicha izlang.';

  @override
  String get plAllow => 'Ruxsat berish';

  @override
  String get plBlockedBody =>
      'Joylashuvga ruxsat sozlamalarda o‘chirilgan. Uni yoqing — yoki manzil bo‘yicha izlang.';

  @override
  String get plOffBody =>
      'Telefonda joylashuv o‘chiq. Uni yoqing — yoki manzil bo‘yicha izlang.';

  @override
  String get plFailedBody =>
      'Joylashuvni aniqlab bo‘lmadi. Qayta urinib ko‘ring — yoki manzil bo‘yicha izlang.';

  @override
  String get plUseAddress => 'Manzil bo‘yicha izlash';

  @override
  String get plDetails => 'Batafsil';

  @override
  String plKmFromYou(String km) {
    return 'Sizdan $km';
  }

  @override
  String plKmFromAddress(String km) {
    return 'Manzildan $km';
  }

  @override
  String get themeToDay => 'Kunduzgi rejim';

  @override
  String get themeToNight => 'Tungi rejim';

  @override
  String get plSocialMore => 'Boshqa tarmoqdagi sahifasini bilasizmi?';

  @override
  String get plCallNumber => 'Qo‘ng‘iroq qilish';

  @override
  String get plPhotoLoading => 'Rasm yuklanmoqda…';

  @override
  String get plPhotoLoadingSpeed => 'Yuklanish tezligi internetingizga bog‘liq';

  @override
  String get plGettingThere => 'Qanday borish mumkin';

  @override
  String get plContact => 'Aloqa';

  @override
  String get plNewsTitle => 'Yangiliklar';

  @override
  String get carMarket => 'Avto Bozor';

  @override
  String get carTabBrowse => 'Ko‘rish';

  @override
  String get carTabSearch => 'Qidirish';

  @override
  String get carTabSaved => 'Sevimlilar';

  @override
  String carListings(String count) {
    return '$count ta e’lon';
  }

  @override
  String carAvailableSold(String available, String sold) {
    return '$available mavjud · $sold sotilgan';
  }

  @override
  String get carSearchSub => 'Atributlar bo‘yicha toping';

  @override
  String carSavedSub(String count) {
    return '$count ta saqlangan';
  }

  @override
  String get carLoading => 'Yuklanmoqda…';

  @override
  String get carMedianPrice => 'o‘rtacha narx';

  @override
  String get carNoneOnSale => 'Hozircha sotuvda yo‘q';

  @override
  String carSoldCount(String count) {
    return '$count sotilgan';
  }

  @override
  String get carSortNew => 'Yangi';

  @override
  String get carSortValue => 'Eng arzonlari';

  @override
  String get carSortPriceUp => 'Narx ↑';

  @override
  String get carSortPriceDown => 'Narx ↓';

  @override
  String get carSortMileage => 'Yurgani ↑';

  @override
  String get carSortYear => 'Yili ↓';

  @override
  String get carAll => 'Hammasi';

  @override
  String get carAvailable => 'Mavjud';

  @override
  String get carSold => 'Sotilgan';

  @override
  String get carEmptyAllTitle => 'Hozircha e’lon yo‘q';

  @override
  String get carEmptyAllBody => 'Tez orada yangi mashinalar qo‘shiladi';

  @override
  String get carEmptyModelTitle => 'Bu modelda e’lon yo‘q';

  @override
  String get carEmptyModelBody => 'Yuqoridagi nomdan boshqa modelni tanlang';

  @override
  String get carChannelTitle => 'Vegukin Avto — kanal';

  @override
  String get carChannelBody => 'Barcha yangi e’lonlar shu yerda jonli chiqadi';

  @override
  String get carOpen => 'Ochish';

  @override
  String get carLoadFailed => 'Yuklab bo‘lmadi';

  @override
  String get carCheckInternet => 'Internet aloqasini tekshiring';

  @override
  String get carDeal => 'Arzon';

  @override
  String get carNegotiable => 'Kelishiladi';

  @override
  String get carNoPrice => 'Narxi keltirilmagan';

  @override
  String get carFewDetails => 'Ma’lumot kam';

  @override
  String get carSeen => 'Ko‘rilgan';

  @override
  String get carSave => 'Saqlash';

  @override
  String get carUnsave => 'Saqlanganlardan olib tashlash';

  @override
  String get carFuelPetrol => 'Benzin';

  @override
  String get carFuelDiesel => 'Dizel';

  @override
  String get carFuelLpg => 'LPG';

  @override
  String get carFuelHybrid => 'Gibrid';

  @override
  String get carAutomatic => 'Avtomat';

  @override
  String get carManual => 'Mexanika';

  @override
  String get carNotGiven => 'Keltirilmagan';

  @override
  String get carPickModel => 'Marka va modelni tanlang';

  @override
  String get carPriceMax => 'Narx (gacha), ₩';

  @override
  String get carMileageMax => 'Yurgani (km gacha)';

  @override
  String get carYearFrom => 'Yildan';

  @override
  String get carFuel => 'Yoqilg‘i';

  @override
  String get carStatus => 'Holati';

  @override
  String carResults(String count) {
    return '$count ta natija';
  }

  @override
  String get carNothingFound => 'Hech narsa topilmadi';

  @override
  String get carWidenFilters => 'Filtrlarni kengaytiring';

  @override
  String get carClearFilters => 'Tozalash';

  @override
  String get carSavedEmptyTitle => 'Sevimlilar bo‘sh';

  @override
  String get carSavedEmptyBody => 'Yoqqan mashinalarni ❤ tugmasi bilan saqlang';

  @override
  String get carStartBrowsing => 'Ko‘rishni boshlash';

  @override
  String get carPickBrand => 'Markani tanlang';

  @override
  String get carAnyBrand => 'Har qanday';

  @override
  String get carAllBrands => 'barcha markalar';

  @override
  String carBrandListings(String count) {
    return '$count e’lon';
  }

  @override
  String carAllOf(String brand) {
    return 'Barcha $brand';
  }

  @override
  String get carSearchHint => 'Qidirish…';

  @override
  String get carCatalogFailed =>
      'Markalar yuklanmadi. Internetni tekshirib, qayta oching.';

  @override
  String carViews(String count) {
    return '$count marta ko‘rilgan';
  }

  @override
  String get carNotice =>
      'Ma’lumotlar e’lon matnidan avtomatik o‘qilgan va xato bo‘lishi mumkin. Aniq narx va tafsilotlar uchun e’lon matnini diqqat bilan o‘qing.';

  @override
  String get carPostText => 'E’lon matni';

  @override
  String get carNoText => 'Matn keltirilmagan';

  @override
  String get carReadMore => 'Ko‘proq o‘qish';

  @override
  String get carReadLess => 'Yopish';

  @override
  String carSource(String name) {
    return 'Manba: $name kanali';
  }

  @override
  String get carPriceAnalysis => 'Narx tahlili';

  @override
  String get carVeryCheap => 'Juda arzon';

  @override
  String get carCheap => 'Arzon';

  @override
  String get carAtMarket => 'Bozor narxida';

  @override
  String get carPricier => 'Qimmatroq';

  @override
  String get carExpensive => 'Qimmat';

  @override
  String get carNearAverage => 'o‘rtachaga yaqin';

  @override
  String carBelowAverage(String percent) {
    return 'o‘rtachadan $percent% arzon';
  }

  @override
  String carAboveAverage(String percent) {
    return 'o‘rtachadan $percent% qimmat';
  }

  @override
  String carFewComparables(String count) {
    return 'faqat $count ta taqqoslash bor';
  }

  @override
  String carScaleCheap(String price) {
    return 'arzon $price';
  }

  @override
  String carScaleDear(String price) {
    return 'qimmat $price';
  }

  @override
  String carNearYearBasis(String year, String count, String median) {
    return '$year y. atrofidagi $count ta · o‘rtacha $median';
  }

  @override
  String carModelBasis(String count, String median) {
    return '$count ta sotuvda · o‘rtacha $median';
  }

  @override
  String carSoldBasis(String count, String median) {
    return '$count ta sotilgan · $median';
  }

  @override
  String get carDetails => 'Batafsil';

  @override
  String get carGeneration => 'Avlod';

  @override
  String get carYear => 'Yili';

  @override
  String get carMileage => 'Yurgani';

  @override
  String get carGearbox => 'Karobka';

  @override
  String get carLegal => 'Hujjatlari';

  @override
  String get carLegalOk => 'Legal';

  @override
  String get carLegalNoReg => 'Oformleniyasiz';

  @override
  String get carRegistration => 'Nomiga o‘tkazish';

  @override
  String get carRequired => 'Shart';

  @override
  String get carNotRequired => 'Shart emas';

  @override
  String get carPosted => 'E’lon';

  @override
  String get carSourceLabel => 'Manba';

  @override
  String get carContact => 'Bog‘lanish';

  @override
  String get carSellerPhone => 'Sotuvchi telefoni';

  @override
  String get carCall => 'Qo‘ng‘iroq';

  @override
  String get carCopy => 'Nusxa';

  @override
  String get carCopied => 'Raqam nusxalandi';

  @override
  String get carWriteOnTelegram => 'Telegram orqali yozish';

  @override
  String get carWrite => 'Yozish';

  @override
  String get carNumberInText => 'Raqam e’lon matnida';

  @override
  String get carSimilar => 'O‘xshash mashinalar';

  @override
  String get carSimilarSub => 'narx bo‘yicha';

  @override
  String get carNoComparables => 'Taqqoslash uchun e’lon yo‘q';

  @override
  String get carListingFailed => 'E’lon yuklanmadi';

  @override
  String carVideoSize(String size) {
    return 'Video · $size MB';
  }

  @override
  String get carListing => 'E’lon';

  @override
  String get carTabAlerts => 'Xabarnoma';

  @override
  String get carTabSell => 'Sotish';

  @override
  String get carAlertsTitle => 'Xabarnomalar';

  @override
  String carAlertsActive(String count) {
    return '$count ta faol';
  }

  @override
  String get carNewAlert => 'Yangi xabarnoma';

  @override
  String get carAnyCar => 'Barcha mashinalar';

  @override
  String get carCreateAlert => 'Xabarnoma yaratish';

  @override
  String get carMyAlerts => 'Mening xabarnomalarim';

  @override
  String get carNoAlertsTitle => 'Xabarnoma yo‘q';

  @override
  String get carNoAlertsBody => 'Yangi mos e’lon chiqsa, sizga bildiramiz';

  @override
  String get carAllListings => 'Barcha e’lonlar';

  @override
  String get carAlertNeedsFilter =>
      'Kamida bitta filtr tanlang (model, narx, yurgani, yil yoki yoqilg‘i).';

  @override
  String get carAlertDuplicate => 'Bunday xabarnoma allaqachon mavjud.';

  @override
  String get carAlertLimit => 'Xabarnomalar soni chegarasiga yetdingiz.';

  @override
  String get carAlertCreated =>
      'Xabarnoma yaratildi: mos e’lon chiqsa, telefoningizga keladi.';

  @override
  String get carAlertDeleted => 'Xabarnoma o‘chirildi';

  @override
  String get carSignInAlertsTitle => 'Mos mashina chiqsa, xabar beramiz';

  @override
  String get carSignInAlertsBody =>
      'Xabarnoma uchun akkauntga kiring. Ko‘rish va saqlash uchun kirish shart emas.';

  @override
  String get carSignInButton => 'Akkauntga kirish';

  @override
  String get carPushOff =>
      'Bildirishnomalar o‘chiq — xabarnomalar telefonga kelmaydi.';

  @override
  String get carPushOn => 'Yoqish';

  @override
  String get carErrorGeneric => 'Xatolik yuz berdi. Qayta urinib ko‘ring.';

  @override
  String get carMyPosts => 'Mening e’lonlarim';

  @override
  String get carNewPost => 'Yangi e’lon qo‘shish';

  @override
  String get carNewPostSub => 'Mashinangizni soting';

  @override
  String get carNoPostsTitle => 'Hali e’lon yo‘q';

  @override
  String get carNoPostsBody =>
      'Yuqoridagi tugma orqali birinchi e’loningizni joylang — bir necha daqiqada tayyor bo‘ladi.';

  @override
  String get carStatePending => 'Ko‘rib chiqilmoqda';

  @override
  String get carStateApproved => 'Joylandi';

  @override
  String get carStateRejected => 'Rad etildi';

  @override
  String get carStateChanges => 'O‘zgartirish kerak';

  @override
  String get carStateDraft => 'Qoralama';

  @override
  String get carEdit => 'Tahrirlash';

  @override
  String get carMarkSold => 'Sotildi';

  @override
  String get carDelete => 'O‘chirish';

  @override
  String get carSoldConfirmTitle => 'Sotildi deb belgilash?';

  @override
  String get carSoldConfirmBody =>
      'E’lon bozorda sotilgan sifatida ko‘rsatiladi.';

  @override
  String get carSoldConfirmYes => 'Ha, sotildi';

  @override
  String get carMarkedSold => 'Sotilgan deb belgilandi';

  @override
  String get carDeleteConfirmTitle => 'E’lonni o‘chirish?';

  @override
  String get carDeleteConfirmBody => 'Bu amalni qaytarib bo‘lmaydi.';

  @override
  String get carDeleted => 'O‘chirildi';

  @override
  String get carCancel => 'Bekor qilish';

  @override
  String get carSignInSellTitle => 'Mashinangizni soting';

  @override
  String get carSignInSellBody => 'E’lon joylash uchun akkauntga kiring.';

  @override
  String get carNewPostTitle => 'Yangi e’lon';

  @override
  String get carEditPostTitle => 'E’lonni tahrirlash';

  @override
  String get carPhotos => 'Rasmlar va video';

  @override
  String get carPhotosHint =>
      'Birinchisi muqova bo‘ladi. Ko‘pi bilan 10 ta, har bir video ≤ 50MB.';

  @override
  String get carPhotosLocked =>
      'Yuborilgandan keyin rasmlarni o‘zgartirib bo‘lmaydi.';

  @override
  String get carAddMedia => 'Qo‘shish';

  @override
  String get carCover => 'Muqova';

  @override
  String get carCarSection => 'Mashina';

  @override
  String get carBrand => 'Marka';

  @override
  String get carModel => 'Model';

  @override
  String get carPickBrandFirst => 'Avval markani tanlang';

  @override
  String get carPickModelTitle => 'Modelni tanlang';

  @override
  String get carOtherModel => 'Boshqa model (qo‘lda)';

  @override
  String get carModelHint => 'masalan: Sonata';

  @override
  String get carPickYear => 'Yilni tanlang';

  @override
  String get carGenerationOptional => 'Avlod (ixtiyoriy)';

  @override
  String get carMileageLabel => 'Yurgan masofasi (km)';

  @override
  String get carFuelType => 'Yoqilg‘i turi';

  @override
  String get carPriceSection => 'Narx va hujjatlar';

  @override
  String get carPriceLabel => 'Narxi (₩)';

  @override
  String get carNegotiableSub => 'Xaridor bilan kelishish mumkin';

  @override
  String get carLegalLabel => 'Rasmiy holati';

  @override
  String get carLegalNo => 'Nolegal';

  @override
  String get carRegQuestion => 'Nomiga o‘tkazish kerakmi?';

  @override
  String get carRegYes => 'Ha, kerak';

  @override
  String get carPhoneLabel => 'Telefon raqam';

  @override
  String get carContactHint => 'Kamida bittasini to‘ldiring.';

  @override
  String get carDescription => 'Tavsif';

  @override
  String get carDescriptionHint =>
      'Holati, butligi, almashtirilgan qismlar, sababi...';

  @override
  String get carSubmit => 'Ko‘rib chiqishga yuborish';

  @override
  String get carSaveChanges => 'Saqlash';

  @override
  String get carRequiredMissing => 'Majburiy maydonlarni to‘ldiring';

  @override
  String get carChangesSaved => 'Saqlandi';

  @override
  String get carSubmitted =>
      'Yuborildi! Admin tekshirgach e’loningiz joylanadi.';

  @override
  String carUploading(String done, String total) {
    return 'Yuklanmoqda: $done / $total';
  }

  @override
  String get carVideoTooBig => 'Video 50MB dan katta';

  @override
  String get carMediaLimit => 'Ko‘pi bilan 10 ta';

  @override
  String get carNeedPhoto => 'Kamida bitta rasm qo‘shing';

  @override
  String get carDupTitle => 'Bu mashina allaqachon e’lon qilingan';

  @override
  String get carDupBody =>
      'Shu raqam va shu mashina bilan e’lon bor. Bir xil e’lonni qayta joylab bo‘lmaydi.';

  @override
  String get carDupOwn => 'Sizning e’loningiz';

  @override
  String get carOk => 'Tushunarli';

  @override
  String get carChannelNudge =>
      'Yangi e’lonlarni birinchi bo‘lib ko‘rish uchun @vegukin_car kanaliga a’zo bo‘ling';

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
    return 'Bugungi tashriflar: $count';
  }
}
