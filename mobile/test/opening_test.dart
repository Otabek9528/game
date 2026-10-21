import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/home/home_screen.dart';
import 'package:muslim_vegukin/features/opening/opening.dart';

import 'support/fakes.dart';

final opening = find.byKey(const ValueKey('opening'));

void main() {
  testWidgets('plays over the first screen at launch, then the app is all there is', (tester) async {
    await TestApp(language: 'en').launch(tester, settle: false);
    await tester.pump();
    expect(opening, findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget, reason: 'loading behind it');

    await tester.pump(Opening.duration ~/ 2);
    expect(opening, findsOneWidget);
    await tester.pumpAndSettle();
    expect(opening, findsNothing);
    await tester.tap(find.byTooltip('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsWidgets);
  });

  testWidgets('a tap skips to its end', (tester) async {
    await TestApp(language: 'en').launch(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(opening);
    // Its fading out, a fifth of it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(opening, findsNothing);
  });

  testWidgets('none when the phone has animations turned off', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await TestApp(language: 'en').launch(tester, settle: false);
    await tester.pump();
    expect(opening, findsNothing);
  });

  testWidgets('also over the language screen of a first launch', (tester) async {
    await TestApp().launch(tester, settle: false);
    await tester.pump();
    expect(opening, findsOneWidget);
    await tester.pumpAndSettle();
    expect(opening, findsNothing);
  });
}
