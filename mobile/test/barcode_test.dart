import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/features/barcode/barcode_camera.dart';
import 'package:muslim_vegukin/features/barcode/barcode_models.dart';
import 'package:muslim_vegukin/features/barcode/barcode_screen.dart';
import 'package:muslim_vegukin/features/barcode/barcode_source.dart';
import 'package:muslim_vegukin/features/barcode/barcode_store_screen.dart';

import 'support/fakes.dart';

/// What the app put on the clipboard.
final copied = <String>[];

Future<TestApp> openScanner(WidgetTester tester, {String language = 'uz', TestApp? app}) async {
  copied.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  app ??= TestApp(language: language);
  await app.launch(tester);
  final tile = language == 'uz' ? 'Mahsulot tarkibini tekshirish' : 'Ingredient check';
  await tester.scrollUntilVisible(find.text(tile), 200);
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text(tile));
  await tester.pumpAndSettle();
  expect(find.byType(BarcodeScreen), findsOneWidget);
  return app;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// [finder], only in the open sheet (the page under it may show the same).
Finder inSheet(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

/// Scrolls the open sheet to [finder], then taps it.
Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    inSheet(finder),
    150,
    scrollable: inSheet(find.byType(Scrollable)).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(inSheet(finder));
  await tester.pumpAndSettle();
}

const cola = '8801043014809';
const sausage = '8801234567893';
const cookie = '8809999999997';
const unknown = '8805555555553';

void main() {
  group('scanning', () {
    testWidgets('a code read: the verdict over the paused camera; closing scans the next', (tester) async {
      final app = await openScanner(tester);
      final camera = app.cameras.single;
      expect(camera.status, CameraStatus.running);
      expect(app.activity.actions, ['barcode']);

      camera.read(cola);
      await tester.pumpAndSettle();
      expect(find.text('Joiz'), findsOneWidget);
      expect(find.text('Tarkibida ta’qiqlangan ingredientlar topilmadi'), findsOneWidget);
      expect(inSheet(find.text('롯데 칠성사이다 500ml')), findsOneWidget);
      expect(inSheet(find.text('CU')), findsOneWidget, reason: 'also at');
      expect(camera.status, CameraStatus.paused);
      expect(app.activity.actions.last, 'scanner_found:$cola');

      // The camera is held while the sheet is up.
      camera.read(sausage);
      await tester.pump();
      expect(app.barcodes.lookedUp, [cola]);

      expect(inSheet(find.textContaining('GS25', findRichText: true)), findsOneWidget, reason: 'found in');
      await tapInSheet(tester, find.text('Tarkibi'));
      expect(find.text('정제수, 설탕, 이산화탄소, 구연산, 향료'), findsOneWidget);

      await tapVisible(tester, find.text('Keyingisini skanerlash'));
      expect(camera.status, CameraStatus.running);
      expect(find.text('So‘nggi tekshiruvlar'), findsOneWidget);
      expect(find.textContaining(cola), findsOneWidget);
    });

    testWidgets('prohibited and doubtful: what is in it, and why', (tester) async {
      final app = await openScanner(tester, language: 'en');
      app.cameras.single.read(sausage);
      await tester.pumpAndSettle();
      expect(find.text('Prohibited'), findsOneWidget);
      expect(find.text('present'), findsNWidgets(2), reason: 'pork and other meat');
      expect(find.text('General database · Store not specified'), findsOneWidget);
      await tapVisible(tester, find.text('Scan the next one'));

      app.cameras.single.read(cookie);
      await tester.pumpAndSettle();
      expect(find.text('Doubtful'), findsOneWidget);
      expect(find.textContaining('may be of plant or animal FAT origin'), findsOneWidget);
      await tester.scrollUntilVisible(
        inSheet(find.text('Made on equipment that also makes prohibited products.')),
        150,
        scrollable: inSheet(find.byType(Scrollable)).first,
      );
      await tapInSheet(tester, find.text('Can I eat doubtful products?'));
      expect(app.links.last.host, 'telegra.ph');
    });

    testWidgets('the photo opens full screen, filling it', (tester) async {
      final app = await openScanner(tester, language: 'en');
      app.cameras.single.read(cola);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.zoom_out_map_rounded));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(InteractiveViewer)), const Size(411, 891));
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(inSheet(find.text('Permissible')), findsOneWidget);
    });

    testWidgets('not in the database: said so, as on the web page', (tester) async {
      final app = await openScanner(tester);
      final camera = app.cameras.single;
      camera.read(unknown);
      await tester.pumpAndSettle();
      expect(inSheet(find.text('Mahsulot topilmadi')), findsOneWidget);
      expect(find.text('Ushbu mahsulot hozircha bazada yo‘q. Tez orada qo‘shilishi mumkin.'), findsOneWidget);
      expect(app.activity.actions.last, 'scanner_not_found:$unknown');
      await tester.tap(find.text('Keyingisini skanerlash'));
      await tester.pumpAndSettle();
      expect(camera.status, CameraStatus.running);
      expect(app.links, isEmpty);
    });

    testWidgets('no connection is not "not found"; a code seen before answers from the phone', (tester) async {
      final app = await openScanner(tester);
      final camera = app.cameras.single;
      app.barcodes.fail = true;
      camera.read(cola);
      await tester.pumpAndSettle();
      expect(find.text('Internet yo‘q'), findsOneWidget);
      expect(find.text('Mahsulot topilmadi'), findsNothing);

      app.barcodes.fail = false;
      await tapVisible(tester, find.text('Qayta urinish'));
      expect(find.text('Joiz'), findsOneWidget);
      await tapVisible(tester, find.text('Keyingisini skanerlash'));

      app.barcodes.fail = true;
      camera.read(cola);
      await tester.pumpAndSettle();
      expect(find.text('Joiz'), findsOneWidget);
      expect(find.text('Avval saqlangan natija · internet yo‘q'), findsOneWidget);
    });

    testWidgets('a code typed by hand, checked like the web page', (tester) async {
      final app = await openScanner(tester);
      final camera = app.cameras.single;
      await tester.tap(find.text('Kodni kiritish'));
      await tester.pumpAndSettle();
      expect(camera.status, CameraStatus.paused);

      await tester.enterText(find.byType(TextField), '8801043014800');
      await tester.tap(find.text('Qidirish'));
      await tester.pumpAndSettle();
      expect(find.text('Shtrix-kod noto‘g‘ri. Raqamlarni tekshiring.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12345');
      await tester.tap(find.text('Qidirish'));
      await tester.pumpAndSettle();
      expect(find.text('Shtrix-kod 8 dan 14 tagacha raqamdan iborat bo‘lishi kerak.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), sausage);
      await tester.tap(find.text('Qidirish'));
      await tester.pumpAndSettle();
      expect(find.text('Joiz emas'), findsOneWidget);
      expect(app.activity.actions.last, 'scanner_found:$sausage');
    });

    testWidgets('from the history: opened again, not counted as a scan', (tester) async {
      final app = await openScanner(tester);
      app.cameras.single.read(cookie);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Keyingisini skanerlash'));
      final counted = app.activity.actions.length;

      await tapVisible(tester, find.text('초코 쿠키'));
      expect(find.text('Shubhali'), findsWidgets);
      expect(app.activity.actions, hasLength(counted));
      expect(app.barcodes.lookedUp, [cookie, cookie]);
    });

    testWidgets('the camera stops when scrolled away, and comes back', (tester) async {
      final app = await openScanner(tester);
      final camera = app.cameras.single;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(camera.status, CameraStatus.paused);
      await tester.tap(find.byTooltip('Skanerlash'));
      await tester.pumpAndSettle();
      expect(camera.status, CameraStatus.running);
    });

    testWidgets('camera refused: the settings, and typing still works without asking again', (tester) async {
      final app = TestApp(language: 'uz')..cameraDenied = true;
      await openScanner(tester, app: app);
      final camera = app.cameras.single;
      expect(find.text('Kameraga ruxsat berilmagan'), findsOneWidget);
      await tester.tap(find.text('Sozlamalarni ochish'));
      expect(app.permissions.settingsOpened, 1);

      await tester.tap(find.text('Kodni kiritish'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), cola);
      await tester.tap(find.text('Qidirish'));
      await tester.pumpAndSettle();
      expect(find.text('Joiz'), findsOneWidget);
      await tapVisible(tester, find.text('Keyingisini skanerlash'));
      expect(camera.starts, 1, reason: 'no new permission request after each check');
    });
  });

  group('stores', () {
    testWidgets('a store: by verdict, by category, more as it scrolls', (tester) async {
      final app = await openScanner(tester);
      final camera = app.cameras.single;
      expect(find.text('Yaqinda'), findsOneWidget, reason: 'Daiso: 3 products');
      await tapVisible(tester, find.text('GS25'));
      expect(find.byType(StoreScreen), findsOneWidget);
      expect(app.activity.actions.last, 'store_opened:GS25');
      expect(camera.status, CameraStatus.paused);
      expect(find.text('120 ta mahsulot'), findsOneWidget);
      expect(app.barcodes.pages, ['joiz/-/0']);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(app.barcodes.pages, ['joiz/-/0', 'joiz/-/20']);

      final chips = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal);
      await tester.drag(chips, const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: chips, matching: find.text('Yengil ovqatlar')));
      await tester.pumpAndSettle();
      expect(app.barcodes.pages.last, 'joiz/Snacks/0');
      expect(find.text('Snacks 1'), findsOneWidget);

      await tapVisible(tester, find.text('Shubhali'));
      expect(app.barcodes.pages.last, 'shubhali/-/0');
      await tapVisible(tester, find.text('Mahsulot 1'));
      expect(find.text('Shubhali'), findsWidgets);
      expect(find.text('Keyingisini skanerlash'), findsNothing, reason: 'browsing, not scanning');

      // Android's back: the sheet, then the store.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(StoreScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(StoreScreen), findsNothing);
      expect(camera.status, CameraStatus.paused, reason: 'still scrolled down to the stores');
      await tester.tap(find.byTooltip('Skanerlash'));
      await tester.pumpAndSettle();
      expect(camera.status, CameraStatus.running);
    });

    testWidgets('none prohibited: an empty list says so', (tester) async {
      await openScanner(tester, language: 'en');
      await tapVisible(tester, find.text('GS25'));
      await tapVisible(tester, find.text('Prohibited'));
      expect(find.text('No products found'), findsOneWidget);
    });
  });

  group('codes', () {
    test('typed: digits, 8 to 14, and the check digit', () {
      expect(checkTypedCode(''), CodeProblem.empty);
      expect(checkTypedCode('88O1'), CodeProblem.nonDigit);
      expect(checkTypedCode('1234567'), CodeProblem.length);
      expect(checkTypedCode('880104301480900'), CodeProblem.length);
      expect(checkTypedCode('8801043014800'), CodeProblem.checksum);
      expect(checkTypedCode(cola), isNull);
      expect(checkTypedCode('88012346'), isNull, reason: 'EAN-8');
      expect(checkTypedCode('036000291452'), isNull, reason: 'UPC-A');
      expect(checkTypedCode('1234567890'), isNull, reason: 'no check digit to test at 10');
    });

    test('a photo on the API is given its full address', () {
      expect(
        Product.fromJson({'barcode': '1', 'image': '/api/v2/image/1.jpg'}).imageUrl,
        Uri.parse('https://vegukin-api.duckdns.org/api/v2/image/1.jpg'),
      );
      expect(Product.fromJson({'barcode': '1', 'image': ''}).imageUrl, isNull);
      expect(Product.fromJson({'barcode': '1', 'verdict': 'NOJOIZ'}).verdict, Verdict.nojoiz);
    });
  });

  group('API', () {
    test('found, not found (also as a 404), and no connection', () async {
      final asked = <Uri>[];
      final source = HttpBarcodeSource(MockClient((request) async {
        asked.add(request.url);
        return switch (request.url.pathSegments.last) {
          cola => http.Response(
              jsonEncode({'found': true, 'barcode': cola, 'name': '사이다', 'verdict': 'joiz', 'otherStores': [{'store': 'CU'}]}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          unknown => http.Response('{"found": false}', 404),
          _ => http.Response('oops', 500),
        };
      }));
      final product = await source.product(cola);
      expect(product!.name, '사이다');
      expect(product.otherStores, ['CU']);
      expect(asked.single.toString(), 'https://vegukin-api.duckdns.org/api/v2/product/$cola');
      expect(await source.product(unknown), isNull);
      expect(source.product(sausage), throwsA(isA<BarcodeException>()));
    });

    test('a store page asks as the web page does', () async {
      Uri? asked;
      final source = HttpBarcodeSource(MockClient((request) async {
        asked = request.url;
        return http.Response(jsonEncode({'total': 41, 'hasMore': true, 'products': [{'barcode': '1', 'verdict': 'joiz'}]}), 200);
      }));
      final page = await source.storeProducts('7-Eleven', verdict: Verdict.shubhali, category: 'Cup Noodles/Ramen', offset: 20);
      expect(asked!.path, '/api/v2/store/7-Eleven/products');
      expect(asked!.queryParameters, {'verdict': 'shubhali', 'offset': '20', 'limit': '20', 'category': 'Cup Noodles/Ramen'});
      expect(page.total, 41);
      expect(page.hasMore, isTrue);
    });
  });
}
