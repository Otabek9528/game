import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/account/account_screen.dart';
import 'package:muslim_vegukin/features/prayers/prayers_screen.dart';

import 'support/fakes.dart';

/// A sheet that may grow to the whole screen stops under the status bar: on
/// an iPhone its handle and title were behind the notch when the text was
/// large (the sign-in sheet's top was at 0).
void main() {
  const statusBar = 59.0;

  Future<TestApp> launchSmall(WidgetTester tester) async {
    final app = TestApp(language: 'ru');
    await app.launch(tester, screen: const Size(360, 640), textScale: 1.6);
    tester.view
      ..padding = const FakeViewPadding(top: statusBar * 3, bottom: 34 * 3)
      ..viewPadding = const FakeViewPadding(top: statusBar * 3, bottom: 34 * 3);
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('the sign-in sheet, a small phone, large text', (tester) async {
    final app = await launchSmall(tester);
    await pushPage(tester, AccountScreen(services: app.services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(BottomSheet)).dy, greaterThanOrEqualTo(statusBar));
  });

  testWidgets('the prayer settings sheet, a small phone, large text', (tester) async {
    final app = await launchSmall(tester);
    await pushPage(tester, PrayersScreen(services: app.services));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(BottomSheet)).dy, greaterThanOrEqualTo(statusBar));
  });
}
