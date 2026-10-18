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
      'Agar ushbu bot sizga foydali bo‘layotgan bo‘lsa va uning ishlashi hamda rivojlanishiga o‘z hissangizni qo‘shmoqchi bo‘lsangiz, quyidagi hisob raqamga istalgan miqdorda moddiy mablag‘laringizni yuborishingiz mumkin.';

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
  String get communityHeroSubtitle => 'Bot foydalanuvchilari jamiyati';

  @override
  String get communityJoinNow => 'Hoziroq qo‘shiling';

  @override
  String get communityPurposeTitle => 'Guruh maqsadi';

  @override
  String get communityPurposeText =>
      'Ushbu guruh Muslim Vegukin Bot foydalanuvchilari uchun rasmiy muhokama maydonidir. Bu yerda bot bilan bog‘liq barcha masalalarni muhokama qilishingiz mumkin.';

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
  String get communityTopicIdeaBody => 'Botni yaxshilash uchun fikrlaringiz';

  @override
  String get communityTopicBugTitle => 'Xatolar haqida xabar berish';

  @override
  String get communityTopicBugBody => 'Agar botda muammo topsangiz';

  @override
  String get communityTopicNewsTitle => 'Bot yangiliklari';

  @override
  String get communityTopicNewsBody =>
      'Yangi funksiyalar va o‘zgarishlar haqida e’lonlar';

  @override
  String get communityTopicBetaTitle => 'Beta versiyalar muhokamasi';

  @override
  String get communityTopicBetaBody =>
      'Yangi funksiyalarni ommaga chiqarishdan oldin sinab ko‘rish';

  @override
  String get communityTopicQuestionTitle => 'Bot haqida savollar';

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
  String get communityBanned3Title => 'Bot bilan bog‘liq bo‘lmagan savollar';

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
  String get communityBanned5Body => 'Bot bilan aloqasi bo‘lmagan suhbatlar';

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
  String get barcodeCode => 'Shtrix-kod';

  @override
  String get barcodeCopyCode => 'Kodni nusxalash';

  @override
  String get barcodeCopied => 'Nusxalandi';

  @override
  String get barcodeScanNext => 'Keyingisini skanerlash';

  @override
  String get barcodeShare => 'Ulashish';

  @override
  String get barcodeReport => 'Xatoni bildirish';

  @override
  String barcodeReportTemplate(String name, String code) {
    return '⚠️ Xato\nMahsulot: $name\nShtrix-kod: $code\nXato nimada: ';
  }

  @override
  String get barcodeNotFound => 'Mahsulot topilmadi';

  @override
  String get barcodeNotFoundDesc =>
      'Ushbu mahsulot hozircha bazada yo‘q. Tez orada qo‘shilishi mumkin.';

  @override
  String get barcodeAddProduct => 'Bazaga qo‘shishga yordam bering';

  @override
  String get barcodeAddProductHint =>
      'Shablon nusxalanadi. Guruhga joylab, mahsulot va tarkibi rasmini yuboring.';

  @override
  String barcodeAddTemplate(String code) {
    return '📦 Yangi mahsulot\nShtrix-kod: $code\nNomi: \nDo‘kon: \n(mahsulot va tarkibi rasmini ilova qiling)';
  }

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
  String get themeToDay => 'Kunduzgi rejim';

  @override
  String get themeToNight => 'Tungi rejim';
}
