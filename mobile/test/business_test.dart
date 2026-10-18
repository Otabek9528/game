import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/features/business/business_card.dart';
import 'package:muslim_vegukin/features/business/business_data.dart';
import 'package:muslim_vegukin/features/business/business_library.dart';
import 'package:muslim_vegukin/features/business/business_logo.dart';
import 'package:muslim_vegukin/features/business/business_models.dart';
import 'package:muslim_vegukin/features/business/business_parts.dart';
import 'package:muslim_vegukin/features/business/business_screen.dart';
import 'package:muslim_vegukin/features/business/business_source.dart';
import 'package:muslim_vegukin/features/business/business_text.dart';

import 'support/fakes.dart';

/// What the app put on the clipboard.
final copied = <String>[];

Future<TestApp> openDirectory(WidgetTester tester, {String language = 'uz', TestApp? app}) async {
  copied.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  app ??= TestApp(language: language);
  await app.launch(tester);
  final band = switch (language) { 'ru' => 'Бизнес-каталог', 'en' => 'Business Directory', _ => 'Biznes Katalogi' };
  await tester.tap(find.text(band));
  await tester.pumpAndSettle();
  expect(find.byType(BusinessScreen), findsOneWidget);
  return app;
}

/// Android's back.
Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// From the directory, into a kind and one of its businesses.
Future<void> openCard(WidgetTester tester, String category, String business) async {
  await tapVisible(tester, find.text(category));
  await tapVisible(tester, find.text(business));
  expect(find.byType(BusinessCard), findsOneWidget);
}

/// Scrolls the card down to [finder].
Future<void> scrollCard(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(finder, find.byType(ListView), const Offset(0, -200));
  await tester.pumpAndSettle();
}

Finder medals(int place) => find.byWidgetPredicate((w) => w is Medal && w.place == place);

void main() {
  group('the rules', () {
    test('the two likely ways lead; a channel follows, the app stores stay together', () {
      final baraka = splitLinks(FakeBusinesses.baraka.links);
      expect([for (final l in baraka.primary) l.kind], ['phone', 'telegram']);
      expect([for (final l in baraka.rest) l.kind], ['tgchannel', 'instagram']);

      final channelOnly = splitLinks(const [BizLink('tgchannel', 'https://t.me/news')]);
      expect(channelOnly.primary.single.kind, 'tgchannel', reason: 'with nothing else, the channel is the way');

      final app = splitLinks(const [
        BizLink('appstore', 'https://apps.apple.com/app/id1'),
        BizLink('website', 'https://example.com'),
        BizLink('playstore', 'https://play.google.com/store/apps/details?id=x'),
      ]);
      expect([for (final l in app.primary) l.kind], ['website']);
      expect([for (final l in app.rest) l.kind], ['playstore', 'appstore']);
    });

    test('what a link shows: a handle, a host, nothing where the address names nothing', () {
      String show(String kind, String value) => BizLink(kind, value).display(privateGroup: 'private');
      expect(show('telegram', 'https://t.me/baraka_halal'), '@baraka_halal');
      expect(show('tgchannel', 'https://t.me/+AbCdEf123'), 'private');
      expect(show('tgchannel', 'https://t.me/joinchat/AbC'), 'private');
      expect(show('instagram', 'https://www.instagram.com/baraka.mart/'), '@baraka.mart');
      expect(show('website', 'https://www.example.co.kr/menu'), 'example.co.kr');
      expect(show('youtube', 'https://youtube.com/@barakamart'), '@barakamart');
      expect(show('youtube', 'https://youtube.com/channel/UC3xAbCdEf'), '');
      expect(show('facebook', 'https://facebook.com/profile.php?id=1000'), '');
      expect(show('facebook', 'https://facebook.com/barakamart'), '@barakamart');
      expect(show('playstore', 'https://play.google.com/store/apps/details?id=x'), '');
      expect(show('phone', '010-1234-5678'), '010-1234-5678');
    });

    test('a tap goes to the dialler, or to a web address, and nowhere else', () {
      expect(const BizLink('phone', '010-1234 5678').target, Uri.parse('tel:01012345678'));
      expect(const BizLink('phone', '+82 10-1234-5678').target, Uri.parse('tel:+821012345678'));
      expect(const BizLink('website', 'https://example.com').target, Uri.parse('https://example.com'));
      expect(const BizLink('website', 'javascript:alert(1)').target, isNull);
      expect(BizLink.fromJson({'kind': 'fax', 'value': '02-123-4567'}), isNull, reason: 'a kind the page doesn’t know');
    });

    test('medals for the top three by likes; a tie shares its place; no likes, no medal', () {
      List<int?> ranks(List<int> likes) =>
          ranksOf([for (final (i, n) in likes.indexed) Business(id: '$i', name: 'B$i', likes: n)]);
      expect(ranks([12, 12, 5, 3, 0]), [1, 1, 3, null, null]);
      expect(ranks([7, 4, 4, 4]), [1, 2, 2, 2]);
      expect(ranks([5, 0, 0]), [1, null, null]);
      expect(ranks([0, 0]), [null, null]);
    });

    test('the directory’s own order; empty kinds sink', () {
      final sorted = [
        FakeBusinesses.translation,
        const BizCategory(id: '9', slug: 'other', name: 'Boshqa', count: 1),
        FakeBusinesses.post,
        FakeBusinesses.halal,
      ]..sort(byCategoryOrder);
      expect([for (final c in sorted) c.slug], ['halal-market', 'pochta', 'other', 'tarjima']);
    });

    test('a description: blocks, labels, the address with its maps, numbers and links', () {
      final blocks = parseDescription(FakeBusinesses.baraka.description!);
      expect(blocks, hasLength(2));
      expect(blocks.first.single.label, isNull);
      final [address, hours, order, insta] = blocks.last;
      expect(address.label, 'Manzil: ');
      expect(address.address, 'Seoul, Itaewon-ro 12');
      expect(hours.label, 'Ish vaqti: ');
      expect(hours.pieces.where((p) => p.kind == PieceKind.phone), isEmpty, reason: 'hours are not a number');
      expect(order.pieces.single.kind, PieceKind.phone);
      expect(order.pieces.single.value, '01098765432');
      expect(insta.pieces.single.kind, PieceKind.link);

      final korean = parseDescription('서울특별시 용산구 이태원로 12 에 있습니다').single.single;
      expect(korean.address, '서울특별시 용산구 이태원로 12');
      expect(parseDescription('2015-2024 yillar').single.single.pieces.single.kind, PieceKind.text);
    });

    test('a row’s preview: the lines run on, links and emptied labels dropped', () {
      expect(FakeBusinesses.baraka.preview,
          'Eng yangi halol go‘sht har kuni · Manzil: Seoul, Itaewon-ro 12 · Ish vaqti: 09:00–21:00 · Buyurtma: 010-9876-5432');
    });

    test('a pasted link is named for where it goes', () {
      expect(hostOf('https://naver.me/abc').map, MapHost.naver);
      expect(hostOf('https://map.kakao.com/?q=x').map, MapHost.kakao);
      expect(hostOf('https://open.kakao.com/o/x').kind, 'kakao');
      expect(hostOf('https://www.shop.co.kr/a').brand, 'shop.co.kr');
      expect(naverMap('Seoul, Itaewon-ro 12').toString(), 'https://map.naver.com/p/search/Seoul%2C%20Itaewon-ro%2012');
    });
  });

  group('logos', () {
    Uint8List pixels(int n, int Function(int x, int y) argb) {
      final data = Uint8List(n * n * 4);
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          final c = argb(x, y);
          final i = (y * n + x) * 4;
          data
            ..[i] = (c >> 16) & 0xFF
            ..[i + 1] = (c >> 8) & 0xFF
            ..[i + 2] = c & 0xFF
            ..[i + 3] = (c >> 24) & 0xFF;
        }
      }
      return data;
    }

    bool centre(int x, int y) => x > 8 && x < 24 && y > 8 && y < 24;

    test('clear round the edge: plain, on white', () {
      final facts = readPixels(pixels(32, (x, y) => centre(x, y) ? 0xFF2E7D32 : 0x00000000), 32)!;
      expect(facts.kind, LogoKind.plain);
    });

    test('one colour to the edge: the frame takes that colour', () {
      final facts = readPixels(pixels(32, (x, y) => centre(x, y) ? 0xFFFFFFFF : 0xFF0B3D91), 32)!;
      expect(facts.kind, LogoKind.plate);
      expect(facts.plate, const Color(0xFF0B3D91));
    });

    test('busy to the edge: a photo, filling the frame; empty: nothing to read', () {
      final facts = readPixels(pixels(32, (x, y) => 0xFF000000 | ((x * 37 + y * 91) % 256) << 16 | ((x * y * 13) % 256)), 32)!;
      expect(facts.kind, LogoKind.photo);
      expect(HSLColor.fromColor(facts.tint).saturation, lessThanOrEqualTo(0.401));
      expect(readPixels(pixels(32, (_, _) => 0), 32), isNull);
    });

    testWidgets('a real image is read from its file', (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawCircle(const Offset(64, 64), 30, Paint()..color = const Color(0xFFC62828));
        final image = await recorder.endRecording().toImage(128, 128);
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        final facts = await readLogo(png);
        expect(facts!.kind, LogoKind.plain);
        expect(HSLColor.fromColor(facts.tint).hue, closeTo(0, 8), reason: 'red, calmed');
      });
    });

    test('initials, and a colour of the name’s own', () {
      expect(initials('Baraka Halal Mart'), 'BH');
      expect(initials('  asia   cargo '), 'AC');
      expect(nameTint('Asia Cargo'), nameTint('Asia Cargo'));
    });
  });

  group('kept on the phone', () {
    test('saved businesses: newest first, with their contacts, kept up to date', () {
      final store = MemoryStore();
      final library = BusinessLibrary(store);
      expect(library.toggleSave(FakeBusinesses.ansan), isTrue);
      expect(library.toggleSave(FakeBusinesses.baraka), isTrue);
      expect([for (final b in library.saved) b.id], ['11', '12']);

      final again = BusinessLibrary(store);
      expect(again.saved.first.links, hasLength(4));
      again.refresh(const Business(id: '12', name: 'Ansan Halol Go‘sht (yangi)'));
      expect(BusinessLibrary(store).saved.last.name, 'Ansan Halol Go‘sht (yangi)');
      expect(again.toggleSave(FakeBusinesses.baraka), isFalse);
      expect([for (final b in BusinessLibrary(store).saved) b.id], ['12']);
    });

    test('the directory last seen', () {
      final store = MemoryStore();
      BusinessLibrary(store).directory = const BizDirectory(
        categories: [FakeBusinesses.translation, FakeBusinesses.halal],
        listingFee: 15000,
      );
      final directory = BusinessLibrary(store).directory!;
      expect([for (final c in directory.categories) c.id], ['1', '3']);
      expect(directory.listingFee, 15000);
      expect(directory.total, 3);
    });
  });

  group('the server', () {
    HttpBusinessSource source(Map<String, Object> Function(http.Request) answer, [List<http.Request>? seen]) =>
        HttpBusinessSource(MockClient((request) async {
          seen?.add(request);
          return http.Response.bytes(utf8.encode(jsonEncode(answer(request))), 200);
        }));

    test('the directory, in its order, with the fee', () async {
      final directory = await source((_) => {
            'success': true,
            'listingFee': 12000,
            'categories': [
              {'id': 3, 'slug': 'tarjima', 'name': 'Tarjima', 'icon': '📄', 'count': 0},
              {'id': 4, 'slug': 'pochta', 'name': 'Pochta', 'icon': '📦', 'count': 2},
              {'id': 1, 'slug': 'halal-market', 'name': 'Halol market', 'count': 3},
              {'slug': 'broken'},
            ],
          }).directory();
      expect([for (final c in directory.categories) c.slug], ['halal-market', 'pochta', 'tarjima']);
      expect(directory.listingFee, 12000);
    });

    test('a kind, a business, a search', () async {
      final seen = <http.Request>[];
      final api = source((r) => switch (r.url.path) {
            '/api/business/list' => {
                'success': true,
                'businesses': [
                  {'id': 11, 'name': 'Baraka', 'likes': 4, 'logo': '/uploads/b.png'},
                ],
              },
            '/api/business/feed' => {
                'success': true,
                'groups': [
                  {
                    'category': {'id': 4, 'slug': 'pochta', 'name': 'Pochta', 'count': 2},
                    'total': 1,
                    'businesses': [{'id': 41, 'name': 'Asia Cargo'}],
                  },
                  {
                    'category': {'id': 1, 'slug': 'halal-market', 'name': 'Halol market', 'count': 3},
                    'total': 2,
                    'businesses': [{'id': 11, 'name': 'Baraka'}, {'id': 12, 'name': 'Ansan'}],
                  },
                ],
              },
            _ => {
                'success': true,
                'business': {
                  'id': 11,
                  'name': 'Baraka',
                  'taps': 77,
                  'categoryName': 'Halol market',
                  'links': [
                    {'kind': 'phone', 'value': '010-1'},
                    {'kind': 'fax', 'value': 'x'},
                    {'kind': 'website', 'value': ' '},
                  ],
                },
              },
          }, seen);

      final list = await api.category('1');
      expect(seen.last.url.queryParameters, {'category_id': '1'});
      expect(list.single.logoUrl.toString(), 'https://vegukin-api.duckdns.org/uploads/b.png');

      final groups = await api.search('a b');
      expect(seen.last.url.queryParameters, {'q': 'a b'});
      expect([for (final g in groups) g.category.name], ['Halol market', 'Pochta']);
      expect(groups.first.businesses.first.categoryName, 'Halol market');

      final b = await api.business('11');
      expect(seen.last.url.path, '/api/business/11');
      expect(b.views, 77, reason: 'the server has called them taps');
      expect(b.links.single.kind, 'phone', reason: 'unknown kinds and empty values dropped');
    });

    test('a failure is a BizException; an opening is counted', () async {
      final seen = <http.Request>[];
      final api = source((_) => {'success': false}, seen);
      await expectLater(api.directory(), throwsA(isA<BizException>()));
      api.countView('11');
      await Future<void>.delayed(Duration.zero);
      expect(seen.last.method, 'POST');
      expect(seen.last.url.path, '/api/business/11/tap');

      final down = HttpBusinessSource(MockClient((_) async => http.Response('', 502)));
      await expectLater(down.business('1'), throwsA(isA<BizException>()));
    });
  });

  group('the directory', () {
    testWidgets('every kind as a tile, with what it covers; empty ones last; kept for next time', (tester) async {
      final app = await openDirectory(tester);
      expect(app.activity.actions, ['business']);
      expect(find.text('Biznes katalogi'), findsOneWidget);
      expect(find.text('6 ta biznes'), findsOneWidget, reason: 'the hero’s count');
      expect(find.text('Halol go‘sht, ziravorlar, oziq-ovqat'), findsOneWidget);
      expect(find.text('3 ta biznes'), findsOneWidget);
      expect(find.text('Hozircha bo‘sh'), findsOneWidget);
      final halal = tester.getTopLeft(find.text('Halol market'));
      final bakery = tester.getTopLeft(find.text('Pishiriqlar'));
      final empty = tester.getTopLeft(find.text('Tarjima va apostil'));
      expect(halal.dy, bakery.dy, reason: 'two to a row');
      expect(empty.dy, greaterThan(halal.dy));
      expect(find.text('Bizneslar haqidagi ma’lumotlar o‘zbek tilida.'), findsNothing, reason: 'already in Uzbek');
      expect(app.store.read('business_directory'), contains('Halol market'));
    });

    testWidgets('offline with nothing kept: an error and a retry; with it kept, it opens at once', (tester) async {
      final app = TestApp(language: 'uz');
      app.businesses.fail = true;
      await openDirectory(tester, app: app);
      expect(find.text('Yuklab bo‘lmadi'), findsOneWidget);
      app.businesses.fail = false;
      await tapVisible(tester, find.text('Qayta urinish'));
      expect(find.text('Halol market'), findsOneWidget);

      await back(tester);
      app.businesses.fail = true;
      await tester.tap(find.text('Biznes Katalogi'));
      await tester.pumpAndSettle();
      expect(find.text('Halol market'), findsOneWidget, reason: 'the directory last seen');
      expect(find.text('Yuklab bo‘lmadi'), findsNothing);
    });

    testWidgets('in English and Russian: the page translated, a note that listings are in Uzbek', (tester) async {
      await openDirectory(tester, language: 'en');
      expect(find.text('Business directory'), findsOneWidget);
      expect(find.text('3 businesses'), findsOneWidget);
      expect(find.text('Business listings are written in Uzbek.'), findsOneWidget);
      expect(find.text('Empty for now'), findsOneWidget);
    });

    testWidgets('Russian plurals', (tester) async {
      await openDirectory(tester, language: 'ru');
      expect(find.text('3 бизнеса'), findsOneWidget);
      expect(find.text('6 бизнесов'), findsOneWidget);
      expect(find.text('1 бизнес'), findsOneWidget);
    });

    testWidgets('for owners: how to get listed, the fee, and the admin', (tester) async {
      final app = await openDirectory(tester);
      await tapVisible(tester, find.text('Biznes egasimisiz?'));
      expect(find.text('Katalogga qo‘shilish'), findsOneWidget);
      expect(find.textContaining('15,000 won'), findsOneWidget);
      await tapVisible(tester, find.text('Admin bilan bog‘lanish'));
      expect(app.links.last, bizAdmin);
    });
  });

  group('a kind', () {
    testWidgets('most liked first; medals, shared on a tie; the order explained', (tester) async {
      await openDirectory(tester);
      await tapVisible(tester, find.text('Halol market'));
      expect(find.byType(BizCategoryScreen), findsOneWidget);
      expect(find.text('Mijozlar eng ko‘p yoqtirgan bizneslar yuqorida'), findsOneWidget);
      expect(medals(1), findsNWidgets(2));
      expect(medals(3), findsNothing, reason: 'Samarqand has no likes');
      final rows = [for (final n in ['Baraka Halal Mart', 'Ansan Halol Go‘sht', 'Samarqand Market']) tester.getTopLeft(find.text(n)).dy];
      expect(rows, orderedEquals([...rows]..sort()));
      await tester.dragUntilVisible(find.text('Biznes egasimisiz?'), find.byType(ListView), const Offset(0, -200));
      expect(find.text('Biznesingizni katalogga qo‘shing — mijozlar sizni shu yerdan topadi.'), findsOneWidget);
    });

    testWidgets('the title switches to another kind', (tester) async {
      await openDirectory(tester);
      await tapVisible(tester, find.text('Halol market'));
      await tapVisible(tester, find.text('Halol market'));
      expect(find.text('Yo‘nalishlar'), findsOneWidget);
      await tapVisible(tester, find.text('Pochta').last);
      expect(find.text('Asia Cargo'), findsOneWidget);
      expect(find.text('Baraka Halal Mart'), findsNothing);
      await back(tester);
      expect(find.byType(BusinessScreen), findsOneWidget, reason: 'one kind replaces another; back is the directory');
    });

    testWidgets('an empty kind says so, and asks for its first business', (tester) async {
      await openDirectory(tester);
      await tapVisible(tester, find.text('Tarjima va apostil'));
      expect(find.text('Bu yo‘nalishda hali biznes yo‘q'), findsOneWidget);
      expect(find.text('Bu yo‘nalishga birinchi bo‘lib qo‘shiling.'), findsOneWidget);
    });
  });

  group('the card', () {
    testWidgets('who it is; the two likely ways as buttons; the rest listed; counted once', (tester) async {
      final app = await openDirectory(tester);
      await openCard(tester, 'Halol market', 'Baraka Halal Mart');
      expect(app.businesses.opened, ['11']);
      expect(app.businesses.counted, ['11']);
      expect(find.text('HALOL MARKET'), findsOneWidget);
      expect(find.text('340 marta ko‘rilgan'), findsOneWidget);
      expect(find.text('12 kishiga yoqdi'), findsOneWidget);
      expect(find.text('010-1234-5678'), findsOneWidget);
      expect(find.text('Qo‘ng‘iroq qilish'), findsOneWidget);
      expect(find.text('@baraka_halal'), findsOneWidget);
      expect(find.text('Telegramda yozish'), findsOneWidget);
      expect(find.text('Telegram kanal / guruh'), findsOneWidget);
      expect(find.text('Yopiq guruh'), findsOneWidget, reason: 'an invite link names nothing');

      await tester.tap(find.text('010-1234-5678'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('tel:01012345678'));

      await tester.longPress(find.text('010-1234-5678'));
      await tester.pumpAndSettle();
      expect(copied.last, '010-1234-5678');
      expect(find.text('Raqam nusxalandi'), findsOneWidget);

      await tester.tap(find.text('@baraka_halal'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://t.me/baraka_halal'));
    });

    testWidgets('the description: its address to copy or find on a map, its number to call', (tester) async {
      final app = await openDirectory(tester);
      await openCard(tester, 'Halol market', 'Baraka Halal Mart');
      await scrollCard(tester, find.text('Naver Map'));
      await tester.tap(find.text('Naver Map'));
      await tester.pumpAndSettle();
      expect(app.links.last.host, 'map.naver.com');
      expect(app.links.last.path, contains('Itaewon-ro'));

      await tester.tap(find.text('Kakao Map'));
      await tester.pumpAndSettle();
      expect(app.links.last.host, 'map.kakao.com');

      await tester.tap(find.text('Nusxalash'));
      await tester.pumpAndSettle();
      expect(copied.last, 'Seoul, Itaewon-ro 12');

      await tester.tapOnText(find.textRange.ofSubstring('010-9876-5432'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('tel:01098765432'));
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Baraka Halal Mart')), findsOneWidget,
          reason: 'scrolled past the name, the bar takes it');
    });

    testWidgets('saved: on top of the directory, and opens with no connection', (tester) async {
      final app = await openDirectory(tester);
      await openCard(tester, 'Halol market', 'Baraka Halal Mart');
      await tester.tap(find.byTooltip('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Saqlandi — aloqa ma’lumotlari internetsiz ham ochiladi'), findsOneWidget);
      expect(find.byTooltip('Saqlanganlardan olib tashlash'), findsOneWidget);

      await back(tester);
      await back(tester);
      expect(find.text('Saqlanganlar'), findsOneWidget);
      expect(find.text('Baraka Halal Mart'), findsOneWidget);

      app.businesses.fail = true;
      await tester.tap(find.text('Baraka Halal Mart'));
      await tester.pumpAndSettle();
      expect(find.text('010-1234-5678'), findsOneWidget, reason: 'the saved contacts');
      expect(find.text('Ma’lumotni yuklab bo‘lmadi.'), findsNothing);
    });

    testWidgets('shared as its name, kind and every contact', (tester) async {
      final app = await openDirectory(tester);
      await openCard(tester, 'Halol market', 'Baraka Halal Mart');
      await tester.tap(find.byTooltip('Ulashish'));
      await tester.pumpAndSettle();
      expect(app.shared.single.split('\n'), [
        'Baraka Halal Mart',
        'Halol market',
        '',
        'Telefon: 010-1234-5678',
        'Telegram: https://t.me/baraka_halal',
        'Telegram kanal / guruh: https://t.me/+AbCdEf123',
        'Instagram: https://instagram.com/baraka.mart',
        '',
        'Muslim Vegukin biznes katalogidan',
      ]);
    });

    testWidgets('nothing filled in: says so once, and offers the admin', (tester) async {
      final app = await openDirectory(tester);
      await openCard(tester, 'Halol market', 'Samarqand Market');
      expect(find.text('Bu biznes hali to‘liq ma’lumot kiritmagan.'), findsOneWidget);
      expect(find.text('Aloqa ma’lumotlari ko‘rsatilmagan.'), findsNothing);
      await tester.tap(find.text('Admin orqali so‘rash'));
      await tester.pumpAndSettle();
      expect(app.links.last, bizAdmin);
    });

    testWidgets('offline and not saved: a retry', (tester) async {
      final app = await openDirectory(tester);
      await tapVisible(tester, find.text('Halol market'));
      app.businesses.fail = true;
      await tapVisible(tester, find.text('Ansan Halol Go‘sht'));
      expect(find.text('Ma’lumotni yuklab bo‘lmadi.'), findsOneWidget);
      expect(find.byTooltip('Saqlash'), findsOneWidget);
      app.businesses.fail = false;
      await tester.tap(find.text('Qayta urinish'));
      await tester.pumpAndSettle();
      expect(find.text('KakaoTalkda yozish'), findsOneWidget);
      expect(app.businesses.counted, ['12']);
    });
  });

  group('search', () {
    testWidgets('as one types; grouped by kind; each group opens its kind', (tester) async {
      final app = await openDirectory(tester);
      await tester.tap(find.text('Biznes yoki xizmatni qidiring'));
      await tester.pumpAndSettle();
      expect(find.byType(BizSearchScreen), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Pochta'), findsOneWidget, reason: 'the kinds to start from');
      expect(find.widgetWithText(ActionChip, 'Tarjima va apostil'), findsNothing, reason: 'nothing in it');

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'ar');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(app.businesses.searches, ['ar'], reason: 'one search for what was typed in one go');
      expect(find.text('3 ta topildi'), findsOneWidget);
      expect(find.text('Halol market · 2'), findsOneWidget);
      expect(find.text('Pochta · 1'), findsOneWidget);
      expect(find.text('Asia Cargo'), findsOneWidget);

      await tester.tap(find.text('Barchasi').last);
      await tester.pumpAndSettle();
      expect(find.byType(BizCategoryScreen), findsOneWidget);
      expect(find.text('Express Pochta'), findsOneWidget);
    });

    testWidgets('nothing found says what was looked for', (tester) async {
      await openDirectory(tester);
      await tester.tap(find.byTooltip('Qidiruv'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Hech narsa topilmadi'), findsOneWidget);
      expect(find.textContaining('“zzz” bo‘yicha biznes topilmadi'), findsOneWidget);
    });
  });
}
