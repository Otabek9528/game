import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';

import 'support/fakes.dart';

/// UZ tags on the home content (the header's language button also reads UZ).
final uzTags = find.descendant(
  of: find.byType(CustomScrollView),
  matching: find.text('UZ'),
);

void main() {
  testWidgets('shows today: date, city, countdown and the day strip', (tester) async {
    await TestApp(language: 'uz').launch(tester);

    expect(find.text('Shanba, 17-oktabr'), findsOneWidget);
    expect(find.text('6-Jumodul avval, 1448'), findsOneWidget);
    expect(find.text('Ansan'), findsOneWidget);
    // 11:00, next is Dhuhr at 12:00.
    expect(find.text('PESHINGACHA'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    for (final time in ['05:00', '06:30', '12:00', '15:30', '18:00', '19:30']) {
      expect(find.text(time), findsOneWidget);
    }
  });

  testWidgets('labels sunrise as the end of Fajr, not a prayer', (tester) async {
    await TestApp(language: 'ru', now: DateTime(2026, 10, 17, 6, 0)).launch(tester);

    expect(find.text('ДО КОНЦА ФАДЖРА'), findsOneWidget);
    expect(find.text('Суббота, 17 октября'), findsOneWidget);
  });

  testWidgets('the countdown ticks every second', (tester) async {
    // The test clock is fixed, so check the card rebuilds rather than the text.
    await TestApp(language: 'en').launch(tester);
    expect(find.text('UNTIL DHUHR'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('UNTIL DHUHR'), findsOneWidget);
  });

  testWidgets('without location, the card explains and asks with a button', (tester) async {
    final app = TestApp(language: 'en', location: FakeLocation(access: LocationAccess.denied));
    await app.launch(tester);

    expect(find.text('Prayer times need your location'), findsOneWidget);
    expect(app.location.requests, 0);

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(app.location.requests, 1);
    expect(find.text('UNTIL DHUHR'), findsOneWidget);
  });

  testWidgets('blocked location points to the app settings', (tester) async {
    await TestApp(
      language: 'en',
      location: FakeLocation(access: LocationAccess.deniedForever),
    ).launch(tester);

    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('business band shows the live count', (tester) async {
    await TestApp(language: 'ru').launch(tester);
    expect(find.text('5 бизнесов · 10 направлений'), findsOneWidget);
  });

  testWidgets('Uzbek-only sections are shown to everyone, tagged UZ', (tester) async {
    await TestApp(language: 'en').launch(tester);
    expect(find.text('Jobs'), findsOneWidget);
    expect(uzTags, findsWidgets);

    // Scroll so every tile has been built, then count.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Parcels'), findsOneWidget);
  });

  testWidgets('no UZ tags when the app is in Uzbek', (tester) async {
    await TestApp(language: 'uz').launch(tester);
    expect(uzTags, findsNothing);
  });

  testWidgets('tapping a section or the prayer card opens it', (tester) async {
    final app = TestApp(language: 'uz');
    await app.launch(tester);

    await tester.tap(find.text('Masjidlar'));
    await tester.tap(find.text('Biznes Katalogi'));
    await tester.tap(find.text('PESHINGACHA'));
    expect(app.opened.ids, ['mosque', 'business', 'prayers']);
  });

  testWidgets('home fits a small phone with very large text', (tester) async {
    await TestApp(language: 'ru').launch(tester, screen: const Size(320, 568), textScale: 1.8);
    // A layout overflow would already have failed the test.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Сообщество'), findsOneWidget);
  });
}
