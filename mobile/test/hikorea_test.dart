import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/core/app_language.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_calendar.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_models.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_screen.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_source.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_text.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_watches.dart';

import 'support/fakes.dart';

Future<TestApp> openHikorea(WidgetTester tester, {String language = 'en', TestApp? app}) async {
  app ??= TestApp(language: language);
  await app.launch(tester);
  await pushPage(tester, HikoreaScreen(services: app.services));
  await tester.pumpAndSettle();
  return app;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// An office's row, scrolled to: the list is long, and below the first cards.
Future<void> tapOffice(WidgetTester tester, String place) async {
  final row = find.descendant(of: find.byType(OfficeRow), matching: find.text(place));
  await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Finder inSheet(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

/// A day in the first (this) month's grid.
Finder dayCell(int day) => find.descendant(of: find.byType(GridView).first, matching: find.text('$day'));

void main() {
  group('names', () {
    String booth(String raw, [AppLanguage language = AppLanguage.en]) =>
        boothName(HkDesk(seq: 1, booth: {'en': raw, 'uz': raw}), language).name;

    test('a counter without the dates HiKorea keeps in its name', () {
      final ansan = boothName(
        const HkDesk(seq: 1, booth: {
          'en': "Ansan Center] Residence Control(location: Ansan Foreign Resident's Support Headquarters 1F)(2023.09.19.~, AFTER 09:36)",
        }),
        AppLanguage.en,
      );
      expect(ansan.name, "Ansan Center · Residence Control (location: Ansan Foreign Resident's Support Headquarters 1F)");
      expect(ansan.afternoon, isTrue);
      expect(booth('Others(2021.05.01 ~ )'), 'Others');
      expect(booth('Appointment for Residence Permit Application (April 16, 2024~)'), 'Appointment for Residence Permit Application');
      expect(booth('[General Civil Service Center]Others(2023.08.15.~, AFTER 09:36)'), 'General Civil Service Center · Others');
      expect(booth('Chet ellik rezidentlar nazorati(2024.10.05.~2026.7.31., AFTER 09:36)', AppLanguage.uz),
          'Chet ellik rezidentlar nazorati');
      expect(booth('Foreigner Residence Control(1F, All countries)(2023.10.14.~)'), 'Foreigner Residence Control (1F, All countries)');
    });

    test('an office, tidied', () {
      expect(officeName('GIMHAE BRANCH OFFICE'), 'Gimhae Branch Office');
      expect(officeName('Ulsan  Immigration Office'), 'Ulsan Immigration Office');
      expect(provincesInEnglish['경남'], 'Gyeongnam', reason: 'the server says Busan');
    });

    test('an office as its place, and whose branch it is', () {
      expect(officeParts('Ansan Immigration Office'), (place: 'Ansan', branch: false, of: null));
      expect(officeParts('GIMHAE BRANCH OFFICE'), (place: 'Gimhae', branch: true, of: null));
      expect(officeParts('Daejeon Immigration Office Cheonan Branch Office'), (place: 'Cheonan', branch: true, of: 'Daejeon'));
      expect(officeParts('Yangju Immigration office'), (place: 'Yangju', branch: false, of: null));
      expect(officeParts('Seoul Southern Immigration Office').place, 'Seoul Southern');
    });

    test('a desk in Russian falls back to English when it has no Russian', () {
      expect(inLanguage({'en': 'Others', 'ru': ' '}, 'ru'), 'Others');
    });
  });

  group('the calendar', () {
    final calendar = HkCalendar(
      deskSeq: 1,
      listed: const {'20261019': 5, '20261020': 40, '20261026': 10, '20261027': 20},
      schedule: const HkSchedule(first: '20261019', last: '20261130', holidays: {'20261103'}, weekdays: {0, 1, 2, 3, 4}),
    );

    test('days nobody has booked yet are open; weekends and holidays are not days', () {
      expect(calendar.tierOf('20261022').$1, HkTier.open);
      expect(calendar.tierOf('20261024').$1, HkTier.closed, reason: 'Saturday');
      expect(calendar.tierOf('20261103').$1, HkTier.closed, reason: 'holiday');
      expect(calendar.tierOf('20261201').$1, HkTier.later, reason: 'after the last: not open yet');
    });

    test('how full: against the busiest day of the same weekday', () {
      expect(calendar.tierOf('20261019'), (HkTier.some, 0.5));
      expect(calendar.tierOf('20261026').$1, HkTier.full);
      expect(calendar.tierOf('20261020').$1, HkTier.full);
      expect(calendar.tierOf('20261027'), (HkTier.some, 0.5));
    });

    test('the earliest day one can still get', () {
      expect(calendar.earliestOpen(DateTime(2026, 10, 17)), DateTime(2026, 10, 19));
      expect(calendar.earliestOpen(DateTime(2026, 10, 20)), DateTime(2026, 10, 21));
      expect(calendar.openDays(DateTime(2026, 10, 19), until: DateTime(2026, 10, 23)),
          [DateTime(2026, 10, 19), DateTime(2026, 10, 21), DateTime(2026, 10, 22), DateTime(2026, 10, 23)]);
    });

    test('with each day\'s capacity read: full is full, and half booked is filling up', () {
      final read = HkCalendar.fromJson({
        'desk_seq': 1,
        'dates': [
          {'visi_ymd': '20261019', 'taken': 5, 'capacity': 40},
          {'visi_ymd': '20261020', 'taken': 40},
          {'visi_ymd': '20261021', 'taken': 1},
        ],
        'day_capacity': {'20261020': 40, '20261021': 1},
        'schedule': {'bookable_min_ymd': '20261019', 'bookable_max_ymd': '20261023', 'active_weekdays': [0, 1, 2, 3, 4]},
        'last_polled_at': '2026-10-17T08:00:00Z',
        'desk_checked_at': '2026-10-17T07:00:00Z',
      });
      expect(read.tierOf('20261019'), (HkTier.open, 5 / 40), reason: 'an eighth booked');
      expect(read.tierOf('20261020').$1, HkTier.full);
      expect(read.tierOf('20261021').$1, HkTier.full, reason: 'its one place taken: not the busiest Wednesday guess');
      expect(read.tierOf('20261022').$1, HkTier.open);
      expect(read.checkedAt, DateTime.utc(2026, 10, 17, 7).toLocal(), reason: 'this counter\'s own read');
    });
  });

  group('a counter\'s capacity and HiKorea retiring one', () {
    test('measured against the counter\'s capacity: full is full, the busiest Monday need not be', () {
      final calendar = HkCalendar.fromJson({
        'desk_seq': 1,
        'dates': [
          {'visi_ymd': '20261019', 'taken': 3},
          {'visi_ymd': '20261026', 'taken': 36},
          {'visi_ymd': '20261020', 'taken': 30},
        ],
        'capacity': 36,
        'schedule': {'bookable_min_ymd': '20261019', 'bookable_max_ymd': '20261221', 'active_weekdays': [0, 1, 2, 3, 4]},
        'listing': 'ok',
      });
      expect(calendar.deskCapacity, 36);
      expect(calendar.tierOf('20261019').$1, HkTier.open, reason: '3 of 36');
      expect(calendar.tierOf('20261026').$1, HkTier.full);
      expect(calendar.tierOf('20261020'), (HkTier.some, 30 / 36));
      expect(calendar.dormant, isFalse);
    });

    test('a counter that lists nothing', () {
      final calendar = HkCalendar.fromJson({'desk_seq': 774, 'dates': [], 'schedule': null, 'listing': 'none',
          'listed_until': '20261016', 'capacity': 180});
      expect((calendar.dormant, calendar.listedUntil), (true, DateTime(2026, 10, 16)));
      expect(calendar.days, isEmpty);
    });
  });

  group('the server', () {
    test('offices sorted; watches carry the account; errors keep their code', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          '/api/hikorea/offices' => http.Response(
              jsonEncode({
                'offices': [
                  {'office_id': '2', 'name_en': 'Suwon Immigration Office', 'desks': [{'desk_seq': 5, 'booth': {'en': 'A'}}]},
                  {'office_id': '1', 'name_en': 'Ansan Immigration Office', 'desks': [{'desk_seq': 4}]},
                  {'office_id': '3', 'name_en': 'No desks', 'desks': []},
                ],
              }),
              200),
          '/api/hikorea/watches' when request.method == 'POST' =>
            http.Response(jsonEncode({'error': 'duplicate_watch', 'message': 'already'}), 409),
          _ => http.Response('{}', 404),
        };
      });
      final source = HttpHikoreaSource(client);
      final offices = await source.offices();
      expect(offices.map((o) => o.nameEn), ['Ansan Immigration Office', 'Suwon Immigration Office']);

      await expectLater(
        source.watch({'Authorization': 'Bearer t'}, desk: 5, start: '20261018', end: '20261031', lang: 'uz'),
        throwsA(isA<HkException>().having((e) => e.code, 'code', 'duplicate_watch')),
      );
      expect(requests.last.headers['Authorization'], 'Bearer t');
      expect(jsonDecode(requests.last.body), {'desk_seq': 5, 'start_ymd': '20261018', 'end_ymd': '20261031', 'lang': 'uz'});
    });
  });

  group('the page', () {
    testWidgets('native from the home screen; offices, searchable; offline: said so, and tried again', (tester) async {
      final app = TestApp(language: 'en')..hikorea.fail = true;
      await app.launch(tester);
      await tester.scrollUntilVisible(find.text('Immigration services'), 200);
      await tester.tap(find.text('Immigration services'));
      await tester.pumpAndSettle();
      expect(find.byType(HikoreaScreen), findsOneWidget);
      expect(find.text('Couldn’t load. Check your connection.'), findsOneWidget);

      app.hikorea.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Which office is yours?'), findsOneWidget, reason: 'where someone new starts');
      expect(find.text('Find your office'), findsOneWidget, reason: 'how it works');
      await tester.scrollUntilVisible(find.text('Gimhae'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Branch office · 1 counter'), findsOneWidget);
      expect(find.text('Immigration office · 2 counters'), findsOneWidget, reason: 'Ansan');

      await tester.enterText(find.byType(TextField), 'seoul');
      await tester.pumpAndSettle();
      expect(find.text('Seoul'), findsOneWidget);
      expect(find.text('Ansan'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No office matches'), findsOneWidget);
    });

    testWidgets('by address: the province, then the address in Korean; to the counters, tidied', (tester) async {
      final app = await openHikorea(tester);
      await tapVisible(tester, find.text('Find by address'));
      await tester.tap(find.text('Find my office'));
      await tester.pump();
      expect(find.text('Pick your province first'), findsOneWidget);

      await tester.tap(find.text('경기 · Gyeonggi'));
      await tester.enterText(find.byType(TextField), '경기도 안산시 단원구 원곡동 123');
      await tester.tap(find.text('Find my office'));
      await tester.pumpAndSettle();
      expect(app.hikorea.asked.last, '경기|경기도 안산시 단원구 원곡동 123');
      expect(find.text('Your office:'), findsOneWidget);

      await tester.tap(find.text('Ansan'));
      await tester.pumpAndSettle();
      expect(find.text('Which counter do you need?'), findsOneWidget);
      expect(find.text("Ansan Center · Residence Control (location: Ansan Foreign Resident's Support Headquarters 1F)"),
          findsOneWidget);
      expect(find.text('Opens at 09:36'), findsOneWidget);
      expect(find.text('Siheung Center · Residence Control (location: Siheung migrant welfare Center 2F)'), findsOneWidget);
    });

    testWidgets('a counter\'s calendar: when it was checked, the earliest day, a day checked live', (tester) async {
      final app = await openHikorea(tester);
      await tapOffice(tester, 'Seoul');
      expect(find.byType(HkCalendarScreen), findsOneWidget, reason: 'one counter: straight to it');
      expect(find.text('Checked 5 min ago'), findsOneWidget);
      expect(find.text('Monday, 19 October'), findsOneWidget);
      expect(find.text('28 free days up to 30 November'), findsOneWidget, reason: '31 weekdays, a holiday, 2 full');
      expect(find.text('October 2026'), findsOneWidget);
      expect(dayCell(5), findsNothing, reason: 'weeks gone by are left out');
      expect(dayCell(12), findsOneWidget, reason: 'this week, from its Monday');
      expect(find.widgetWithText(FilledButton, 'Book on HiKorea'), findsOneWidget, reason: 'free days: book them');
      expect(find.widgetWithText(OutlinedButton, 'Watch'), findsOneWidget);

      await tester.tap(find.text('Monday, 19 October'));
      await tester.pumpAndSettle();
      expect(app.hikorea.asked.last, 'day 201 20261019');
      expect(inSheet(find.text('6 slots open')), findsOneWidget);
      expect(inSheet(find.text('2 left')), findsOneWidget);
      expect(inSheet(find.text('Full')), findsOneWidget);
      expect(inSheet(find.text('Morning')), findsOneWidget);
      await tapVisible(tester, inSheet(find.text('Book on HiKorea')));
      expect(app.links.last, Uri.parse('https://www.hikorea.go.kr/'));
    });

    testWidgets('a full day offers a watch on it; HiKorea not answering: said so, and tried again', (tester) async {
      final app = await openHikorea(tester);
      await tapOffice(tester, 'Seoul');
      app.hikorea.dayError = 'session_expired';
      await tapVisible(tester, dayCell(20));
      expect(inSheet(find.textContaining('Our connection to HiKorea is being renewed')), findsOneWidget);
      app.hikorea.dayError = null;
      await tapVisible(tester, inSheet(find.text('Try again')));
      expect(inSheet(find.text('Fully booked')), findsOneWidget);

      await tapVisible(tester, inSheet(find.text('Notify me when a slot opens')));
      expect(inSheet(find.text('20 October 2026')), findsOneWidget, reason: 'just that day');
      expect(inSheet(find.text('1 day')), findsOneWidget);
    });

    testWidgets('a watch: set, a test notification, listed, and stopped', (tester) async {
      final app = await openHikorea(tester);
      await tapOffice(tester, 'Seoul');
      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('18 October – 31 October 2026')), findsOneWidget, reason: 'from tomorrow, 14 days');
      await tester.tap(inSheet(find.text('Next 30 days')));
      await tester.pumpAndSettle();
      expect(inSheet(find.text('30 days')), findsOneWidget);
      await tapVisible(tester, inSheet(find.text('Start watching')));

      final watch = app.hikorea.watchList.single;
      expect((watch.deskSeq, ymdOf(watch.start), ymdOf(watch.end)), (201, '20261018', '20261116'));
      expect(inSheet(find.text('You’re watching')), findsOneWidget);
      await tapVisible(tester, inSheet(find.text('Send a test notification')));
      expect(app.hikorea.tests, ['en']);
      expect(inSheet(find.text('Sent')), findsOneWidget);

      await tapVisible(tester, inSheet(find.text('See my watches')));
      expect(find.byType(HkWatchesScreen), findsOneWidget);
      expect(find.text('18 October – 16 November 2026 · 30 days'), findsOneWidget);
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Stop this watch?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Watch stopped'), findsOneWidget);
      expect(find.text('Past watches'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('the same watch twice: said so', (tester) async {
      final app = await openHikorea(tester);
      await tapOffice(tester, 'Seoul');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Watch'));
        await tester.pumpAndSettle();
        await tapVisible(tester, inSheet(find.text('Start watching')));
        if (i == 0) {
          await tester.tapAt(const Offset(20, 40));
          await tester.pumpAndSettle();
        }
      }
      expect(app.hikorea.watchList, hasLength(1));
      expect(inSheet(find.text('You’re already watching these days')), findsOneWidget);
    });

    testWidgets('watches and the counter seen last, on the first page, with how they stand', (tester) async {
      final app = await openHikorea(tester);
      await tapOffice(tester, 'Ansan');
      await tapVisible(tester, find.textContaining('Siheung Center'));
      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();
      await tapVisible(tester, inSheet(find.text('Start watching')));
      await tester.tapAt(const Offset(20, 40));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Your watches'), findsOneWidget);
      expect(find.text('Last viewed'), findsOneWidget);
      expect(find.textContaining('Siheung Center'), findsNWidgets(2), reason: 'the watch, and the counter seen last');
      expect(find.text('8 free days in your dates'), findsOneWidget, reason: '18–31 October: weekdays, but 20 and 26');
      expect(find.text('Earliest free day: Monday, 19 October'), findsOneWidget);
      expect(find.text('Which office is yours?'), findsNothing, reason: 'not new any more');
      expect(find.text('Not sure which office?'), findsOneWidget);
      expect(app.hikorea.watchList.single.deskSeq, 102);
    });

    testWidgets('a counter HiKorea retired: said so, the way to the others, no watch', (tester) async {
      final app = TestApp(language: 'en')..hikorea.dormantDesks.add(101);
      await openHikorea(tester, app: app);
      await tapOffice(tester, 'Ansan');
      expect(find.text('No days on HiKorea'), findsOneWidget, reason: 'the counters say which');
      expect(find.text('Earliest free day: Monday, 19 October'), findsOneWidget);
      await tapVisible(tester, find.textContaining('Ansan Center'));
      expect(find.text('HiKorea shows no days at this counter'), findsOneWidget);
      expect(find.textContaining('Since 16 October HiKorea has listed no days here'), findsOneWidget);
      expect(find.text('October 2026'), findsNothing, reason: 'no calendar of closed days');
      expect(find.text('Notify me when a slot opens'), findsNothing);
      expect(find.text('Watch'), findsNothing);

      await tester.tap(find.text('This office’s other counters'));
      await tester.pumpAndSettle();
      expect(find.text('Which counter do you need?'), findsOneWidget);
      await tapVisible(tester, find.textContaining('Siheung Center'));
      expect(find.text('Monday, 19 October'), findsOneWidget, reason: 'the other counter: a calendar');
    });

    testWidgets('three months at least', (tester) async {
      await openHikorea(tester);
      await tapOffice(tester, 'Seoul');
      await tester.scrollUntilVisible(find.text('December 2026'), 300,
          scrollable: find.descendant(of: find.byType(HkCalendarScreen), matching: find.byType(Scrollable)).first);
      expect(find.text('December 2026'), findsOneWidget);
    });

    testWidgets('in Uzbek', (tester) async {
      await openHikorea(tester, language: 'uz');
      expect(find.text('Immigratsiya xizmatlari'), findsOneWidget);
      expect(find.text('Sizning ofisingiz qaysi?'), findsOneWidget);
      await tapOffice(tester, 'Seoul');
      expect(find.text('Chet ellik rezidentlar nazorati (1-qavat, Barcha mamlakatlar)'), findsOneWidget);
      expect(find.text('Eng yaqin bo‘sh kun'), findsOneWidget);
      expect(find.text('Dushanba, 19-oktabr'), findsOneWidget);
    });
  });
}
