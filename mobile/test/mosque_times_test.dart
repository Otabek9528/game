import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/notifications/notifications_screen.dart';
import 'package:muslim_vegukin/features/places/mosque_times.dart';
import 'package:muslim_vegukin/features/places/place_detail.dart';
import 'package:muslim_vegukin/features/places/place_map.dart';
import 'package:muslim_vegukin/features/places/places_models.dart';

import 'support/fakes.dart';

/// A kind's list near the phone, then one place's page.
Future<TestApp> openPlace(WidgetTester tester, String name,
    {TestApp? app, String list = 'Mosques', String language = 'en', String nearMe = 'Search near me', bool tall = false,
    Size? screen, double textScale = 1}) async {
  app ??= TestApp(language: language);
  // Tall: the whole place page at once, so its order can be read.
  await app.launch(tester, screen: screen ?? (tall ? const Size(411, 3000) : const Size(411, 891)), textScale: textScale);
  await tester.scrollUntilVisible(find.text(list), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(list));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nearMe));
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text(name));
  expect(find.byType(PlaceDetailScreen), findsOneWidget);
  return app;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.runAsync(() => Scrollable.ensureVisible(tester.element(finder), alignment: 0.5));
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> signInWithGoogle(WidgetTester tester) async {
  await tester.tap(find.text('Continue with Google'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// The sheet's tiles, in order, and where each sits.
Finder tiles() => find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key! as ValueKey).value}'.startsWith('times-tile:'));

List<Offset> tilePlaces(WidgetTester tester) => [for (final e in tiles().evaluate()) tester.getTopLeft(find.byWidget(e.widget))];

/// In the sheet only: the page behind it has words of its own.
Finder inSheet(Finder finder) => find.descendant(of: find.byType(TimesSheet), matching: finder);

double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text).first).dy;

void main() {
  group('the model', () {
    test('a place page with times, and one from a server without them', () {
      final schedule = MosqueSchedule.fromJson({
        'timetable': {'fajr': '06:00', 'dhuhr': '13:00', 'asr': null, 'maghrib': 'soon', 'updatedAt': '2027-02-24', 'stale': true},
        'eid': {
          'fitr': {'sessions': ['07:00', '08:30'], 'updatedAt': '2027-02-20', 'stale': false},
          'adha': null,
        },
      })!;
      expect(schedule.daily, {'fajr': '06:00', 'dhuhr': '13:00'}, reason: 'a time not HH:MM is left out');
      expect((schedule.dailyUpdated, schedule.dailyStale), (DateTime(2027, 2, 24), true));
      expect(schedule.eids.keys, ['fitr']);
      expect(schedule.eids['fitr']!.sessions, ['07:00', '08:30']);
      expect(MosqueSchedule.fromJson({'timetable': null}), isNull, reason: 'no "eid": a server before prayer times');
      expect(MosqueSchedule.fromJson({'timetable': null, 'eid': {'fitr': null, 'adha': null}})!.hasDaily, isFalse);
    });

    test('only mosques have them', () {
      final restaurant = PlaceDetail.fromJson({
        'id': 101, 'name': 'Osh', 'buildingType': 'Oshxona', 'timetable': null, 'eid': {'fitr': null, 'adha': null},
      })!;
      expect(restaurant.schedule, isNull);
    });

    test('the next prayer, in Korea time; Juma in Peshin’s place on Fridays', () {
      const daily = {'fajr': '06:00', 'dhuhr': '13:00', 'asr': '16:15', 'maghrib': '18:25', 'isha': '20:00', 'jumuah': '13:30'};
      // Thursday 15:00 in Seoul is 06:00 UTC.
      expect(nextPrayer(daily, DateTime.utc(2027, 2, 25, 6)), 'asr');
      // Friday 10:00 in Seoul.
      expect(nextPrayer(daily, DateTime.utc(2027, 2, 26, 1)), 'jumuah');
      // Friday without a Juma time: Peshin as any day.
      expect(nextPrayer({...daily}..remove('jumuah'), DateTime.utc(2027, 2, 26, 1)), 'dhuhr');
      // After Xufton: the morning's first.
      expect(nextPrayer(daily, DateTime.utc(2027, 2, 25, 13)), 'fajr');
      expect(nextPrayer(const {}, DateTime.utc(2027, 2, 25, 13)), isNull);
    });
  });

  group('a mosque’s page', () {
    testWidgets('times after the way there and the phone; no map; each part with its date', (tester) async {
      await openPlace(tester, 'Ansan Markaziy Masjidi', tall: true);
      expect(find.byType(PlaceMap), findsNothing, reason: 'the times take the map’s place');
      for (final navigator in ['Naver', 'Kakao', 'Google']) {
        expect(find.text(navigator), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('Congregation times'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(top(tester, 'Contact'), lessThan(top(tester, 'Congregation times')), reason: 'phone and address first');
      for (final (name, time) in [('Fajr', '06:00'), ('Dhuhr', '13:00'), ('Asr', '16:15'), ('Isha', '20:00'), ('Jumu‘ah', '13:30')]) {
        expect(find.text(name), findsOneWidget);
        expect(find.text(time), findsWidgets);
      }
      expect(find.text('Maghrib'), findsNothing, reason: 'not given: not shown');
      expect(find.text('Last updated: 1 October 2026'), findsOneWidget);
      expect(find.text('next'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Eid al-Adha'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('EID PRAYER'), findsOneWidget);
      expect(find.text('Eid al-Fitr'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('Last updated: 18 March 2026'), findsOneWidget, reason: 'each Eid its own date');
      expect(find.text('not added'), findsOneWidget, reason: 'Eid al-Adha: shown all year, empty');
      expect(top(tester, 'Eid al-Adha'), lessThan(top(tester, 'About the place')), reason: 'before what it’s like');
    });

    testWidgets('a mosque with nothing yet: where the times will be, to add', (tester) async {
      await openPlace(tester, 'Siheung Masjidi');
      await tester.scrollUntilVisible(find.text('No times yet'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('not added'), findsNWidgets(2));
      expect(find.byTooltip('Add Eid times'), findsOneWidget);
    });

    testWidgets('other places keep their map and have no times', (tester) async {
      await openPlace(tester, 'Samarqand Osh Markazi', list: 'Restaurants');
      expect(find.byType(PlaceMap), findsOneWidget);
      expect(find.text('Congregation times'), findsNothing);
    });

    testWidgets('a server before prayer times: no section', (tester) async {
      final app = TestApp(language: 'en');
      app.places.noTimes = true;
      await openPlace(tester, 'Ansan Markaziy Masjidi', app: app, tall: true);
      await tester.pumpAndSettle();
      expect(find.text('Congregation times'), findsNothing);
      expect(find.text('About the place'), findsOneWidget);
    });

    testWidgets('in Uzbek', (tester) async {
      await openPlace(tester, 'Ansan Markaziy Masjidi', language: 'uz', list: 'Masjidlar', nearMe: 'O‘z atrofimdan izlash');
      await tester.scrollUntilVisible(find.text('Jamoat namozi'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Bomdod'), findsOneWidget);
      expect(find.text('Oxirgi yangilanish: 1 oktabr 2026'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Qurbon hayiti'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Ramazon hayiti'), findsOneWidget);
    });
  }, skip: false);

  group('setting times', () {
    testWidgets('signed in first; tiles never move; the empty one filled, Juma taken away, saved', (tester) async {
      final app = await openPlace(tester, 'Ansan Markaziy Masjidi');
      await tapVisible(tester, find.text('Edit'));
      expect(find.text('Sign in'), findsWidgets, reason: 'who changed it is kept');
      await signInWithGoogle(tester);
      expect(find.byType(TimesSheet), findsOneWidget);
      expect(find.text('Pick a prayer'), findsOneWidget);
      expect(find.text('Everyone sees it as soon as you save.'), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsNothing);
      expect(tiles(), findsNWidgets(6));
      expect(find.descendant(of: find.byType(TimesSheet), matching: find.text('—')), findsOneWidget, reason: 'Maghrib: not set');

      final where = tilePlaces(tester);
      final wheelAt = <double>[];
      for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Jumu‘ah']) {
        await tester.tap(find.descendant(of: find.byType(TimesSheet), matching: find.text(name)).first);
        await tester.pumpAndSettle();
        expect(find.byType(CupertinoPicker), findsNWidgets(2));
        wheelAt.add(tester.getTopLeft(find.byType(CupertinoPicker).first).dy);
      }
      expect(tilePlaces(tester), where, reason: 'picking each prayer in turn moves nothing');
      expect(wheelAt.toSet(), hasLength(1), reason: 'the wheel stays in one place');
      expect(find.descendant(of: find.byType(TimesSheet), matching: find.text('—')), findsNothing,
          reason: 'picking the empty one gave it a time');

      // Maghrib: a minute later on the wheel.
      await tester.tap(find.descendant(of: find.byType(TimesSheet), matching: find.text('Maghrib')).first);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(TimesSheet), matching: find.text('Maghrib')), findsNWidgets(2),
          reason: 'the tile and the wheel’s heading');
      await tester.timedDrag(find.byType(CupertinoPicker).last, const Offset(0, -40), const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(TimesSheet), matching: find.text('18:01')), findsOneWidget);

      // Juma taken away.
      await tester.tap(find.descendant(of: find.byType(TimesSheet), matching: find.text('Jumu‘ah')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Jumu‘ah'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoPicker), findsNothing);
      expect(find.descendant(of: find.byType(TimesSheet), matching: find.text('—')), findsOneWidget);
      expect(tilePlaces(tester), where);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(TimesSheet), findsNothing);
      final (id, body) = app.places.timeSaves.single;
      expect(id, 1);
      expect(body, {'maghrib': '18:01', 'jumuah': null}, reason: 'only what changed');
      expect(app.places.asked.where((a) => a.startsWith('saveTimes 1 Bearer')), hasLength(1));
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Jumu‘ah'), findsNothing);
      expect(find.text('Last updated: 17 October 2026'), findsOneWidget);
    });

    testWidgets('nothing changed: nothing sent', (tester) async {
      final app = await openPlace(tester, 'Ansan Markaziy Masjidi');
      await tapVisible(tester, find.text('Edit'));
      await signInWithGoogle(tester);
      await tester.tap(find.descendant(of: find.byType(TimesSheet), matching: find.text('Fajr')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(app.places.timeSaves, isEmpty);
      expect(find.byType(TimesSheet), findsNothing);
    });

    testWidgets('refused: said in the sheet, which stays', (tester) async {
      final app = await openPlace(tester, 'Ansan Markaziy Masjidi');
      app.places.failNext['saveTimes'] = 'too_many_edits';
      await tapVisible(tester, find.text('Edit'));
      await signInWithGoogle(tester);
      await tester.tap(find.descendant(of: find.byType(TimesSheet), matching: find.text('Maghrib')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Too many changes. Please try again later.'), findsOneWidget);
      expect(find.byType(TimesSheet), findsOneWidget);
    });

    testWidgets('the Eids: a prayer added to one, one taken from the other', (tester) async {
      final app = await openPlace(tester, 'Ansan Markaziy Masjidi');
      await tester.scrollUntilVisible(find.byTooltip('Edit Eid times'), 200, scrollable: find.byType(Scrollable).first);
      await tapVisible(tester, find.byTooltip('Edit Eid times'));
      await signInWithGoogle(tester);
      expect(find.text('Eid prayer'), findsOneWidget);
      expect(find.text('EID AL-FITR'), findsOneWidget);
      expect(find.text('EID AL-ADHA'), findsOneWidget);
      expect(inSheet(find.text('Add')), findsNWidgets(2), reason: 'room for more in both');

      await tester.tap(inSheet(find.text('Add')).last);
      await tester.pumpAndSettle();
      expect(find.text('Eid al-Adha, Prayer 1'), findsOneWidget, reason: 'the new one, picked');
      expect(find.byType(CupertinoPicker), findsNWidgets(2));

      await tester.tap(find.descendant(of: find.byType(TimesSheet), matching: find.text('08:30')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Eid al-Fitr, Prayer 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final (id, body) = app.places.timeSaves.single;
      expect(id, 1);
      expect(body, {'fitr': ['07:00'], 'adha': ['07:00']});
      await tester.scrollUntilVisible(find.text('Eid al-Adha'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('not added'), findsNothing);
    });

    testWidgets('the largest text: tiles and wheel fit, nothing overflows', (tester) async {
      await openPlace(tester, 'Ansan Markaziy Masjidi', textScale: 1.6);
      await tapVisible(tester, find.text('Edit'));
      await signInWithGoogle(tester);
      await tester.tap(inSheet(find.text('Dhuhr')).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final e in tiles().evaluate()) {
        final r = tester.getRect(find.byWidget(e.widget));
        expect(r.left >= 0 && r.right <= screen.width, isTrue, reason: 'no tile off the side');
      }
      expect(tester.getRect(find.byType(CupertinoPicker).last).right, lessThanOrEqualTo(screen.width));
    });

    testWidgets('three prayers: no more room', (tester) async {
      final app = TestApp(language: 'en');
      app.places.schedules[1] = MosqueSchedule(eids: {'fitr': EidTimes(sessions: const ['07:00', '08:00', '09:00'])});
      await openPlace(tester, 'Ansan Markaziy Masjidi', app: app);
      await tester.scrollUntilVisible(find.byTooltip('Edit Eid times'), 200, scrollable: find.byType(Scrollable).first);
      await tapVisible(tester, find.byTooltip('Edit Eid times'));
      await signInWithGoogle(tester);
      expect(inSheet(find.text('Add')), findsOneWidget, reason: 'only Eid al-Adha has room');
    });
  });

  group('notifications', () {
    Future<TestApp> openWithAWatch(WidgetTester tester, {bool? timesOn = true}) async {
      final app = TestApp(language: 'en');
      app.places.watches[1] = const PlaceWatch(count: 43, watching: true);
      app.places.timesOn = timesOn;
      await app.launch(tester);
      await tester.tap(find.text('Notifications').first);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      return app;
    }

    testWidgets('prayer time changes switched off on their own', (tester) async {
      final app = await openWithAWatch(tester);
      final switchFinder = find.widgetWithText(SwitchListTile, 'When prayer times change');
      await tester.scrollUntilVisible(switchFinder, 200, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(app.places.asked, contains('setTimesUpdates false'));
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
    });

    testWidgets('a server without that choice: no switch', (tester) async {
      await openWithAWatch(tester, timesOn: null);
      expect(find.text('When prayer times change'), findsNothing);
    });
  });
}
