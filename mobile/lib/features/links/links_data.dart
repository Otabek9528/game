import 'package:flutter/material.dart';

// The web page's lists (pages/links/links.js and links.html), with what the
// app adds: where each job group is, how its city is also spelt, and what
// each "Korea life" link is about, in three languages.

/// Parts of Korea, for when the user's place is unknown.
enum LinkRegion { nationwide, capital, chungcheong, jeolla, gyeongsang, other }

/// What a "Korea life" link is about.
enum LifeTopic { official, news, legal, insurance, work, everyday, other }

/// A city the job groups are for: where it is, and the ways people write it.
class LinkCity {
  const LinkCity(this.name, this.hangul, this.lat, this.lon, this.region, [this.spellings = const []]);

  final String name;
  final String hangul;
  final double lat;
  final double lon;
  final LinkRegion region;

  /// Other spellings, as Uzbeks and Russians write it: "Chonan", "Чонан".
  final List<String> spellings;
}

const linkCities = {
  'ansan': LinkCity('Ansan', '안산', 37.3219, 126.8309, LinkRegion.capital, ['Ансан']),
  'anseong': LinkCity('Anseong', '안성', 37.0080, 127.2797, LinkRegion.capital, ['Ansong', 'Ансон']),
  'andong': LinkCity('Andong', '안동', 36.5684, 128.7294, LinkRegion.gyeongsang, ['Андон']),
  'bucheon': LinkCity('Bucheon', '부천', 37.5034, 126.7660, LinkRegion.capital, ['Puchon', 'Buchon', 'Пучхон']),
  'busan': LinkCity('Busan', '부산', 35.1796, 129.0756, LinkRegion.gyeongsang, ['Pusan', 'Пусан']),
  'cheongju': LinkCity('Cheongju', '청주', 36.6424, 127.4890, LinkRegion.chungcheong, ['Chongju', 'Чхонджу']),
  'cheonan': LinkCity('Cheonan', '천안', 36.8151, 127.1139, LinkRegion.chungcheong, ['Chonan', 'Чхонан', 'Чонан']),
  'asan': LinkCity('Asan', '아산', 36.7898, 127.0018, LinkRegion.chungcheong, ['Асан']),
  'seonghwan': LinkCity('Seonghwan', '성환', 36.9156, 127.1312, LinkRegion.chungcheong, ['Songhwan']),
  'daejeon': LinkCity('Daejeon', '대전', 36.3504, 127.3845, LinkRegion.chungcheong, ['Dejon', 'Tejon', 'Daejon', 'Тэджон']),
  'gunsan': LinkCity('Gunsan', '군산', 35.9676, 126.7366, LinkRegion.jeolla, ['Kunsan', 'Кунсан']),
  'daeso': LinkCity('Daeso', '대소', 36.9760, 127.5300, LinkRegion.chungcheong, ['Eumseong', 'Umsong', '음성']),
  'jincheon': LinkCity('Jincheon', '진천', 36.8950, 127.5200, LinkRegion.chungcheong, ['Deoksan', 'Doksan', 'Chinchon', '덕산']),
  'yangju': LinkCity('Yangju', '양주', 37.7853, 127.0458, LinkRegion.capital, ['Янджу']),
  'icheon': LinkCity('Icheon', '이천', 37.2720, 127.4350, LinkRegion.capital, ['Ichon', 'Ичхон']),
  'iksan': LinkCity('Iksan', '익산', 35.9483, 126.9577, LinkRegion.jeolla, ['Иксан']),
  'incheon': LinkCity('Incheon', '인천', 37.4563, 126.7052, LinkRegion.capital, ['Inchon', 'Инчхон']),
  'jecheon': LinkCity('Jecheon', '제천', 37.1326, 128.1910, LinkRegion.chungcheong, ['Chechon', 'Danyang', '단양']),
  'gwangju': LinkCity('Gwangju', '광주', 35.1595, 126.8526, LinkRegion.jeolla, ['Kvanju', 'Gvangju', 'Kwangju', 'Кванджу']),
  'gimhae': LinkCity('Gimhae', '김해', 35.2285, 128.8894, LinkRegion.gyeongsang, ['Kimhe', 'Kimhae', 'Кимхэ']),
  'gimpo': LinkCity('Gimpo', '김포', 37.6153, 126.7156, LinkRegion.capital, ['Kimpo', 'Кимпхо']),
  'geoje': LinkCity('Geoje', '거제', 34.8806, 128.6211, LinkRegion.gyeongsang, ['Koje', 'Goje', 'Кодже']),
  'paju': LinkCity('Paju', '파주', 37.7599, 126.7802, LinkRegion.capital, ['Паджу']),
  'seongnam': LinkCity('Seongnam', '성남', 37.4200, 127.1265, LinkRegion.capital, ['Songnam', 'Сонам']),
  'seoul': LinkCity('Seoul', '서울', 37.5665, 126.9780, LinkRegion.capital, ['Seul', 'Сеул']),
  'uijeongbu': LinkCity('Uijeongbu', '의정부', 37.7381, 127.0337, LinkRegion.capital, ['Ijongbu', 'Uijongbu', 'Ыйджонбу']),
  'yeosu': LinkCity('Yeosu', '여수', 34.7604, 127.6622, LinkRegion.jeolla, ['Yosu', 'Ysu', 'Ёсу']),
};

/// Each job group's cities; none for the ones covering all of Korea.
const jobCities = <String, List<String>>{
  'https://t.me/Ansanish': ['ansan'],
  'https://t.me/anseong_work': ['anseong'],
  'https://t.me/Ansongda_ish': ['anseong'],
  'https://t.me/andongishguruppa': ['andong'],
  'https://t.me/Bucheon_Logen_tekpe': ['bucheon'],
  'https://t.me/ishbusan': ['busan'],
  'https://t.me/pusan_ish': ['busan'],
  'https://t.me/cheongjuuzbekgroup': ['cheongju'],
  'https://t.me/ChonanAsan_ish': ['cheonan', 'asan'],
  'https://t.me/chonanuzbeklar': ['cheonan'],
  'https://t.me/daejeonarbayt': ['daejeon'],
  'https://t.me/gruppa_ishbor': ['daejeon', 'gunsan'],
  'https://t.me/+6ApjKGye3NllMmVl': ['daeso'],
  'https://t.me/daeso_deoksan_jincheon_samseong': ['daeso', 'jincheon'],
  'https://t.me/salievdejon': ['daejeon'],
  'https://t.me/Gunsandaishbor': ['gunsan'],
  'https://t.me/helpinyangju': ['yangju'],
  'https://t.me/icheon_city': ['icheon'],
  'https://t.me/koreaish1': ['iksan'],
  'https://t.me/Incheon_Lotte_tekpe': ['incheon'],
  'https://t.me/jecheonish': ['jecheon'],
  'https://t.me/Katta_Gwangju_gvangju': ['gwangju'],
  'https://t.me/Kimheish': ['gimhae'],
  'https://t.me/Gimpodagiuzbeklar': ['gimpo'],
  'https://t.me/kojeishelon': ['geoje'],
  'https://t.me/korea_ish_bor': [],
  'https://t.me/Koreya_tekpe_arbayt_ozbeklar': [],
  'https://t.me/paju_uz': ['paju'],
  'https://t.me/SeongnamGroup': ['seongnam'],
  'https://t.me/Seoul_Lotte_tekpe': ['seoul'],
  'https://t.me/Seoul_tekpe_arbayt': ['seoul'],
  'https://t.me/Seonghwanuz': ['seonghwan'],
  'https://t.me/Ijongbudagi_uzbeklar': ['uijeongbu'],
  'https://t.me/YsuStuents': ['yeosu'],
  'https://t.me/ansansadonrabota': ['ansan'],
  'https://t.me/KoreaParanReklama': [],
};

/// A "Korea life" link: its topic, an icon, and its name in Russian and
/// English (the Uzbek one is the web page's).
class LifeInfo {
  const LifeInfo(this.topic, this.icon, this.ru, this.en);

  final LifeTopic topic;
  final IconData icon;
  final String ru;
  final String en;
}

const lifeInfo = <String, LifeInfo>{
  'https://t.me/uzbek_students_korea': LifeInfo(LifeTopic.news, Icons.campaign_rounded,
      'Важные новости для узбекистанцев в Корее', 'Important news for Uzbeks in Korea'),
  'https://t.me/KoreyaQonun':
      LifeInfo(LifeTopic.legal, Icons.gavel_rounded, 'Консультации по правовым вопросам', 'Legal advice'),
  'https://t.me/health_insurance_uz': LifeInfo(LifeTopic.insurance, Icons.health_and_safety_rounded,
      'О медицинском страховании в Корее', 'Korean health insurance'),
  'https://t.me/koreya_mashina_sugurta': LifeInfo(LifeTopic.insurance, Icons.directions_car_rounded,
      'Правила дорожного движения и автострахование', 'Traffic rules and car insurance'),
  'https://t.me/HaksengUz': LifeInfo(LifeTopic.work, Icons.work_rounded,
      'Работа в Корее: собеседования, резюме, нетворкинг', 'Working in Korea: interviews, CVs, networking'),
  'https://t.me/wayu_korea': LifeInfo(LifeTopic.official, Icons.groups_rounded,
      'Ассоциация молодёжи Узбекистана (Южная Корея)', 'Uzbekistan Youth Association (South Korea)'),
  'https://t.me/UzEmbassy_kr_bot': LifeInfo(LifeTopic.official, Icons.account_balance_rounded,
      'Официальный бот посольства Узбекистана', 'Official bot of the Embassy of Uzbekistan'),
  'https://t.me/Koreyaginam': LifeInfo(LifeTopic.everyday, Icons.flight_land_rounded,
      'Для тех, кто собирается в Корею', 'For those planning to come to Korea'),
  'https://t.me/salomkoreya':
      LifeInfo(LifeTopic.news, Icons.newspaper_rounded, 'Канал для живущих в Корее', 'A channel for people in Korea'),
  'https://t.me/seul_global_markazi': LifeInfo(LifeTopic.news, Icons.lightbulb_outline_rounded,
      'Что нужно знать соотечественникам в Корее', 'What compatriots in Korea should know'),
  'https://t.me/f3_vizaga':
      LifeInfo(LifeTopic.legal, Icons.badge_rounded, 'Группа подавших на визу F-3', 'Group for F-3 visa applicants'),
  'https://t.me/uzbeknur_korea': LifeInfo(LifeTopic.news, Icons.public_rounded, 'Всё о Корее', 'All about Korea'),
  'https://t.me/misterberd': LifeInfo(LifeTopic.legal, Icons.school_rounded, 'Визы, гранты и новости Кореи',
      'Korean visas, grants and news'),
  'https://t.me/ganiev_tarjimon': LifeInfo(LifeTopic.legal, Icons.translate_rounded,
      'Юридическая помощь и перевод', 'Legal help and translation'),
  'https://t.me/travelkoreabest':
      LifeInfo(LifeTopic.everyday, Icons.landscape_rounded, 'Места отдыха в Корее', 'Places to visit in Korea'),
  'https://t.me/korea_taxi':
      LifeInfo(LifeTopic.everyday, Icons.local_taxi_rounded, 'Попутное такси в Корее', 'Ride sharing in Korea'),
  'https://t.me/StarbooksKoreya':
      LifeInfo(LifeTopic.everyday, Icons.menu_book_rounded, 'Заказ книг', 'Ordering books'),
};

/// The web page's lists as shipped with the app: used until (or unless) the
/// web page's current lists are fetched.
const bundledJobs = [
  ('Ansanda ish', 'https://t.me/Ansanish'),
  ('Anseong work', 'https://t.me/anseong_work'),
  ('Ansongda ish guruhi', 'https://t.me/Ansongda_ish'),
  ('Andongda ish guruhi', 'https://t.me/andongishguruppa'),
  ('Bucheon Logen tekpe', 'https://t.me/Bucheon_Logen_tekpe'),
  ("Busan - ish e'lonlari", 'https://t.me/ishbusan'),
  ("Busan ish e'lon", 'https://t.me/pusan_ish'),
  ("Cheongjudagi(청주) o'zbeklar", 'https://t.me/cheongjuuzbekgroup'),
  ("Chonan Asan o'zbeklar ishi va faoliyati", 'https://t.me/ChonanAsan_ish'),
  ("Chonan o'zbeklar", 'https://t.me/chonanuzbeklar'),
  ('Daejeon arbayt guruhi', 'https://t.me/daejeonarbayt'),
  ('Daejeon, Gunsan arbayt', 'https://t.me/gruppa_ishbor'),
  ('Daeso arbayt', 'https://t.me/+6ApjKGye3NllMmVl'),
  ('Daeso Deoksan Jincheon Mgueok', 'https://t.me/daeso_deoksan_jincheon_samseong'),
  ('Dejon City', 'https://t.me/salievdejon'),
  ('Gunsandagi musofirlar', 'https://t.me/Gunsandaishbor'),
  ('Help in Yangju', 'https://t.me/helpinyangju'),
  ('Icheon City', 'https://t.me/icheon_city'),
  ('Iksan ish', 'https://t.me/koreaish1'),
  ('Incheon Lotte tekpe', 'https://t.me/Incheon_Lotte_tekpe'),
  ('Jecheon va Danyang(제천 단양)', 'https://t.me/jecheonish'),
  ('Katta Gwangju | 광주광역시', 'https://t.me/Katta_Gwangju_gvangju'),
  ('Kimhe ish 김해 일', 'https://t.me/Kimheish'),
  ("Gimpodagi o'zbeklar", 'https://t.me/Gimpodagiuzbeklar'),
  ('Koje yangiliklari', 'https://t.me/kojeishelon'),
  ('Korea ish bor', 'https://t.me/korea_ish_bor'),
  ('Koreya tekpe arbayt', 'https://t.me/Koreya_tekpe_arbayt_ozbeklar'),
  ("Paju city e'lonlari", 'https://t.me/paju_uz'),
  ("Seongnam ish e'lon", 'https://t.me/SeongnamGroup'),
  ('Seoul Lotte tekpe', 'https://t.me/Seoul_Lotte_tekpe'),
  ('Seoul tekpe', 'https://t.me/Seoul_tekpe_arbayt'),
  ('Seonghwanada ish bor', 'https://t.me/Seonghwanuz'),
  ('Uijeongbudagilar guruhi', 'https://t.me/Ijongbudagi_uzbeklar'),
  ('Yeosu guruh', 'https://t.me/YsuStuents'),
  ('Ансан (Работа)', 'https://t.me/ansansadonrabota'),
  ('Гр.Паран. Реклама', 'https://t.me/KoreaParanReklama'),
];

const bundledLife = [
  ("Koreyadagi O'zbekistonliklar uchun muhim yangiliklar", 'https://t.me/uzbek_students_korea'),
  ("Huquqiy masalalar bo'yicha maslahat", 'https://t.me/KoreyaQonun'),
  ("Koreya sog'liq sug'urtasi bo'yicha ma'lumotlar", 'https://t.me/health_insurance_uz'),
  ("Yo'l harakati qonun-qoidalari va sug'urtasi haqida", 'https://t.me/koreya_mashina_sugurta'),
  ('Koreyada ishlash, intervyu, rezyume, networking', 'https://t.me/HaksengUz'),
  ("O'zbekiston yoshlar assotsiatsiyasi (Janubiy Korea)", 'https://t.me/wayu_korea'),
  ("O'zbekiston elchixonasi rasmiy boti", 'https://t.me/UzEmbassy_kr_bot'),
  ("Koreyaga endi kelmoqchi bo'lganlar uchun", 'https://t.me/Koreyaginam'),
  ('Koreyadagilar uchun kanal', 'https://t.me/salomkoreya'),
  ("Koreyadagi yurtdoshlarimiz bilishi kerak bo'ladigan nuktalar", 'https://t.me/seul_global_markazi'),
  ('F-3 vizaga topshirganlar guruhi', 'https://t.me/f3_vizaga'),
  ('Hammasi Koreya haqida', 'https://t.me/uzbeknur_korea'),
  ('Koreya vizalari, grantlar va yangiliklar', 'https://t.me/misterberd'),
  ('Yuridik yordam va tarjimonlik', 'https://t.me/ganiev_tarjimon'),
  ('Koreyada dam olish joylari', 'https://t.me/travelkoreabest'),
  ("Koreyada yo'l-yo'lakay taksi", 'https://t.me/korea_taxi'),
  ('Kitoblar buyurtma qilish', 'https://t.me/StarbooksKoreya'),
];

/// Who a community group is for.
enum GroupFor { everyone, women, ours }

/// The web page's "Telegram guruhlar", and the bot's own group, where it
/// asks people to suggest missing links.
const communityGroups = [
  ('Muslim Vegukin', 'https://t.me/MuslimVegukin', GroupFor.ours),
  ('Onajonlar guruhi', 'https://t.me/+cyn-FkSVNfA5ZDdl', GroupFor.women),
  ('Tangin UZ', 'https://t.me/TanginUz', GroupFor.everyone),
  ('Tangin UZ', 'https://t.me/+yJj3Pq5tm043MDY1', GroupFor.women),
];

/// Where to suggest a group that's missing.
const suggestGroupUrl = 'https://t.me/MuslimVegukin';
