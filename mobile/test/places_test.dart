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

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
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

    test('typed in Cyrillic or Latin, with or without apostrophes, finds the same', () {
      expect(foldForSearch('Ансан'), 'ansan');
      expect(foldForSearch("O‘zbek  Do'kon"), 'ozbek dokon');
      expect(foldForSearch('Ўзбек'), foldForSearch('O‘zbek'));
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
    test('every place, asked again with its tag; unchanged: nothing; before update 6: unsupported', () async {
      final asked = <http.Request>[];
      var status = 200;
      final source = HttpPlacesSource(MockClient((request) async {
        asked.add(request);
        if (status == 304) return http.Response('', 304);
        if (status == 404) return http.Response('<html>Not Found</html>', 404);
        return http.Response(
          jsonEncode({
            'success': true,
            'places': [
              {'id': 1, 'name': 'Nur', 'buildingType': 'Masjid', 'city': 'Ansan'},
            ],
          }),
          200,
          headers: {'etag': '"abc"', 'content-type': 'application/json'},
        );
      }));
      final first = await source.all(PlaceKind.mosque);
      expect((first!.places.single.city, first.etag), ('Ansan', '"abc"'));
      expect(asked.last.url.toString(), 'https://vegukin-api.duckdns.org/api/places/all?building_type=Masjid');
      status = 304;
      expect(await source.all(PlaceKind.mosque, etag: '"abc"'), isNull);
      expect(asked.last.headers['If-None-Match'], '"abc"');
      status = 404;
      await expectLater(source.all(PlaceKind.shop), throwsA(isA<PlacesException>().having((e) => e.code, 'code', 'unsupported')));
      expect(asked.last.url.queryParameters['building_type'], "Do'kon");
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
    testWidgets('native from the home screen: every mosque, the nearest first, how far', (tester) async {
      final app = await openPlaces(tester);
      expect(find.byType(PlacesScreen), findsOneWidget);
      expect(app.opened.ids, isEmpty, reason: 'not the web page');
      expect(find.text('6 mosques · nearest first'), findsOneWidget);
      expect(find.textContaining('Around Ansan'), findsOneWidget);
      expect(cardIds(tester).take(3), [6, 1, 2]);
      expect(find.text('Nearest'), findsOneWidget);
      expect(find.textContaining('1.4 km · Ansan'), findsOneWidget);
      expect(find.text('Ansan · 2', skipOffstage: false), findsOneWidget, reason: 'its cities, the busiest first');
    });

    testWidgets('found by name in either script; a Korean address searched around; its city alone', (tester) async {
      final app = await openPlaces(tester);
      await tester.enterText(find.byType(TextField), 'Ансан');
      await tester.pumpAndSettle();
      expect(find.text('2 mosques'), findsOneWidget);
      expect(cardIds(tester), [6, 1]);

      await tester.enterText(find.byType(TextField), '서울 용산구');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search near “서울 용산구”'));
      await tester.pumpAndSettle();
      expect(app.places.asked, contains('address mosque 서울 용산구'));
      expect(find.text('Around “서울 용산구 이태원동”'), findsOneWidget);
      expect(cardIds(tester).first, 3, reason: 'Seoul’s, measured from Itaewon');

      await tester.enterText(find.byType(TextField), '부산');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search near “부산”'));
      await tester.pumpAndSettle();
      expect(find.text('That address wasn’t found. Try writing it more precisely, in Korean.'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daegu · 1'));
      await tester.pumpAndSettle();
      expect(cardIds(tester), [4]);
    });

    testWidgets('restaurants and shops a tap away; the call and the way there on the card', (tester) async {
      final app = await openPlaces(tester);
      await tester.tap(find.descendant(of: find.byType(PlacesScreen), matching: find.text('Restaurants')).last);
      await tester.pumpAndSettle();
      expect(cardIds(tester), [101]);
      expect(find.text('1 restaurant · nearest first'), findsOneWidget);

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
      await tester.tap(find.descendant(of: card('Ansan Markaziy Masjidi'), matching: find.text('Call')));
      await tester.pumpAndSettle();
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
      expect(find.text('6 mosques · nearest first'), findsOneWidget);
    });

    testWidgets('kept on the phone: the next time asks only whether it changed', (tester) async {
      final app = await openPlaces(tester);
      expect(app.places.asked.where((a) => a.startsWith('all')), ['all mosque -']);
      await tester.pageBack();
      await tester.pumpAndSettle();
      app.places.fail = true;
      await tester.tap(find.text('Mosques'));
      await tester.pumpAndSettle();
      expect(find.text('6 mosques · nearest first'), findsOneWidget, reason: 'offline, from the phone');
      expect(find.text('Couldn’t load the places. Check your connection.'), findsNothing);
      app.places.fail = false;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mosques'));
      await tester.pumpAndSettle();
      expect(app.places.asked.where((a) => a.startsWith('all')).last, 'all mosque e1');
    });

    testWidgets('a server before update 6: the nearest few from the location', (tester) async {
      final app = TestApp(language: 'en');
      app.places.oldServer = true;
      await openPlaces(tester, app: app);
      expect(app.places.asked, contains('nearby mosque'));
      expect(cardIds(tester).take(3), [6, 1, 2]);
      expect(find.text('Ansan · 2'), findsNothing, reason: 'no cities from a few');
    });
  });

  group('a place’s page', () {
    Future<TestApp> openAnsan(WidgetTester tester, {TestApp? app}) async {
      app = await openPlaces(tester, app: app);
      await tester.tap(find.text('Ansan Markaziy Masjidi'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailScreen), findsOneWidget);
      return app;
    }

    testWidgets('what it is, how far, its numbers and note and links, what people say', (tester) async {
      final app = await openAnsan(tester);
      expect(find.text('🕌  MOSQUE'), findsOneWidget);
      expect(find.textContaining('2.1 km · Ansan'), findsOneWidget);
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
      expect(find.descendant(of: card('Ansan Markaziy Masjidi'), matching: find.byIcon(Icons.notifications_active_rounded)), findsOneWidget);
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
      await tester.tap(find.text('Siheung Masjidi'));
      await tester.pumpAndSettle();
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
      await tester.tap(find.descendant(of: find.byType(PlacesScreen), matching: find.text('Restaurants')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Samarqand Osh Markazi'));
      await tester.pumpAndSettle();
      expect(find.text('Write an announcement'), findsNothing, reason: 'only its owner posts');
      await tapVisible(tester, find.text('Claim it'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(app.places.claims, [101]);
      expect(find.text('Request sent. The admin will get in touch.'), findsWidgets);
    });

    testWidgets('a restaurant’s menu', (tester) async {
      final app = await openPlaces(tester, label: 'Restaurants');
      await tester.tap(find.text('Samarqand Osh Markazi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open the menu'));
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
