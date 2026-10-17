import 'package:intl/intl.dart';

import '../../core/app_language.dart';
import '../../l10n/app_localizations.dart';
import 'prayer_models.dart';

/// "Shanba, 17-oktabr" / "Суббота, 17 октября" / "Saturday, 17 October".
String gregorianLine(DateTime date, AppLanguage language) {
  final pattern = language == AppLanguage.uz ? 'EEEE, d-MMMM' : 'EEEE, d MMMM';
  final text = DateFormat(pattern, language.code).format(date);
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

const _hijriMonths = {
  AppLanguage.uz: [
    'Muharram', 'Safar', 'Rabiul avval', 'Rabiul oxir', 'Jumodul avval',
    'Jumodul oxir', 'Rajab', 'Sha’bon', 'Ramazon', 'Shavvol', 'Zulqa’da',
    'Zulhijja',
  ],
  AppLanguage.ru: [
    'Мухаррам', 'Сафар', 'Раби аль-авваль', 'Раби ас-сани', 'Джумада аль-уля',
    'Джумада ас-сания', 'Раджаб', 'Шаабан', 'Рамадан', 'Шавваль', 'Зуль-када',
    'Зуль-хиджа',
  ],
  AppLanguage.en: [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Ula',
    'Jumada al-Akhirah', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal',
    'Dhu al-Qadah', 'Dhu al-Hijjah',
  ],
};

/// "6-Jumodul avval, 1448" / "6 Джумада аль-уля 1448" / "6 Jumada al-Ula 1448".
String hijriLine(PrayerDay day, AppLanguage language) {
  final month = _hijriMonths[language]![(day.hijriMonth - 1).clamp(0, 11)];
  return language == AppLanguage.uz
      ? '${day.hijriDay}-$month, ${day.hijriYear}'
      : '${day.hijriDay} $month ${day.hijriYear}';
}

String prayerName(AppLocalizations s, Prayer prayer) => switch (prayer) {
      Prayer.fajr => s.prayerFajr,
      Prayer.sunrise => s.prayerSunrise,
      Prayer.dhuhr => s.prayerDhuhr,
      Prayer.asr => s.prayerAsr,
      Prayer.maghrib => s.prayerMaghrib,
      Prayer.isha => s.prayerIsha,
    };

/// Names what the countdown counts to. Sunrise is not a prayer, so before it
/// the label says how long Fajr has left instead.
String countdownLabel(AppLocalizations s, Prayer next) => switch (next) {
      Prayer.fajr => s.untilFajr,
      Prayer.sunrise => s.untilFajrEnds,
      Prayer.dhuhr => s.untilDhuhr,
      Prayer.asr => s.untilAsr,
      Prayer.maghrib => s.untilMaghrib,
      Prayer.isha => s.untilIsha,
    };

/// "2 soat oldin" — how old the saved location is.
String ageText(AppLocalizations s, Duration age) {
  if (age.inMinutes < 1) return s.locationJustNow;
  if (age.inMinutes < 60) return s.locationMinutesAgo(age.inMinutes);
  if (age.inHours < 24) return s.locationHoursAgo(age.inHours);
  return s.locationDaysAgo(age.inDays);
}

String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String countdownText(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}
