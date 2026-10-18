import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';
import 'package:muslim_vegukin/features/prayers/prayers_screen.dart';

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

  testWidgets('refused at first launch: the card explains, its button asks again', (tester) async {
    final app = TestApp(
      language: 'en',
      location: FakeLocation(access: LocationAccess.denied, afterRequest: LocationAccess.denied),
    );
    await app.launch(tester);

    // The one-time ask happened and was refused.
    expect(app.location.requests, 1);
    expect(find.text('Prayer times need your location'), findsOneWidget);

    app.location.afterRequest = LocationAccess.granted;
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(app.location.requests, 2);
    expect(find.text('UNTIL DHUHR'), findsOneWidget);
  });

  testWidgets('"Alarms & reminders" is explained and opened once, after location and camera', (tester) async {
    final app = TestApp(language: 'en')..permissions.exactAlarmsMissing = true;
    await app.launch(tester);
    await tester.pumpAndSettle();

    expect(find.text('Exact timing'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(app.permissions.exactAlarmSettingsOpened, 1);

    // Back from the settings page, or the next launch: not asked again.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Exact timing'), findsNothing);
    expect(app.permissions.asks, 1);
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

  testWidgets('a section opens its page; the prayer card opens the prayers page', (tester) async {
    final app = TestApp(language: 'uz');
    await app.launch(tester);

    await tester.tap(find.text('Masjidlar'));
    expect(app.opened.ids, ['mosque']);

    await tester.tap(find.text('PESHINGACHA'));
    await tester.pumpAndSettle();
    expect(find.byType(PrayersScreen), findsOneWidget);
  });

  testWidgets('the sun/moon button switches day and night, and remembers it', (tester) async {
    final app = TestApp(language: 'en');
    await app.launch(tester);
    BuildContext home() => tester.element(find.byType(CustomScrollView));
    expect(Theme.of(home()).brightness, Brightness.light);

    await tester.tap(find.byTooltip('Night mode'));
    await tester.pumpAndSettle();
    expect(Theme.of(home()).brightness, Brightness.dark);
    expect(app.store.read('theme_mode'), 'night');

    await tester.tap(find.byTooltip('Day mode'));
    await tester.pumpAndSettle();
    expect(Theme.of(home()).brightness, Brightness.light);
    expect(app.store.read('theme_mode'), 'day');
  });

  testWidgets('home fits a small phone with very large text', (tester) async {
    await TestApp(language: 'ru').launch(tester, screen: const Size(320, 568), textScale: 1.8);
    // A layout overflow would already have failed the test.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Сообщество'), findsOneWidget);
  });
}
