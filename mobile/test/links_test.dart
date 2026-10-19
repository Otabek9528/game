import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/links/links_controller.dart';
import 'package:muslim_vegukin/features/links/links_data.dart';
import 'package:muslim_vegukin/features/links/links_screen.dart';
import 'package:muslim_vegukin/features/prayer/prayer_models.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';

import 'support/fakes.dart';

/// The web page's script, as in this repository.
final webScript = File('../pages/links/links.js').readAsStringSync();

Future<TestApp> openLinks(WidgetTester tester, {String language = 'uz', TestApp? app}) async {
  app ??= TestApp(language: language);
  await app.launch(tester);
  if (language != 'uz') {
    // Offered on the home screen in Uzbek only.
    await pushPage(tester, LinksScreen(services: app.services));
    await tester.pumpAndSettle();
    return app;
  }
  final tile = find.text('Foydali linklar');
  await tester.scrollUntilVisible(tile, 200);
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
  expect(find.byType(LinksScreen), findsOneWidget);
  return app;
}

SavedLocation at(double lat, double lon, [String? city]) =>
    SavedLocation(lat: lat, lon: lon, city: city, timestamp: DateTime(2026));

void main() {
  group('the lists', () {
    test('the app\'s copy is the web page\'s, and every link has what the app adds', () {
      final web = parseLinksScript(webScript)!;
      expect(web.jobs, bundledJobs);
      expect(web.life, bundledLife);
      for (final (name, url) in web.jobs) {
        expect(jobCities.containsKey(url), isTrue, reason: '$name has no city');
        for (final key in jobCities[url]!) {
          expect(linkCities.containsKey(key), isTrue, reason: '$name: no city "$key"');
        }
      }
      for (final (name, url) in web.life) {
        expect(lifeInfo.containsKey(url), isTrue, reason: '$name has no topic');
      }
    });

    test('the script\'s lists are read however they are quoted; anything but Telegram is left out', () {
      final lists = parseLinksScript('''
        let arbaytLinks = [
          { name: 'Yangi \\'guruh\\'', url: 'https://t.me/yangi' },
          { name: "Sayt", url: "https://example.com" },
        ];
        var koreaLifeLinks = [{ name: "Kanal", url: "https://t.me/kanal" }];
      ''')!;
      expect(lists.jobs, [("Yangi 'guruh'", 'https://t.me/yangi')]);
      expect(lists.life, [('Kanal', 'https://t.me/kanal')]);
      expect(parseLinksScript('nothing here'), isNull);
    });
  });

  group('search', () {
    final c = LinksController(store: MemoryStore(), script: () async => null);
    List<String> names(String q) => [for (final l in c.search(q)) l.name];

    test('a city however it is spelt', () {
      for (final q in ['cheonan', 'chonan', '천안', 'Чонан']) {
        expect(names(q), containsAll(["Chonan o'zbeklar", "Chonan Asan o'zbeklar ishi va faoliyati"]), reason: q);
      }
      expect(names('pusan'), ["Busan - ish e'lonlari", "Busan ish e'lon"]);
      expect(names('kimhae'), ['Kimhe ish 김해 일']);
    });

    test('apostrophes or none, several words, other languages', () {
      expect(names("e'lon"), names('elon'));
      expect(names('seongnam elon'), ["Seongnam ish e'lon"]);
      expect(names('insurance').length, 2);
      expect(names('посольства'), ["O'zbekiston elchixonasi rasmiy boti"]);
      expect(names('tangin').length, 2);
    });
  });

  group('distance', () {
    UsefulLink job(String url) => LinksController(store: MemoryStore(), script: () async => null)
        .jobs
        .firstWhere((l) => l.url == url);

    test('from the user\'s place to the group\'s nearest city', () {
      final ansan = at(37.32, 126.83);
      expect(LinksController.distanceKm(job('https://t.me/Ansanish'), ansan)!, lessThan(2));
      final both = job('https://t.me/ChonanAsan_ish');
      expect(LinksController.nearestCity(both, at(36.79, 127.0))!.name, 'Asan');
      expect(LinksController.distanceKm(job('https://t.me/korea_ish_bor'), ansan), isNull, reason: 'all of Korea');
    });

    test('outside Korea there is no "nearest"', () {
      final tashkent = at(41.3, 69.24);
      expect(LinksController.inKorea(tashkent), isFalse);
      expect(LinksController.distanceKm(job('https://t.me/Ansanish'), tashkent), isNull);
    });
  });

  group('staying up to date', () {
    test('a group added on the web page shows up; the next day\'s visit fetches again', () async {
      var calls = 0;
      var now = DateTime(2026, 10, 18, 9);
      final script = webScript.replaceFirst(
        'const arbaytLinks = [',
        'const arbaytLinks = [\n  { name: "Suwon ish", url: "https://t.me/suwon_ish" },',
      );
      final store = MemoryStore();
      Future<String?> source() async {
        calls++;
        return script;
      }

      final c = LinksController(store: store, script: source, clock: () => now);
      expect(c.jobs.length, 36);
      await c.start();
      expect(c.jobs.length, 37);
      final added = c.jobs.first;
      expect(added.name, 'Suwon ish');
      expect(added.region, LinkRegion.other, reason: 'the app doesn\'t know where it is yet');

      // From the phone, without asking again the same day.
      final again = LinksController(store: store, script: source, clock: () => now);
      expect(again.jobs.length, 37);
      await again.start();
      expect(calls, 1);
      now = now.add(const Duration(days: 1, minutes: 1));
      await again.start();
      expect(calls, 2);
    });

    test('a page that can\'t be read changes nothing', () async {
      final c = LinksController(store: MemoryStore(), script: () async => '<html>404</html>');
      await c.start();
      expect(c.jobs.length, 36);
    });

    test('favourites and the chosen tab are remembered', () async {
      final store = MemoryStore();
      final c = LinksController(store: store, script: () async => null);
      await c.toggleFavorite(c.life.first);
      c.setTab(LinksTab.life);
      c.setOrder(JobOrder.regions);
      final again = LinksController(store: store, script: () async => null);
      expect(again.favorites.single.url, c.life.first.url);
      expect(again.tab, LinksTab.life);
      expect(again.order, JobOrder.regions);
    });
  });

  group('the page', () {
    testWidgets('job groups nearest first, with distances; a tap opens Telegram', (tester) async {
      final app = await openLinks(tester);
      expect(find.text('Butun Koreya'), findsWidgets);
      expect(find.text('Yaqin atrofda'), findsOneWidget);
      expect(find.text('Ansanda ish'), findsOneWidget);
      expect(find.text('<1 km'), findsWidgets);
      await tester.tap(find.text('Ansanda ish'));
      expect(app.links.last, Uri.parse('https://t.me/Ansanish'));
    });

    testWidgets('by region; Korea life by topic, in the app\'s language', (tester) async {
      await openLinks(tester, language: 'en');
      await tester.tap(find.text('Regions'));
      await tester.pumpAndSettle();
      expect(find.text('Seoul & Gyeonggi'), findsOneWidget);
      await tester.tap(find.text('Life in Korea'));
      await tester.pumpAndSettle();
      expect(find.text('Official'), findsOneWidget);
      expect(find.text('Official bot of the Embassy of Uzbekistan'), findsOneWidget);
    });

    testWidgets('search across everything; nothing found offers to suggest a group', (tester) async {
      final app = await openLinks(tester);
      await tester.enterText(find.byType(TextField), 'chonan');
      await tester.pumpAndSettle();
      expect(find.text('2 ta natija'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Hech narsa topilmadi'), findsOneWidget);
      await tester.tap(find.text('Guruhingiz ro‘yxatda yo‘qmi?'));
      expect(app.links.last, Uri.parse('https://t.me/MuslimVegukin'));
    });

    testWidgets('a favourite goes on top; a long press copies or shares', (tester) async {
      final app = await openLinks(tester);
      await tester.tap(find.byTooltip('Sevimlilarga qo‘shish').first);
      await tester.pumpAndSettle();
      expect(find.text('Sevimlilar'), findsOneWidget);
      expect(app.store.read('links_favorites'), isNotNull);

      await tester.longPress(find.text('Ansanda ish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ulashish'));
      await tester.pumpAndSettle();
      expect(app.shared.last, 'Ansanda ish\nhttps://t.me/Ansanish');
    });

    testWidgets('no place yet: one tap to find it', (tester) async {
      final app = TestApp(language: 'en', location: FakeLocation(access: LocationAccess.denied, afterRequest: LocationAccess.denied));
      await openLinks(tester, language: 'en', app: app);
      expect(find.text('Use your location to see the nearest groups first'), findsOneWidget);
      expect(find.text('Seoul & Gyeonggi'), findsOneWidget, reason: 'by region meanwhile');
    });
  });
}
