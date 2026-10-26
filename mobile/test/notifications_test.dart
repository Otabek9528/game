import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';
import 'package:muslim_vegukin/features/home/home_screen.dart';
import 'package:muslim_vegukin/features/home/sections.dart';
import 'package:muslim_vegukin/features/notifications/notifications_screen.dart';
import 'package:muslim_vegukin/features/notifications/notify_models.dart';
import 'package:muslim_vegukin/features/places/places_models.dart';

import 'support/fakes.dart';

Future<TestApp> openNotifications(WidgetTester tester, {TestApp? app}) async {
  app ??= TestApp(language: 'uz');
  await app.launch(tester);
  await tester.tap(find.text('Bildirishnomalar').first);
  await tester.pumpAndSettle();
  return app;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('natively: nothing watched yet, the two ways in; messages come to the app', (tester) async {
    final app = await openNotifications(tester);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(app.opened.ids, isEmpty, reason: 'not the web page');
    expect(find.text('Hech narsani o‘tkazib yubormang'), findsOneWidget);
    expect(find.text('Xabarlar shu ilovaga bildirishnoma bo‘lib keladi.'), findsOneWidget);
    expect(find.text('Telegram botda'), findsNothing, reason: 'not a Telegram account');
  });

  testWidgets('an area around where one stands: radius, types, saved; then deleted', (tester) async {
    final app = await openNotifications(tester);
    await tester.tap(find.text('Hududni kuzatish').first);
    await tester.pumpAndSettle();
    expect(find.text('Hozirgina aniqlandi'), findsOneWidget);
    expect(find.textContaining('1 oshxona'), findsOneWidget, reason: 'the preview: what falls inside 3 km');
    await tapVisible(tester, find.text('5 km'));
    await tapVisible(tester, find.text('Do‘konlar').last);
    await tapVisible(tester, find.text('Saqlash'));
    expect(find.text('Hudud saqlandi'), findsOneWidget);
    final area = app.places.areas.single;
    expect((area.radiusKm, area.fromLocation), (5, true));
    expect(area.types, {PlaceKind.mosque, PlaceKind.restaurant});

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    expect(app.places.areas, isEmpty);
    expect(find.text('Hudud o‘chirildi'), findsOneWidget);
  });

  testWidgets('an area by address: one not found is said, a Korean one is saved', (tester) async {
    final app = await openNotifications(tester);
    await tester.tap(find.text('Hududni kuzatish').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manzil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '부산 해운대');
    await tester.tap(find.text('Topish'));
    await tester.pumpAndSettle();
    expect(find.text('Bu manzil topilmadi. Koreys tilida, aniqroq yozib ko‘ring.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '안산 원곡동');
    await tester.tap(find.text('Topish'));
    await tester.pumpAndSettle();
    expect(find.text('경기 안산시 단원구 안산 원곡동'), findsOneWidget);
    await tapVisible(tester, find.text('Saqlash'));
    expect(app.places.areas.single.fromLocation, isFalse);
    expect(find.text('안산 원곡동'), findsOneWidget, reason: 'its card');
  });

  testWidgets('a Telegram account chooses the bot, the app or both; a blocked bot is said, with a check', (tester) async {
    final app = TestApp(language: 'uz');
    app.places
      ..delivery = const NotifyDelivery(telegram: true, push: true, canTelegram: true, bot: 'MuslimVegukinBot')
      ..botBlocked = true;
    await openNotifications(tester, app: app);
    expect(find.text('Telegram botda'), findsOneWidget);
    expect(find.textContaining('Bot sizga xabar yubora olmayapti'), findsOneWidget);
    await tester.tap(find.text('Botni ochish'));
    expect(app.links.last, Uri.parse('https://t.me/MuslimVegukinBot'));
    await tester.tap(find.text('Tekshirish'));
    await tester.pumpAndSettle();
    expect(app.places.asked, contains('hello'));
    expect(find.textContaining('Bot sizga xabar yubora olmayapti'), findsNothing);

    await tester.tap(find.text('Ilovada'));
    await tester.pumpAndSettle();
    expect(app.places.asked.last, 'delivery true false');
    await tester.tap(find.text('Telegram botda'));
    await tester.pumpAndSettle();
    expect(find.text('Kamida bittasi yoqilgan bo‘lsin.'), findsOneWidget);
    expect(app.places.asked.last, 'delivery true false', reason: 'never both off');
  });

  testWidgets('"Stop" in a message stops that place at once, with an undo', (tester) async {
    final app = TestApp(language: 'uz');
    app.places.watches[1] = app.places.watches[1]!.copyWith(watching: true);
    await app.launch(tester);
    openSection(
      tester.element(find.byType(HomeScreen)),
      const Feature(id: 'notifications', emoji: '🔔', path: 'pages/notifications/notifications.html?stop=place:1'),
      app.services,
    );
    await tester.pumpAndSettle();
    expect(app.places.watches[1]!.watching, isFalse);
    expect(find.text('Bu joy bo‘yicha xabarlar to‘xtatildi.'), findsOneWidget);
    await tester.tap(find.text('Qaytarish'));
    await tester.pumpAndSettle();
    expect(app.places.watches[1]!.watching, isTrue);
    expect(find.text('Ansan Markaziy Masjidi'), findsOneWidget, reason: 'back in the list');
  });
}
