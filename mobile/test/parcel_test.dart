import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/features/parcel/linkify.dart';
import 'package:muslim_vegukin/features/parcel/parcel_controller.dart';
import 'package:muslim_vegukin/features/parcel/parcel_models.dart';
import 'package:muslim_vegukin/features/parcel/parcel_pages.dart';
import 'package:muslim_vegukin/features/parcel/parcel_saved.dart';
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
        'message_text': 'Toshkent\u00a0ga',
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
      final source = HttpParcelSource(client);
      final dates = await source.dates(ParcelDirection.korToUzb);
      expect(dates.single.key, '25.10.2026');
      final posts = await source.postsByCity('Ansan', ParcelCountry.kor, ParcelDirection.uzbToKor);
      expect(posts.single.text, 'Toshkent → Сеул 📦');
      await expectLater(source.cities(ParcelCountry.uzb, ParcelDirection.uzbToKor), throwsA(isA<ParcelException>()));
      expect(asked.first.toString(), 'https://vegukin-api.duckdns.org/api/parcels/dates?direction=1');
      expect(asked[1].queryParameters, {'city': 'Ansan', 'country': 'kor', 'direction': '0'});
    });

    test('a dropped connection is tried once more', () async {
      var calls = 0;
      final client = MockClient((request) async {
        if (++calls == 1) throw const SocketException('connection reset');
        return http.Response(jsonEncode({'success': true, 'dates': <Object>[]}), 200);
      });
      expect(await HttpParcelSource(client).dates(ParcelDirection.korToUzb), isEmpty);
      expect(calls, 2);
    });

    test('posts keep their id from one load to the next', () {
      const a = ParcelPost(text: 'Toshkentga', username: 'akmal', flightTime: '18.10.2026');
      final b = ParcelPost.fromJson(a.toJson());
      expect(b.id, a.id);
      expect(const ParcelPost(text: 'Toshkentga!', username: 'akmal').id, isNot(a.id));
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
    DateTime noon() => DateTime(2026, 10, 18, 12);

    test('opens on the first coming day; loads days as they are wanted; remembers a swap', () async {
      final store = MemoryStore();
      final source = FakeParcels();
      final c = ParcelController(source: source, store: store, clock: noon);
      expect(c.direction, ParcelDirection.korToUzb, reason: 'from Korea home, until swapped');
      await c.start();
      expect(c.feed.map((d) => d.key), ['18.10.2026', '21.10.2026']);
      expect(c.day('18.10.2026').loading, isTrue, reason: 'not wanted yet');
      c.want('18.10.2026');
      await pumpEventQueue();
      expect(c.day('18.10.2026').data!.length, 2);

      await c.swap();
      expect(store.read('parcel_direction'), '0');
      expect(c.country, ParcelCountry.uzb, reason: 'cities of the departure country first');
      expect(c.feed.single.key, '25.10.2026');
      expect(ParcelController(source: source, store: store).direction, ParcelDirection.uzbToKor);
      c.dispose();
    });

    test('days already past are left out of the list, and can be picked', () async {
      final c = ParcelController(source: FakeParcels(), store: MemoryStore(), clock: () => DateTime(2026, 10, 19, 9));
      await c.start();
      expect(c.isPast(c.dates.data!.first), isTrue);
      expect(c.feed.single.key, '21.10.2026');
      c.pick(c.dates.data!.first);
      expect(c.feed.length, 2);
      c.dispose();
    });

    test('two days load at a time', () async {
      final slow = _SlowPosts();
      final c = ParcelController(source: slow, store: MemoryStore(), clock: noon);
      await c.start();
      for (final key in ['18.10.2026', '21.10.2026', '25.10.2026']) {
        c.want(key);
      }
      await pumpEventQueue();
      expect(slow.asked, ['18.10.2026', '21.10.2026']);
      slow.answerAll();
      await pumpEventQueue();
      expect(slow.asked, ['18.10.2026', '21.10.2026', '25.10.2026']);
      c.dispose();
    });

    test('a failed load says so; a failed refresh keeps what was shown, marked offline', () async {
      final source = FakeParcels()..fail = true;
      final c = ParcelController(source: source, store: MemoryStore(), clock: noon);
      await c.start();
      expect(c.dates.failed, isTrue);

      source.fail = false;
      expect(await c.refresh(), isTrue);
      c.want('18.10.2026');
      await pumpEventQueue();
      expect(c.day('18.10.2026').data!.length, 2);

      source.fail = true;
      expect(await c.refresh(), isFalse);
      await pumpEventQueue();
      expect(c.offline, isTrue);
      expect(c.dates.data!.length, 2);
      expect(c.day('18.10.2026').data!.length, 2);
      c.dispose();
    });

    test('opens with what was loaded last time, even with no connection', () async {
      final store = MemoryStore();
      final first = ParcelController(source: FakeParcels(), store: store, clock: noon);
      await first.start();
      first.want('18.10.2026');
      await pumpEventQueue();
      first.dispose(); // writes the cache

      final offline = FakeParcels()..fail = true;
      final c = ParcelController(source: offline, store: store, clock: noon);
      final started = c.start();
      // At once, before any answer.
      expect(c.dates.data!.length, 2);
      expect(c.day('18.10.2026').data!.first.username, 'akmal_kuryer');
      await started;
      expect(c.offline, isTrue);
      expect(c.dates.data!.length, 2);
      c.dispose();
    });

    test('answers for the old direction are dropped', () async {
      final slow = _SlowParcels();
      final c = ParcelController(source: slow, store: MemoryStore(), clock: noon);
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
      final c = ParcelController(source: source, store: MemoryStore(), clock: noon);
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

    test('saved posts stay on the phone; undo puts one back where it was', () async {
      final store = MemoryStore();
      final saved = SavedParcels(store);
      final posts = FakeParcels.posts['18.10.2026']!;
      await saved.save(posts[0], ParcelDirection.korToUzb);
      await saved.save(posts[1], ParcelDirection.uzbToKor);
      expect(saved.items.map((s) => s.post.id), [posts[1].id, posts[0].id], reason: 'newest first');

      final again = SavedParcels(store);
      expect(again.contains(posts[0]), isTrue);
      expect(again.items.last.direction, ParcelDirection.korToUzb);

      final item = again.items.last;
      final at = await again.remove(posts[0]);
      expect(again.contains(posts[0]), isFalse);
      await again.restore(item, at);
      expect(again.items.last.post.id, posts[0].id);
    });

    test('the warm-up on app start runs only for a page used before, and not lately', () async {
      final source = FakeParcels();
      final store = MemoryStore();
      await warmParcels(source, store);
      expect(source.requests, isEmpty, reason: 'never opened');

      final old = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      store.values['parcel_cache'] = jsonEncode({
        'dates': {
          '1': {'at': old, 'items': <Object>[]},
        },
      });
      await warmParcels(source, store);
      expect(source.requests.first, 'dates 1');
      source.requests.clear();
      await warmParcels(source, store);
      expect(source.requests, isEmpty, reason: 'just fetched');
    });
  });

  group('the page', () {
    testWidgets('the first day\'s posts at once; the notice first, then Telegram with a message ready', (tester) async {
      final app = await openParcels(tester);
      expect(find.text('Qayerdan'), findsOneWidget);
      expect(find.text('Koreya'), findsOneWidget);
      expect(find.text('Ehtiyot bo‘ling'), findsOneWidget);
      expect(find.text('@akmal_kuryer'), findsOneWidget);
      // No username: the web page's note, and a call button from the text.
      expect(find.text('Kuryer kontakti xabarda ko‘rsatilgan'), findsOneWidget);

      await tester.tap(find.text('Telegramda yozish'));
      await settle(tester);
      expect(app.links, isEmpty, reason: 'the notice comes first');
      await tester.tap(find.text('Tushundim').last);
      await settle(tester);
      final telegram = app.links.single.toString();
      expect(telegram, startsWith('https://t.me/akmal_kuryer?text='));
      // Spaces as %20, never "+": Android would show the plus signs.
      expect(telegram, isNot(contains('+')));
      expect(
        Uri.decodeComponent(telegram.split('?text=').last),
        'Assalomu alaykum! Koreyadan O‘zbekistonga reysingiz (18.10.2026 14:30) bo‘yicha pochta haqida yozyapman.',
      );
      expect(app.store.read('parcel_notice'), '1');

      // Understood once: straight through from now on.
      await tester.tap(find.text('Qo‘ng‘iroq qilish'));
      await settle(tester);
      expect(app.links.last, Uri.parse('tel:+998901234567'));
      // The notice folds to one line.
      expect(find.text('E’lonlar Telegram guruhlaridan. Biz kuryerlar bilan bog‘liq emasmiz.'), findsOneWidget);
    });

    testWidgets('the days follow one another; a tap on a day goes there', (tester) async {
      await openParcels(tester);
      await tester.tap(find.text('Tushundim'));
      await settle(tester);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await settle(tester);
      expect(find.textContaining('Buxoroga'), findsOneWidget, reason: 'the next day, in the same list');

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
      await settle(tester);
      await tester.tap(find.text('21'));
      await settle(tester);
      expect(find.textContaining('Buxoroga'), findsOneWidget);
    });

    testWidgets('the swap, which is remembered', (tester) async {
      final app = await openParcels(tester);
      await tester.tap(find.byTooltip('Yo‘nalishni almashtirish'));
      await settle(tester);
      expect(find.textContaining('Seulga'), findsOneWidget);
      expect(app.store.read('parcel_direction'), '0');
    });

    testWidgets('search finds posts across the days', (tester) async {
      await openParcels(tester);
      await tester.tap(find.byTooltip('Qidirish'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'buxoro');
      await settle(tester);
      expect(find.textContaining('Buxoroga'), findsOneWidget);
      expect(find.text('@akmal_kuryer'), findsNothing);

      await tester.enterText(find.byType(TextField), 'nothing like it');
      await settle(tester);
      expect(find.text('Hech narsa topilmadi'), findsOneWidget);
    });

    testWidgets('a post saved, found among the saved, removed and put back', (tester) async {
      final app = await openParcels(tester);
      await tester.tap(find.byTooltip('Saqlash').first);
      await settle(tester);
      expect(app.store.read('parcel_saved'), contains('akmal_kuryer'));

      await tester.tap(find.byTooltip('Saqlangan e’lonlar'));
      await settle(tester);
      expect(find.byType(ParcelSavedScreen), findsOneWidget);
      expect(find.text('@akmal_kuryer'), findsOneWidget);

      await tester.tap(find.byTooltip('Saqlanganlardan olib tashlash'));
      await settle(tester);
      expect(find.text('@akmal_kuryer'), findsNothing);
      await tester.tap(find.text('Bekor qilish'));
      await settle(tester);
      expect(find.text('@akmal_kuryer'), findsOneWidget);
    });

    testWidgets('a post shared: route, flight, contact and text', (tester) async {
      final app = await openParcels(tester);
      await tester.tap(find.byTooltip('Ulashish').first);
      expect(app.shared.single, contains('Koreyadan O‘zbekistonga'));
      expect(app.shared.single, contains('@akmal_kuryer'));
      expect(app.shared.single, contains('15 000 won'));
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

    testWidgets('offline the first time: an error with a retry that works', (tester) async {
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

    testWidgets('offline later: last time\'s posts, with a note', (tester) async {
      final app = TestApp(language: 'en');
      await openParcels(tester, language: 'en', app: app);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);
      app.parcels.fail = true;
      await tester.tap(find.text('Parcels'));
      await settle(tester);
      expect(find.text('@akmal_kuryer'), findsOneWidget);
      expect(find.text('No connection. Showing the posts loaded last time.'), findsOneWidget);
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

/// Posts answer only when told to; records which days were asked for.
class _SlowPosts extends FakeParcels {
  final asked = <String>[];
  final _waiting = <Completer<void>>[];

  void answerAll() {
    for (final c in _waiting) {
      c.complete();
    }
    _waiting.clear();
  }

  @override
  Future<List<ParcelPost>> postsByDate(String date, ParcelDirection direction) async {
    asked.add(date);
    final c = Completer<void>();
    _waiting.add(c);
    await c.future;
    return super.postsByDate(date, direction);
  }
}
