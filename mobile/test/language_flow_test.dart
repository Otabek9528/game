import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/app.dart';
import 'package:muslim_vegukin/core/locale_controller.dart';

class MemoryStore implements LanguageStore {
  MemoryStore([this.value]);

  String? value;

  @override
  String? read() => value;

  @override
  Future<void> write(String code) async => value = code;
}

/// Starts the app on a phone-sized screen (by default 411×891, a Pixel 7).
Future<MemoryStore> launch(
  WidgetTester tester, {
  String? saved,
  List<Locale> device = const [Locale('ko')],
  Size screen = const Size(411, 891),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = screen * 3
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final store = MemoryStore(saved);
  await tester.pumpWidget(VegukinApp(
    controller: LocaleController(store),
    deviceLocales: device,
  ));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('first launch asks for a language, pre-selecting the phone one',
      (tester) async {
    final store = await launch(tester, device: const [Locale('ru')]);

    expect(find.text('O‘zbekcha'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('На каком языке продолжим?'), findsOneWidget);
    expect(find.text('Продолжить'), findsOneWidget);
    // Nothing is saved until the user confirms.
    expect(store.value, isNull);
  });

  testWidgets('each option describes itself in its own language',
      (tester) async {
    await launch(tester);

    expect(find.text('Barcha bo‘limlar mavjud'), findsOneWidget);
    expect(find.text('Часть разделов пока только на узбекском'), findsOneWidget);
    expect(find.text('Some sections are in Uzbek only for now'), findsOneWidget);
  });

  testWidgets('picking a language previews it, Continue saves it',
      (tester) async {
    final store = await launch(tester);
    expect(find.text('Davom etish'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Which language suits you?'), findsOneWidget);
    expect(find.text('Davom etish'), findsNothing);
    expect(store.value, isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(store.value, 'en');
    expect(find.text('The home screen is the next step.'), findsOneWidget);
  });

  testWidgets('a saved language skips the picker', (tester) async {
    await launch(tester, saved: 'ru');

    expect(find.text('Русский'), findsNothing);
    expect(find.text('Главная'), findsOneWidget);
  });

  testWidgets('the language can be changed later from home', (tester) async {
    final store = await launch(tester, saved: 'en');

    await tester.tap(find.text('Change language'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('O‘zbekcha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(store.value, 'uz');
    expect(find.text('Bosh sahifa'), findsOneWidget);
  });

  testWidgets('fits a small phone with very large text', (tester) async {
    await launch(tester, screen: const Size(320, 568), textScale: 1.8);

    // Overflow would have failed the test already; the button must still be
    // reachable by scrolling.
    await tester.scrollUntilVisible(
      find.text('Davom etish'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    expect(find.text('Bosh sahifa'), findsOneWidget);
  });

  testWidgets('still usable with the phone turned sideways', (tester) async {
    final store = await launch(tester, screen: const Size(891, 411));

    await tester.scrollUntilVisible(
      find.text('Davom etish'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    expect(store.value, 'uz');
  });
}
