import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muslim_vegukin/features/cars/car_detail.dart';
import 'package:muslim_vegukin/features/cars/cars_sell.dart';
import 'package:muslim_vegukin/features/cars/cars_models.dart';
import 'package:muslim_vegukin/features/cars/cars_parts.dart';
import 'package:muslim_vegukin/features/cars/cars_screen.dart';
import 'package:muslim_vegukin/features/cars/cars_source.dart';

import 'support/fakes.dart';

Future<TestApp> openCars(WidgetTester tester, {TestApp? app}) async {
  app ??= TestApp(language: 'en');
  await app.launch(tester);
  await pushPage(tester, CarsScreen(services: app.services));
  await tester.pumpAndSettle();
  return app;
}

Finder card(int id) => find.byWidgetPredicate((w) => w is CarCard && w.car.id == id);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.runAsync(() => Scrollable.ensureVisible(tester.element(finder), alignment: 0.5));
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('a listing', () {
    test('from the server: numbers as text, media on the server’s address, a handle without @', () {
      final car = Car.fromJson({
        'id': '9',
        'brand': ' Kia ',
        'model': 'K5',
        'year': '2017',
        'price_krw': 9900000,
        'status': 'sold',
        'photo': '/media/cars/9/1.jpg',
        'contact_handle': '@seller',
        'media': [
          {'type': 'video', 'url': '/media/9/v.mp4', 'size_bytes': '1048576'},
        ],
      })!;
      expect((car.id, car.brand, car.year, car.sold, car.contactHandle), (9, 'Kia', 2017, true, 'seller'));
      expect('${car.photo}', 'https://vegukin-api.duckdns.org/media/cars/9/1.jpg');
      expect((car.media!.single.video, car.media!.single.sizeBytes), (true, 1048576));
      expect(Car.fromJson({'brand': 'x'}), isNull);
    });

    test('prices as the web page writes them', () {
      expect(won(7500000), '7 500 000 ₩');
      expect(wonShort(7500000), '7.5M');
      expect(wonShort(7000000), '7M');
      expect(kmShort(150000), '150k km');
      expect(groupDigits('1234567'), '1 234 567');
    });

    test('the market: the middle price, an odd one out off the scale, cars of about its year', () {
      expect(median([3, 1, 2]), 2);
      expect(median([1, 2, 3, 4]), 3);
      final spread = PriceSpread.of([2000000, 2500000, 3000000, 3500000, 4000000, 15000000]);
      expect(spread.hi, lessThan(15000000), reason: 'a 15M among 2–4M doesn’t stretch the scale');
      expect(spread.lo, 2000000);
      final cars = [for (final (i, y) in [2014, 2015, 2015, 2016, 2009].indexed) Car(id: i, year: y, priceKrw: 5000000 + i * 100000)];
      expect(nearYears(Car(id: 99, year: 2015), cars)?.spread.n, 4);
      expect(nearYears(Car(id: 99, year: 2009), cars), isNull, reason: 'too few of about its year');
      expect(dealOf(9000000, 10000000), Deal.low);
      expect(dealOf(10300000, 10000000), Deal.mid);
      expect(dealOf(11000000, 10000000), Deal.high);
    });

    test('sorted: price both ways (no price last), mileage, year, value', () {
      final cars = [
        const Car(id: 1, priceKrw: 7000000, year: 2015, mileageKm: 90000),
        const Car(id: 2, year: 2018, mileageKm: 40000),
        const Car(id: 3, priceKrw: 5000000, year: 2012, mileageKm: 200000),
      ];
      List<int> ids(CarSort s) => sortCars(cars, s, 2026).map((c) => c.id).toList();
      expect(ids(CarSort.priceLow), [3, 1, 2]);
      expect(ids(CarSort.priceHigh), [1, 3, 2]);
      expect(ids(CarSort.mileageLow), [2, 1, 3]);
      expect(ids(CarSort.yearNew), [2, 1, 3]);
      expect(ids(CarSort.newest), [1, 2, 3]);
      expect(ids(CarSort.value).last, 2);
    });
  });

  test('the server: the web page’s addresses and parameters', () async {
    final asked = <http.Request>[];
    final source = HttpCarsSource(MockClient((request) async {
      asked.add(request);
      final path = request.url.path;
      final body = switch (path) {
        '/api/cars/catalog' => [
            {'brand': 'Hyundai', 'total': 3, 'models': [{'model': 'Sonata', 'count': 3}]},
          ],
        '/api/cars/car' => {'id': 5, 'brand': 'Hyundai', 'media': []},
        '/api/cars/car/5/view' => {'views': 7},
        _ => {'cars': [{'id': 5, 'brand': 'Hyundai'}], 'count': 40},
      };
      return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    expect((await source.catalog()).single.models.single.model, 'Sonata');
    await source.model('Hyundai', 'Sonata');
    expect(asked.last.url.toString(), 'https://vegukin-api.duckdns.org/api/cars/model?brand=Hyundai&model=Sonata');
    final found = await source.search(const CarQuery(priceMax: 7000000, fuels: {'lpg', 'diesel'}, status: 'active'));
    expect(found.count, 40);
    expect(asked.last.url.queryParameters, {'price_max': '7000000', 'fuel': 'lpg,diesel', 'status': 'active'});
    expect((await source.car(5)).full, isTrue);
    expect(await source.view(5), 7);
    expect(asked.last.method, 'POST');
  });

  group('the market', () {
    testWidgets('opened from home, natively; everything newest first, then one model with its going price', (tester) async {
      final app = TestApp(language: 'uz');
      await app.launch(tester);
      await tester.scrollUntilVisible(find.text('Vegukin Cars'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Vegukin Cars'));
      await tester.pumpAndSettle();
      expect(find.byType(CarsScreen), findsOneWidget);
      expect(app.opened.ids, isEmpty, reason: 'not the web page');
      expect(app.activity.actions, contains('cars'));
      expect(find.text('Avto Bozor'), findsOneWidget);
      expect(find.text('8 ta e’lon'), findsOneWidget);
      expect(find.byType(CarCard), findsWidgets);

      await tester.tap(find.text('Avto Bozor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hyundai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sonata'));
      await tester.pumpAndSettle();
      expect(find.text('Hyundai Sonata'), findsOneWidget);
      expect(find.text('5 mavjud · 1 sotilgan'), findsWidgets);
      expect(find.text('7 500 000 ₩'), findsWidgets, reason: 'the going price');
      expect(find.text('🔥 Arzon'), findsOneWidget, reason: '5.5M under 90% of 7.5M');
    });

    testWidgets('sorted and filtered without asking the server again', (tester) async {
      final app = await openCars(tester);
      final asked = app.cars.asked.length;
      await tester.tap(find.text('Price ↑'));
      await tester.pumpAndSettle();
      List<int> ids() => tester.widgetList<CarCard>(find.byType(CarCard, skipOffstage: false)).map((c) => c.car.id).toList();
      expect(ids().first, 1, reason: '5.5M first');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(ids().last, 8, reason: 'no price last');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(StatusSwitch), matching: find.text('Sold')));
      await tester.pumpAndSettle();
      expect(tester.widgetList<CarCard>(find.byType(CarCard, skipOffstage: false)).map((c) => c.car.id), [6]);
      expect(app.cars.asked.length, asked);
    });

    testWidgets('a listing: the price judged against its year, the post, a call, a video, seen in the list', (tester) async {
      final app = await openCars(tester);
      await tapVisible(tester, find.descendant(of: card(1), matching: find.text('5 500 000 ₩')));
      expect(find.byType(CarDetailScreen), findsOneWidget);
      expect(find.text('2015 Hyundai Sonata LF'), findsOneWidget);
      expect(app.cars.views, [1]);
      await tester.scrollUntilVisible(find.text('Price check'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Very cheap'), findsOneWidget);
      expect(find.textContaining('below average'), findsOneWidget);
      expect(find.textContaining('from around 2015'), findsOneWidget, reason: 'four cars of about its year');

      await tester.tap(find.text('Contact').last);
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('tel:01012345678'));

      await tester.scrollUntilVisible(find.text('Similar cars'), 200, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PageView).first);
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.drag(find.byType(PageView).last, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Video · 5.0 MB'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).last);
      expect('${app.links.last}', 'https://vegukin-api.duckdns.org/media/cars/1/v.mp4');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.descendant(of: card(1), matching: find.text('Seen')), findsOneWidget);
    });

    testWidgets('a seller on Telegram: the button writes to them', (tester) async {
      final app = await openCars(tester);
      await tapVisible(tester, find.descendant(of: card(2), matching: find.text('7 200 000 ₩')));
      await tester.tap(find.text('Message on Telegram').last);
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://t.me/sonata_seller'));
    });

    testWidgets('saved with the heart: counted on the tab, listed, kept on the phone', (tester) async {
      final app = await openCars(tester);
      await tester.tap(find.descendant(of: card(1), matching: find.byTooltip('Save')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('1 saved'), findsOneWidget);
      expect(card(1), findsOneWidget);
      expect(app.store.read('cars_favorites'), contains('"id":1'));

      await tester.pageBack();
      await tester.pumpAndSettle();
      await pushPage(tester, CarsScreen(services: app.services));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(card(1), findsOneWidget, reason: 'still there');
      await tester.tap(find.descendant(of: card(1), matching: find.byTooltip('Remove from saved')));
      await tester.pumpAndSettle();
      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('search: the filters asked of the server, a fuel and a price, then cleared', (tester) async {
      final app = await openCars(tester);
      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '7500000');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('7 500 000'), findsOneWidget, reason: 'grouped as typed');
      await tester.tap(find.text('LPG'));
      await tester.pumpAndSettle();
      expect(app.cars.asked.last, 'search price_max=7500000&fuel=lpg');
      expect(find.text('1 results'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(app.cars.asked.last, 'search ');
      expect(find.text('8 results'), findsOneWidget);
    });

    testWidgets('offline: said so, and tried again', (tester) async {
      final app = TestApp(language: 'en');
      app.cars.fail = true;
      await openCars(tester, app: app);
      expect(find.text('Couldn’t load'), findsOneWidget);
      app.cars.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(CarCard), findsWidgets);
    });

    testWidgets('the channel, after the sixth listing', (tester) async {
      final app = await openCars(tester);
      await tapVisible(tester, find.text('Open'));
      expect(app.links.last, Uri.parse('https://t.me/vegukin_car'));
    });
  });

  group('with an account', () {
    /// A choice in the form: its field (by label), then [option] in the sheet.
    Future<void> choose(WidgetTester tester, String field, String option) async {
      final box = find.descendant(
        of: find.ancestor(of: find.text(field), matching: find.byType(Column)).first,
        matching: find.byIcon(Icons.expand_more_rounded),
      );
      await tester.ensureVisible(box);
      await tester.pumpAndSettle();
      await tester.tap(box);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String hint, String text) async {
      final field = find.widgetWithText(TextField, hint);
      await tester.scrollUntilVisible(field, 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
    }

    Future<void> signIn(WidgetTester tester, TestApp app) async {
      await tester.tap(find.text('Sign in').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      app.cars.signedIn = true;
    }

    testWidgets('saved cars made one with the server: the phone’s sent up, the Mini App’s brought down', (tester) async {
      final app = TestApp(language: 'en');
      await app.store.write('cars_favorites', '[{"id":3,"brand":"Hyundai","model":"Sonata"}]');
      app.cars.favorites.add(7);
      await openCars(tester, app: app);
      expect(app.cars.favorites, {3, 7});
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('2 saved'), findsOneWidget);
      await tester.tap(find.descendant(of: card(7), matching: find.byTooltip('Remove from saved')));
      await tester.pumpAndSettle();
      expect(app.cars.favorites, {3});
    });

    testWidgets('alerts: anyone browses, an alert asks to sign in; then made, listed, deleted', (tester) async {
      final app = await openCars(tester);
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(find.text('Hear about the right car first'), findsOneWidget);
      await signIn(tester, app);
      await tester.tap(find.text('Alerts').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create alert'));
      await tester.pumpAndSettle();
      expect(find.text('Choose at least one filter (model, price, mileage, year or fuel).'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '7000000');
      await tester.tap(find.text('LPG'));
      await tester.tap(find.text('Create alert'));
      await tester.pumpAndSettle();
      expect(app.cars.asked, contains('alert price_max=7000000&fuel=lpg'));
      expect(find.text('≤ 7 000 000 ₩'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(app.cars.alertList, isEmpty);
      expect(find.text('No alerts yet'), findsOneWidget);
    });

    testWidgets('a post: required fields said; photos sent; to the admin; listed as under review', (tester) async {
      CarPostForm.debugPickMedia = (limit) async => [
            XFile.fromData(Uint8List.fromList([1, 2, 3]), path: 'front.jpg', mimeType: 'image/jpeg'),
            XFile.fromData(Uint8List.fromList([4, 5]), path: 'walk.mp4', mimeType: 'video/mp4'),
          ];
      addTearDown(() => CarPostForm.debugPickMedia = null);
      final app = await openCars(tester);
      await tester.tap(find.text('Sell'));
      await tester.pumpAndSettle();
      await signIn(tester, app);
      await tester.tap(find.text('New listing').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();
      expect(find.text('Fill in the required fields'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Cover'), findsOneWidget);
      await choose(tester, 'Make *', 'Kia');
      await choose(tester, 'Model *', 'K5');
      await choose(tester, 'Year *', '2017');
      await type(tester, '7 000 000', '9900000');
      await type(tester, '010 1234 5678', '010-1111-2222');
      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();
      expect(app.cars.asked, contains('post Kia K5 2017 9900000 01011112222'));
      expect(app.cars.uploads.map((u) => (u.$2, u.$3)), [('front.jpg', false), ('walk.mp4', true)]);
      expect(app.cars.asked, contains('submit 100'));
      expect(find.text('Under review'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sold'), findsNothing, reason: 'not before it’s live');
    });

    testWidgets('the same car posted again: said so, and nothing sent', (tester) async {
      CarPostForm.debugPickMedia = (limit) async => [XFile.fromData(Uint8List.fromList([1]), name: 'a.jpg', mimeType: 'image/jpeg')];
      addTearDown(() => CarPostForm.debugPickMedia = null);
      final app = await openCars(tester);
      app.cars.dupes = [const CarDuplicate(id: 1, brand: 'Hyundai', model: 'Sonata', year: 2015, priceKrw: 5500000, viewable: true)];
      await tester.tap(find.text('Sell'));
      await tester.pumpAndSettle();
      await signIn(tester, app);
      await tester.tap(find.text('New listing').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      for (final (field, option) in [('Make *', 'Hyundai'), ('Model *', 'Sonata'), ('Year *', '2015')]) {
        await choose(tester, field, option);
      }
      await type(tester, '7 000 000', '5500000');
      await type(tester, '@username', '@seller');
      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();
      expect(find.text('This car is already listed'), findsOneWidget);
      expect(app.cars.asked.where((a) => a.startsWith('post')), isEmpty);
    });

    testWidgets('a notification about a listing opens it', (tester) async {
      final app = TestApp(language: 'uz');
      await app.launch(tester);
      app.push.open({'url': 'https://vegukin-twa.pages.dev/pages/cars/cars.html?startapp=car2', 'kind': 'car'});
      await tester.pumpAndSettle();
      expect(find.byType(CarDetailScreen), findsOneWidget);
      expect(find.text('2014 Hyundai Sonata LF'), findsOneWidget);
    });
  });
}
