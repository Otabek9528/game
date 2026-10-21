import 'package:intl/intl.dart';

import '../../core/app_language.dart';
import 'hikorea_models.dart';

/// "GIMHAE BRANCH OFFICE" → "Gimhae Branch Office"; doubled spaces go.
String officeName(String name) {
  final text = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text != text.toUpperCase()) return text;
  return text.toLowerCase().replaceAllMapped(RegExp(r"(^|[\s(-])([a-z])"), (m) => '${m[1]}${m[2]!.toUpperCase()}');
}

final _branchOfOffice = RegExp(r'^(.+?) Immigration Office (.+?) Branch Office$', caseSensitive: false);
final _branch = RegExp(r'^(.+?) Branch Office$', caseSensitive: false);
final _main = RegExp(r'^(.+?) Immigration Office$', caseSensitive: false);

/// An office as its place, and whether it is a branch (of which office):
/// "Daejeon Immigration Office Cheonan Branch Office" → Cheonan, a branch
/// of Daejeon. Lists lead with the place: every name ends alike.
({String place, bool branch, String? of}) officeParts(String name) {
  final full = officeName(name);
  if (_branchOfOffice.firstMatch(full) case final m?) return (place: m[2]!, branch: true, of: m[1]);
  if (_branch.firstMatch(full) case final m?) return (place: m[1]!, branch: true, of: null);
  if (_main.firstMatch(full) case final m?) return (place: m[1]!, branch: false, of: null);
  return (place: full, branch: false, of: null);
}

final _afternoon = RegExp(r'AFTER\s*0?9:36', caseSensitive: false);
final _bracket = RegExp(r'\s*\(([^()]*)\)');
final _months = RegExp(
  r'January|February|March|April|May|June|July|August|September|October|November|December',
  caseSensitive: false,
);
final _datesOnly = RegExp(r'^[\d.~,\s]*$');

/// A counter's name without the dates HiKorea keeps in it ("(2023.10.14.~,
/// AFTER 09:36)", "(April 16, 2024~)"), its place set apart from the rest
/// ("Ansan Center] Residence Control" → "Ansan Center · Residence Control"),
/// and whether its reception opens at 09:36. The web page's tidying left
/// "(2023.10.14.~," in 13 of the 58 names.
({String name, bool afternoon}) boothName(HkDesk desk, AppLanguage language) {
  final raw = inLanguage(desk.booth, language.code);
  var name = raw.replaceAllMapped(_bracket, (m) {
    final inside = m[1]!.replaceAll(_afternoon, '').replaceAll(_months, '');
    return _datesOnly.hasMatch(inside) ? '' : m[0]!;
  });
  name = name.replaceAll(_afternoon, '');
  // The place first, in brackets: "[Eumseong Center] General …", or
  // "Andong Immigration Center] General …" that lost its "[" on the way.
  final place = RegExp(r'^\s*\[?([^\[\]]+)\]\s*').firstMatch(name);
  if (place != null) name = '${place[1]!.trim()} · ${name.substring(place.end)}';
  name = name
      .replaceAllMapped(RegExp(r'([^\s(\[])([(\[])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,;:-]+|[\s,;:(-]+$'), '');
  return (name: name, afternoon: _afternoon.hasMatch(raw));
}

/// The same, for a watch, which carries its counter's texts.
String watchBooth(HkWatch watch, AppLanguage language) =>
    boothName(HkDesk(seq: watch.deskSeq, booth: watch.booth), language).name;

/// HiKorea's provinces, in English. The server pairs the Korean and English
/// names by position and gets five of them wrong, so the app has its own.
const provincesInEnglish = {
  '서울': 'Seoul',
  '부산': 'Busan',
  '대구': 'Daegu',
  '인천': 'Incheon',
  '광주': 'Gwangju',
  '대전': 'Daejeon',
  '울산': 'Ulsan',
  '세종': 'Sejong',
  '경기': 'Gyeonggi',
  '강원': 'Gangwon',
  '충북': 'Chungbuk',
  '충남': 'Chungnam',
  '전북': 'Jeonbuk',
  '전남': 'Jeonnam',
  '경북': 'Gyeongbuk',
  '경남': 'Gyeongnam',
  '제주': 'Jeju',
};

/// "21-oktabr" (uz), "21 октября", "21 October".
String dayMonth(DateTime day, AppLanguage language) =>
    DateFormat(language == AppLanguage.uz ? 'd-MMMM' : 'd MMMM', language.code).format(day);

/// "21-oktabr, 2026" (uz), "21 октября 2026", "21 October 2026".
String dayMonthYear(DateTime day, AppLanguage language) =>
    DateFormat(language == AppLanguage.uz ? 'd-MMMM, y' : 'd MMMM y', language.code).format(day);

String capitalized(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// "Payshanba", "Четверг", "Thursday".
String weekdayName(DateTime day, AppLanguage language) => capitalized(DateFormat('EEEE', language.code).format(day));

/// "Oktabr 2026", "Октябрь 2026", "October 2026".
String monthTitle(DateTime month, AppLanguage language) =>
    capitalized(DateFormat('LLLL y', language.code).format(month));

/// Monday first: "Du", "Пн", "Mon".
List<String> weekdayLetters(AppLanguage language) => [
      for (var d = 0; d < 7; d++) capitalized(DateFormat('E', language.code).format(DateTime(2024, 1, 1 + d))),
    ];
