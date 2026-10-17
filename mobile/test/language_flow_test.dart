import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayer/prayer_sources.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('first launch asks for a language, pre-selecting the phone one',
      (tester) async {
    final app = TestApp();
    await app.launch(tester, device: const [Locale('ru')]);

    expect(find.text('O‘zbekcha'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('На каком языке продолжим?'), findsOneWidget);
    expect(find.text('Продолжить'), findsOneWidget);
    // Nothing is saved until the user confirms.
    expect(app.languageStore.value, isNull);
  });

  testWidgets('first launch never asks for location on its own', (tester) async {
    final app = TestApp(location: FakeLocation(access: LocationAccess.denied));
    await app.launch(tester);

    expect(app.location.requests, 0);
  });

  testWidgets('each option describes itself in its own language',
      (tester) async {
    await TestApp().launch(tester);

    expect(find.text('Barcha bo‘limlar mavjud'), findsOneWidget);
    expect(find.text('Часть разделов пока только на узбекском'), findsOneWidget);
    expect(find.text('Some sections are in Uzbek only for now'), findsOneWidget);
  });

  testWidgets('picking a language previews it, Continue saves it',
      (tester) async {
    final app = TestApp();
    await app.launch(tester);
    expect(find.text('Davom etish'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Which language suits you?'), findsOneWidget);
    expect(find.text('Davom etish'), findsNothing);
    expect(app.languageStore.value, isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(app.languageStore.value, 'en');
    expect(find.text('Business Directory'), findsOneWidget);
  });

  testWidgets('a saved language skips the picker', (tester) async {
    await TestApp(language: 'ru').launch(tester);

    expect(find.text('Русский'), findsNothing);
    expect(find.text('Бизнес-каталог'), findsOneWidget);
  });

  testWidgets('the language can be changed later from home', (tester) async {
    final app = TestApp(language: 'en');
    await app.launch(tester);

    await tester.tap(find.byTooltip('Change language'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('O‘zbekcha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(app.languageStore.value, 'uz');
    expect(find.text('Biznes Katalogi'), findsOneWidget);
  });

  testWidgets('fits a small phone with very large text', (tester) async {
    final app = TestApp();
    await app.launch(tester, screen: const Size(320, 568), textScale: 1.8);

    // Overflow would have failed the test already; the button must still be
    // reachable by scrolling.
    await tester.scrollUntilVisible(
      find.text('Davom etish'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    expect(app.languageStore.value, 'uz');
  });

  testWidgets('still usable with the phone turned sideways', (tester) async {
    final app = TestApp();
    await app.launch(tester, screen: const Size(891, 411));

    await tester.scrollUntilVisible(
      find.text('Davom etish'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    expect(app.languageStore.value, 'uz');
  });
}
