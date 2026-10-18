import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/features/parcel/linkify.dart';
import 'package:muslim_vegukin/features/parcel/parcel_controller.dart';
import 'package:muslim_vegukin/features/parcel/parcel_models.dart';
import 'package:muslim_vegukin/features/parcel/parcel_screen.dart';
import 'package:muslim_vegukin/features/parcel/parcel_source.dart';

import 'support/fakes.dart';

/// Opens the parcel page from the home grid and lets the fake answers in.
Future<TestApp> openParcels(WidgetTester tester, {String language = 'uz', TestApp? app}) async {
  app ??= TestApp(language: language);
  await app.launch(tester);
  final tile = find.text(language == 'en' ? 'Parcels' : 'Pochta');
  await tester.scrollUntilVisible(tile, 200);
  // The grid's last row: clear of the screen's bottom edge first.
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await settle(tester);
  expect(find.byType(ParcelScreen), findsOneWidget);
  return app;
}

/// The placeholders breathe forever: pump through instead of settling.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('the API\'s answers', () {
    test('days, cities and posts', () {
      final day = ParcelDate.fromJson({'date_formatted': '25.10.2026', 'date_uzbek': '25-oktabr', 'count': 3})!;
      expect(day.date, DateTime(2026, 10, 25));
      expect(day.key, '25.10.2026');
      expect(day.count, 3);
      expect(ParcelDate.fromJson({'date_formatted': '2026-10-25'}), isNull);
      expect(ParcelCity.fromJson({'city': ' Ansan ', 'count': '2'})!.count, 2);
      expect(ParcelCity.fromJson({'city': ''}), isNull);

      final post = ParcelPost.fromJson({
        'message_text': 'Toshkent ga',
        'username': '@akmal',
        'telegram_id': 12345,
        'flight_time': '25.10.2026 14:30',
        'direction': 1,
      });
      expect(post.text, 'Toshkent ga');
      expect(post.username, 'akmal');
      expect(post.telegramId, '12345');
      expect(post.direction, ParcelDirection.korToUzb);
      final bare = ParcelPost.fromJson({'message_text': null, 'username': '', 'direction': null});
      expect(bare.text, '');
      expect(bare.username, isNull);
      expect(bare.direction, isNull);
    });

    test('the web page\'s endpoints, read as UTF-8', () async {
      final asked = <Uri>[];
      final client = MockClient((request) async {
        asked.add(request.url);
        final body = switch (request.url.path) {
          '/api/parcels/dates' => {
              'success': true,
              'dates': [
                {'date_formatted': '25.10.2026', 'count': 2},
                {'date_formatted': 'bad'},
              ],
            },
          '/api/parcels/by-city' => {
              'success': true,
              'posts': [
                {'message_text': 'Toshkent → Сеул 📦', 'username': 'a'},
              ],
            },
          _ => {'success': false, 'error': 'nope'},
        };
        // No charset in the headers: must still come out right.
        return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
      });
      await http.runWithClient(() async {
        const source = HttpParcelSource();
        final dates = await source.dates(ParcelDirection.korToUzb);
        expect(dates.single.key, '25.10.2026');
        final posts = await source.postsByCity('Ansan', ParcelCountry.kor, ParcelDirection.uzbToKor);
        expect(posts.single.text, 'Toshkent → Сеул 📦');
        await expectLater(source.cities(ParcelCountry.uzb, ParcelDirection.uzbToKor), throwsA(isA<ParcelException>()));
      }, () => client);
      expect(asked.first.toString(), 'https://vegukin-api.duckdns.org/api/parcels/dates?direction=1');
      expect(asked[1].queryParameters, {'city': 'Ansan', 'country': 'kor', 'direction': '0'});
    });
  });

  group('phones, Telegram names and links in a post', () {
    List<String> found(String text) =>
        [for (final p in linkify(text)) if (p.kind != PieceKind.text) '${p.kind.name} ${p.target}'];

    test('are found', () {
      expect(found('Tel: 010-1234-5678, yoki +998 (90) 123-45-67.'), [
        'phone tel:01012345678',
        'phone tel:+998901234567',
      ]);
      expect(found('Yozing @bobur_cargo ga'), ['telegram https://t.me/bobur_cargo']);
      expect(found('Kanal: t.me/vegukin_pochta. Sayt: https://example.uz/a?b=1)'), [
        'link https://t.me/vegukin_pochta',
        'link https://example.uz/a?b=1',
      ]);
    });

    test('prices, weights, dates and e-mails are not', () {
      expect(found('1 kg — 15 000 won, 25.10.2026 14:30 da uchaman, 2026 yil'), isEmpty);
      expect(found('pochta: akmal@gmail.com'), isEmpty);
    });

    test('the text comes back whole', () {
      const text = 'Salom! 010 1234 5678 ga qo‘ng‘iroq qiling, @akmal_k.';
      expect(linkify(text).map((p) => p.text).join(), text);
    });
  });

  group('the controller', () {
    test('loads the days and the first day\'s posts; remembers a swap', () async {
      final store = MemoryStore();
      final source = FakeParcels();
      final c = ParcelController(source: source, store: store);
      expect(c.direction, ParcelDirection.korToUzb, reason: 'from Korea home, until swapped');
      await c.start();
      expect(c.dates.data!.length, 2);
      expect(c.selected!.key, '18.10.2026');
      expect(c.posts.data!.length, 2);

      await c.select(c.dates.data![1]);
      expect(c.posts.data!.single.text, contains('Buxoro'));

      await c.swap();
      expect(store.read('parcel_direction'), '0');
      expect(c.country, ParcelCountry.uzb, reason: 'cities of the departure country first');
      expect(c.selected!.key, '25.10.2026');
      expect(ParcelController(source: source, store: store).direction, ParcelDirection.uzbToKor);
      c.dispose();
    });

    test('a failed load says so; a failed refresh keeps what was shown', () async {
      final source = FakeParcels()..fail = true;
      final c = ParcelController(source: source, store: MemoryStore());
      await c.start();
      expect(c.dates.failed, isTrue);

      source.fail = false;
      expect(await c.refresh(), isTrue);
      expect(c.posts.data!.length, 2);

      source.fail = true;
      expect(await c.refresh(), isFalse);
      expect(c.posts.data!.length, 2);
      expect(c.dates.data!.length, 2);
      c.dispose();
    });

    test('answers for the old direction are dropped', () async {
      final slow = _SlowParcels();
      final c = ParcelController(source: slow, store: MemoryStore());
      unawaited(c.start());
      unawaited(c.swap());
      // The new direction's answer comes first, then the old one.
      slow.answer(ParcelDirection.uzbToKor);
      await pumpEventQueue();
      slow.answer(ParcelDirection.korToUzb);
      await pumpEventQueue();
      expect(c.direction, ParcelDirection.uzbToKor);
      expect(c.dates.data!.single.key, '25.10.2026');
      c.dispose();
    });

    test('cities load when wanted, per country', () async {
      final source = FakeParcels();
      final c = ParcelController(source: source, store: MemoryStore());
      await c.start();
      expect(c.cities, isNull);
      c.setMode(ParcelMode.byCity);
      await pumpEventQueue();
      expect(c.cities!.data!.map((x) => x.name), ['Ansan', 'Seul']);
      await c.setCountry(ParcelCountry.uzb);
      expect(c.cities!.data!.single.name, 'Toshkent');
      expect(source.requests, contains('cities uzb 1'));
      c.dispose();
    });
  });

  group('the page', () {
    testWidgets('shows the first day\'s posts at once; Telegram and phone open outside', (tester) async {
      final app = await openParcels(tester);
      expect(find.text('Qayerdan'), findsOneWidget);
      expect(find.text('Koreya'), findsOneWidget);
      expect(find.text('O‘zbekiston'), findsOneWidget);
      expect(find.text('@akmal_kuryer'), findsOneWidget);
      expect(find.text('2 ta e’lon'), findsOneWidget);
      // No username: the web page's note, and a call button from the text.
      expect(find.text('Kuryer kontakti xabarda ko‘rsatilgan'), findsOneWidget);

      await tester.tap(find.text('Telegramda yozish'));
      expect(app.links.last, Uri.parse('https://t.me/akmal_kuryer'));
      await tester.tap(find.text('Qo‘ng‘iroq qilish'));
      expect(app.links.last, Uri.parse('tel:+998901234567'));
    });

    testWidgets('another day, and the swap, which is remembered', (tester) async {
      final app = await openParcels(tester);
      await tester.tap(find.text('21'));
      await settle(tester);
      expect(find.textContaining('Buxoroga'), findsOneWidget);

      await tester.tap(find.byTooltip('Yo‘nalishni almashtirish'));
      await settle(tester);
      expect(find.textContaining('Seulga'), findsOneWidget);
      expect(app.store.read('parcel_direction'), '0');
    });

    testWidgets('by city: the departure country\'s cities, then a city\'s posts', (tester) async {
      await openParcels(tester);
      await tester.tap(find.text('Shahar bo‘yicha'));
      await settle(tester);
      expect(find.text('Ansan'), findsOneWidget);
      await tester.tap(find.text('Ansan'));
      await settle(tester);
      expect(find.byType(ParcelCityScreen), findsOneWidget);
      expect(find.text('🇰🇷 Ansan'), findsOneWidget);
      expect(find.textContaining('Koreyadan O‘zbekistonga'), findsOneWidget);
      expect(find.text('@akmal_kuryer'), findsOneWidget);

      // The bar's back arrow (its tooltip is in Uzbek here).
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);
      await tester.tap(find.text('O‘zbekiston').last);
      await settle(tester);
      expect(find.text('Toshkent'), findsOneWidget);
    });

    testWidgets('offline: an error with a retry that works', (tester) async {
      final app = TestApp(language: 'en');
      app.parcels.fail = true;
      await openParcels(tester, language: 'en', app: app);
      expect(find.text('Couldn’t load. Check your internet and try again.'), findsOneWidget);
      app.parcels.fail = false;
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.text('@akmal_kuryer'), findsOneWidget);
      expect(find.text('2 posts'), findsOneWidget);
    });

    testWidgets('how it works, from the bar', (tester) async {
      await openParcels(tester, language: 'en');
      await tester.tap(find.byTooltip('How it works'));
      await settle(tester);
      expect(find.text('Read a post and contact the courier'), findsOneWidget);
    });
  });
}

/// Answers only when told to, per direction.
class _SlowParcels extends FakeParcels {
  final _waiting = <ParcelDirection, Completer<void>>{};

  void answer(ParcelDirection d) => _waiting.putIfAbsent(d, Completer.new).complete();

  @override
  Future<List<ParcelDate>> dates(ParcelDirection direction) async {
    await _waiting.putIfAbsent(direction, Completer.new).future;
    return super.dates(direction);
  }
}
