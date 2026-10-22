import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/features/places/place_actions.dart';
import 'package:muslim_vegukin/features/places/place_detail.dart';
import 'package:muslim_vegukin/features/places/places_kit.dart';
import 'package:muslim_vegukin/features/places/places_models.dart';
import 'package:muslim_vegukin/features/places/places_parts.dart';
import 'package:muslim_vegukin/features/places/places_screen.dart';
import 'package:muslim_vegukin/features/places/places_source.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';
import 'package:muslim_vegukin/l10n/app_localizations_en.dart';

import 'support/fakes.dart';

Future<TestApp> openPlaces(WidgetTester tester, {String language = 'en', TestApp? app, String label = 'Mosques'}) async {
  app ??= TestApp(language: language);
  await app.launch(tester);
  await tester.scrollUntilVisible(find.text(label), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  return app;
}

Finder card(String name) => find.ancestor(of: find.text(name), matching: find.byType(PlaceCard));

/// The ids of the cards built, in order.
List<int> cardIds(WidgetTester tester) =>
    tester.widgetList<PlaceCard>(find.byType(PlaceCard, skipOffstage: false)).map((c) => c.place.id).toList();

/// Scrolled to the middle of the screen (clear of the pinned bar), and tapped.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.runAsync(() => Scrollable.ensureVisible(tester.element(finder), alignment: 0.5));
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The sign-in sheet's Google button, and the sheet gone.
Future<void> signInWithGoogle(WidgetTester tester) async {
  await tester.tap(find.text('Continue with Google'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('a place', () {
    test('from the server: phones apart, a blank location none, only web links', () {
      final place = Place.fromJson({
        'id': 7,
        'name': ' Masjid ',
        'buildingType': 'Masjid',
        'phone': '010-1, 031-2 ,',
        'lat': 0,
        'lon': 0,
        'kakaoMapUrl': 'javascript:alert(1)',
        'naverMapUrl': 'https://naver.me/x',
        'ownerNote': '   ',
        'averageRating': 4.5,
      })!;
      expect((place.name, place.kind), ('Masjid', PlaceKind.mosque));
      expect(place.phones, ['010-1', '031-2']);
      expect((place.located, place.kakaoUrl, place.naverUrl, place.note), (false, null, 'https://naver.me/x', null));
      expect(Place.fromJson({'id': 1, 'name': 'x', 'buildingType': 'Cafe'}), isNull);
      expect(Place.fromJson({'id': 1, 'name': 'x', 'buildingType': "Do'kon"})!.kind, PlaceKind.shop);
    });

    test('its number as text, as the server sends it, or as a number', () {
      final place = Place.fromJson({'id': '103', 'name': 'Pusan markaziy masjidi', 'buildingType': 'Masjid', 'reviewCount': '4'})!;
      expect((place.id, place.reviewCount), (103, 4));
      expect(Place.fromJson({'id': 'abc', 'name': 'x', 'buildingType': 'Masjid'}), isNull);
      expect(WatchedPlace.fromJson({'placeId': '7', 'name': 'Nur', 'type': 'mosque'})!.id, 7);
      expect(hasHangul('서울 용산구'), isTrue);
      expect(hasHangul('Seoul'), isFalse);
    });

    test('distances in metres near, a decimal under ten km, whole beyond', () {
      final s = AppLocalizationsEn();
      expect(distanceText(s, 0.437), '440 m');
      expect(distanceText(s, 2.06), '2.1 km');
      expect(distanceText(s, 23.4), '23 km');
    });

    test('links: its own map pages, else built from where it is', () {
      final located = Place.fromJson({'id': 1, 'name': 'Nur', 'buildingType': 'Masjid', 'lat': 37.3, 'lon': 126.8})!;
      expect('${kakaoUri(located)}', 'https://map.kakao.com/link/to/Nur,37.3,126.8');
      expect('${googleUri(located)}', 'https://www.google.com/maps/dir/?api=1&destination=37.3%2C126.8');
      final unlocated = Place.fromJson({'id': 2, 'name': 'Nur', 'buildingType': 'Masjid', 'address': '서울 용산구'})!;
      expect('${naverUri(unlocated)}', 'https://map.naver.com/p/search/${Uri.encodeComponent('서울 용산구')}');
      expect('${telUri('010-1234 5678 (ext)')}', 'tel:010-12345678()');
      final s = AppLocalizationsEn();
      expect(socialHandle(s, 'telegram', 'https://t.me/+AbCdEf'), 'Link');
      expect(socialHandle(s, 'instagram', 'https://www.instagram.com/vegukin/'), '@vegukin');
      expect(socialHandle(s, 'tiktok', 'https://www.tiktok.com/@halal'), '@halal');
    });

    test('a page: one’s own review known only from a server that marks it', () {
      final detail = PlaceDetail.fromJson({
        'id': 1,
        'name': 'Nur',
        'buildingType': 'Masjid',
        'reviews': [
          {'rating': 5, 'text': 'Good', 'timestamp': '2026-10-01T10:00:00.000Z', 'mine': false},
          {'rating': 3, 'text': '', 'timestamp': '2026-09-01T10:00:00.000Z', 'mine': true},
        ],
        'pendingFields': ['note'],
        'watch': {'watchCount': 4, 'watching': true},
      })!;
      expect((detail.ownReviews, detail.myReview?.rating, detail.average), (true, 3, 4.0));
      expect(detail.spread, [0, 0, 1, 0, 1]);
      expect(detail.pending, {'note'});
      expect((detail.watch.count, detail.watch.watching), (4, true));
      final old = PlaceDetail.fromJson({
        'id': 1,
        'name': 'Nur',
        'buildingType': 'Masjid',
        'reviews': [
          {'rating': 5, 'userId': '555'},
        ],
      })!;
      expect((old.ownReviews, old.myReview), (false, null));
    });
  });

  group('the server', () {
    test('five nearest, as the web page asks; the server’s place numbers as text', () async {
      final asked = <http.Request>[];
      final source = HttpPlacesSource(MockClient((request) async {
        asked.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'places': [
              {'id': '103', 'name': 'Pusan markaziy masjidi', 'buildingType': 'Masjid', 'city': 'Busan', 'distance': 1.27,
                'lat': 35.259987044324, 'lon': 129.092258069682, 'kakaoMapUrl': 'http://kko.to/CqJss1CVA'},
            ],
          }),
          200,
        );
      }));
      final places = await source.nearby(PlaceKind.mosque, 35.2, 129.1);
      expect((places.single.id, places.single.distanceKm, places.single.kakaoUrl), (103, 1.27, 'http://kko.to/CqJss1CVA'));
      expect(asked.last.url.queryParameters, {'lat': '35.2', 'lon': '129.1', 'building_type': 'Masjid', 'limit': '5'});
      await source.nearAddress(PlaceKind.shop, '서울 용산구');
      expect(asked.last.url.path, '/api/places/by-address');
      expect(asked.last.url.queryParameters, {'address': '서울 용산구', 'building_type': "Do'kon", 'limit': '5'});
    });

    test('a page with the account; a review in its shape; unwatching without a body; errors by their code', () async {
      final asked = <http.Request>[];
      final source = HttpPlacesSource(MockClient((request) async {
        asked.add(request);
        if (request.url.path.endsWith('/submit') && request.url.path.contains('/place/')) {
          return http.Response(jsonEncode({'success': false, 'code': 'invalid_handle', 'error': 'bad'}), 400);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'updated': true,
            'watching': false,
            'watchCount': 2,
            'place': {'id': 9, 'name': 'Nur', 'buildingType': 'Masjid', 'reviews': []},
          }),
          200,
        );
      }));
      const auth = {'Authorization': 'Bearer t'};
      final detail = await source.detail(9, auth);
      expect(detail.place.name, 'Nur');
      expect(asked.last.url.toString(), 'https://vegukin-api.duckdns.org/api/place/9?view=1');
      expect(asked.last.headers['Authorization'], 'Bearer t');

      expect(await source.review(auth, 9, 4, 'Good'), isTrue);
      expect(jsonDecode(asked.last.body), {'place_id': 9, 'rating': 4, 'review_text': 'Good'});

      final watch = await source.watch(auth, 9, on: false, lang: 'uz');
      expect((asked.last.method, asked.last.body, watch.watching, watch.count), ('DELETE', '', false, 2));

      await expectLater(
        source.suggest(auth, 9, 'telegram', '@x y'),
        throwsA(isA<PlacesException>().having((e) => e.code, 'code', 'invalid_handle')),
      );
    });
  });

  group('the list', () {
    testWidgets('with location allowed, near me at once: a new fix, the five nearest, how far', (tester) async {
      final app = await openPlaces(tester);
      expect(find.byType(PlacesScreen), findsOneWidget);
      expect(app.opened.ids, isEmpty, reason: 'not the web page');
      expect(find.text('Search near me'), findsOneWidget);
      expect(find.text('Search near an address'), findsOneWidget);
      expect(app.places.asked, contains('nearby mosque 5'));
      expect(find.text('🕌  The 5 nearest mosques'), findsOneWidget);
      expect(find.text('You’re in Ansan · Just now'), findsOneWidget);
      expect(cardIds(tester).take(3), [6, 1, 2]);
      await tester.scrollUntilVisible(find.text('Daegu Masjid'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Yangi namozxona'), findsNothing, reason: 'five: the one without a location isn’t near');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('Nearest'), findsOneWidget);
      expect(find.text('1.4 km'), findsOneWidget);
    });

    testWidgets('near me measures again every time: moved a few km, other places', (tester) async {
      final app = await openPlaces(tester);
      final fixes = app.location.fixes;
      app.location
        ..lat = 37.534
        ..lon = 126.994
        ..city = 'Seoul';
      await tester.tap(find.text('Search near me'));
      await tester.pumpAndSettle();
      expect(app.location.fixes, fixes + 1, reason: 'a new fix, not the one kept for the prayer times');
      expect(app.places.lastNear, (lat: 37.534, lon: 126.994));
      expect(cardIds(tester).first, 3);
      expect(find.text('You’re in Seoul · Just now'), findsOneWidget);

      // Only 2 km on: the prayer times keep their point, the places don't.
      app.location.lat = 37.552;
      await tester.tap(find.text('Search near me'));
      await tester.pumpAndSettle();
      expect(app.places.lastNear, (lat: 37.552, lon: 126.994));
    });

    testWidgets('location not allowed yet: the choice first; near me asks; refused: allow, or an address', (tester) async {
      final app = TestApp(language: 'en', location: FakeLocation(access: LocationAccess.denied, afterRequest: LocationAccess.denied));
      await openPlaces(tester, app: app);
      expect(find.text('Where shall we look?'), findsOneWidget);
      expect(app.places.asked.where((a) => a.startsWith('nearby')), isEmpty, reason: 'nothing asked unasked');
      final asked = app.location.requests;
      await tester.tap(find.text('Search near me'));
      await tester.pumpAndSettle();
      expect(app.location.requests, asked + 1, reason: 'the tap asks for it');
      expect(find.text('Allow location to find the nearest places, or search by address.'), findsOneWidget);
      await tester.tap(find.text('Search by address'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('no new fix: the location saved before, said so', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      app.location.failFix = true;
      await tester.scrollUntilVisible(find.text('Mosques'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Mosques'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t get your current location — showing for Ansan (just now)'), findsOneWidget);
      expect(cardIds(tester).first, 6);
    });

    testWidgets('near an address: in Korean, found, remembered; one not found said under the field', (tester) async {
      final app = await openPlaces(tester);
      await tester.tap(find.text('Search near an address'));
      await tester.pumpAndSettle();
      expect(find.text('서울 강동구 구천면로 271'), findsOneWidget, reason: 'the web page’s example');
      await tester.enterText(find.byType(TextField), '서울 용산구');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(app.places.asked, contains('address mosque 서울 용산구 5'));
      expect(find.text('🕌  Nearest to the address'), findsOneWidget);
      expect(find.text('서울 용산구 이태원동'), findsOneWidget);
      expect(cardIds(tester).first, 3);
      expect(find.text('290 m'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.text('Recent addresses'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '부산');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('That address wasn’t found. Try writing it more precisely, in Korean.'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, '서울 용산구').last);
      await tester.pumpAndSettle();
      expect(cardIds(tester).first, 3, reason: 'a recent address, one tap');
    });

    testWidgets('each kind opened is counted apart, as on the web', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      for (final label in ['Mosques', 'Restaurants', 'Shops']) {
        await tester.scrollUntilVisible(find.text(label), 200, scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byType(PlacesScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      expect(app.activity.actions.where((a) => ['mosque', 'restaurant', 'shop'].contains(a)), ['mosque', 'restaurant', 'shop']);
    });

    testWidgets('the call and the way there on the card', (tester) async {
      final app = await openPlaces(tester, label: 'Restaurants');
      expect(cardIds(tester), [101]);
      expect(find.text('🍽️  The nearest restaurant'), findsOneWidget);
      await tester.tap(find.descendant(of: card('Samarqand Osh Markazi'), matching: find.text('Call')));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('tel:010-3333-4444'));

      await tester.tap(find.descendant(of: card('Samarqand Osh Markazi'), matching: find.text('Directions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kakao Map'));
      await tester.pumpAndSettle();
      expect('${app.links.last}', 'https://map.kakao.com/link/to/Samarqand%20Osh%20Markazi,37.321,126.832');
    });

    testWidgets('two numbers: which one to call', (tester) async {
      final app = await openPlaces(tester);
      await tapVisible(tester, find.descendant(of: card('Ansan Markaziy Masjidi'), matching: find.text('Call')));
      expect(find.text('Which number?'), findsOneWidget);
      await tester.tap(find.text('031-555-6666'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('tel:031-555-6666'));
    });

    testWidgets('offline: said so, and tried again', (tester) async {
      final app = TestApp(language: 'en');
      app.places.fail = true;
      await openPlaces(tester, app: app);
      expect(find.text('Couldn’t load the places. Check your connection.'), findsOneWidget);
      app.places.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('🕌  The 5 nearest mosques'), findsOneWidget);
    });
  });

  group('a place’s page', () {
    Future<TestApp> openAnsan(WidgetTester tester, {TestApp? app}) async {
      app = await openPlaces(tester, app: app);
      await tapVisible(tester, find.text('Ansan Markaziy Masjidi'));
      expect(find.byType(PlaceDetailScreen), findsOneWidget);
      return app;
    }

    testWidgets('what it is, how far, its numbers and note and links, what people say', (tester) async {
      final app = await openAnsan(tester);
      expect(find.text('🕌  MOSQUE'), findsOneWidget);
      expect(find.textContaining('2.1 km from you · Ansan'), findsOneWidget);
      expect(find.text('Get directions'), findsOneWidget, reason: 'its map');
      expect(find.text('4.7'), findsWidgets);
      expect(find.text('· 3 reviews'), findsOneWidget);
      expect(find.text('010-1111-2222'), findsOneWidget);
      expect(find.text('031-555-6666'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Juma namozi: 13:00\nHar kuni ochiq'), 200, scrollable: find.byType(Scrollable).first);
      await tapVisible(tester, find.text('Telegram · @ansanmasjid'));
      expect(app.links.last, Uri.parse('https://t.me/ansanmasjid'));
      await tester.scrollUntilVisible(find.text('Juda toza, wudu joyi bor'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Rating only'), findsOneWidget, reason: 'a review without words');
      expect(app.places.asked.where((a) => a.startsWith('detail 1')), hasLength(1));
    });

    testWidgets('call, directions in Naver, the address copied, shared', (tester) async {
      final app = await openAnsan(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      await tester.tap(find.descendant(of: find.byType(PlaceDetailScreen), matching: find.text('Directions')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Naver Map'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://naver.me/abc'), reason: 'its own Naver page');

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(copied, '경기 안산시 단원구 원곡로 5');
      expect(find.text('Address copied'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(PlaceDetailScreen), matching: find.text('Share')));
      await tester.pumpAndSettle();
      expect(app.shared.single, contains('🕌 Ansan Markaziy Masjidi'));
      expect(app.shared.single, contains('📍 경기 안산시 단원구 원곡로 5'));
      expect(app.shared.single, contains('https://naver.me/abc'));
    });

    testWidgets('watched with a tap, no sign-in needed; and the list knows', (tester) async {
      final app = await openAnsan(tester);
      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();
      expect(app.places.asked, contains('watch 1 true en'));
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('44'), findsOneWidget);
      expect(find.textContaining('this phone').evaluate().isNotEmpty || find.text('Notifications are off, so news won’t arrive').evaluate().isNotEmpty, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.descendant(of: card('Ansan Markaziy Masjidi'), matching: find.text('Watching')), findsOneWidget);
    });

    testWidgets('a review: signed in first; one per person, changed and deleted', (tester) async {
      final app = await openAnsan(tester);
      await tapVisible(tester, find.text('Write a review'));
      expect(find.text('Sign in'), findsWidgets, reason: 'a review needs a name');
      await signInWithGoogle(tester);
      expect(find.text('How would you rate it?'), findsOneWidget);

      await tester.tap(find.text('Publish'));
      await tester.pump();
      expect(find.text('Choose a rating first'), findsOneWidget);
      await tester.tap(find.byTooltip('Good'));
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Toza, keng');
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(app.places.asked, contains('review 1 4 Toza, keng'));
      expect(find.text('Thank you! Your review is published.'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Your review'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Toza, keng'), findsOneWidget);
      await tapVisible(tester, find.text('Change your review'));
      expect(find.text('Toza, keng'), findsWidgets, reason: 'what was written, to change');
      await tester.tap(find.text('Delete the review'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(app.places.asked, contains('unreview 1'));
      expect(find.text('Your review is deleted.'), findsOneWidget);
      expect(find.text('Your review'), findsNothing);
    });

    testWidgets('opening hours suggested, and shown as waiting; a bad link said so', (tester) async {
      final app = await openPlaces(tester);
      await tapVisible(tester, find.text('Siheung Masjidi'));
      await tapVisible(tester, find.text('Add information'));
      await signInWithGoogle(tester);
      expect(find.text('It appears once an admin has checked it.'), findsOneWidget);
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Har kuni 05:00–23:00');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(app.places.suggestions.single, (2, 'note', 'Har kuni 05:00–23:00'));
      expect(find.text('Thank you! Your suggestion is under review.'), findsOneWidget);
      expect(find.text('Information: a suggestion is waiting for review'), findsOneWidget);

      app.places.failNext['suggest'] = 'invalid_handle';
      await tapVisible(tester, find.text('Add'));
      await tester.tap(find.text('Telegram'));
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), '@1x');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('That username is not valid. Letters, digits and underscores only.'), findsOneWidget);
    });

    testWidgets('a mosque’s announcement to its watchers; a restaurant claimed by its owner', (tester) async {
      final app = await openAnsan(tester);
      await tapVisible(tester, find.text('Write an announcement'));
      await signInWithGoogle(tester);
      expect(find.text('Once an admin approves it, about 43 people will get it.'), findsOneWidget);
      await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Hayit namozi 07:30');
      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();
      expect(app.places.announcements.single, (1, 'Hayit namozi 07:30'));
      expect(find.text('Sent for review'), findsOneWidget);
      expect(find.text('1 awaiting review'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Restaurants'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Restaurants'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Samarqand Osh Markazi'));
      expect(find.text('Write an announcement'), findsNothing, reason: 'only its owner posts');
      await tapVisible(tester, find.text('Claim it'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(app.places.claims, [101]);
      expect(find.text('Request sent. The admin will get in touch.'), findsWidgets);
    });

    testWidgets('a restaurant’s menu', (tester) async {
      final app = await openPlaces(tester, label: 'Restaurants');
      await tapVisible(tester, find.text('Samarqand Osh Markazi'));
      await tapVisible(tester, find.text('Open the menu'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://menu.example/osh'));
    });

    testWidgets('from a notification: the place itself, as its own type, whatever the link said', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      app.push.open({'url': 'https://vegukin-twa.pages.dev/pages/places/places-detail.html?type=restaurant&id=1'});
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailScreen), findsOneWidget);
      expect(find.text('🕌  MOSQUE'), findsOneWidget);
      expect(app.opened.ids, isEmpty, reason: 'not the web page');
    });

    testWidgets('a place gone from the list: said so', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      app.push.open({'url': 'https://vegukin-twa.pages.dev/pages/places/places-detail.html?type=mosque&id=999'});
      await tester.pumpAndSettle();
      expect(find.text('This place wasn’t found. It may have been removed.'), findsOneWidget);
    });
  });
}
