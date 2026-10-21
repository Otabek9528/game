import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayers/day_view.dart';
import 'package:muslim_vegukin/features/prayers/prayers_screen.dart';
import 'package:muslim_vegukin/features/reminders/reminders.dart';

import 'support/fakes.dart';

Future<TestApp> openPrayers(WidgetTester tester, {String language = 'en'}) async {
  final app = TestApp(language: language);
  await app.launch(tester);
  await tester.tap(find.text('UNTIL DHUHR'));
  await tester.pumpAndSettle();
  expect(find.byType(PrayersScreen), findsOneWidget);
  return app;
}

void main() {
  group('the day\'s rows', () {
    final day = dayAt(DateTime(2026, 10, 17));

    test('between sunrise and Dhuhr nothing is open: Dhuhr is next and drawn filled', () {
      final rows = timelineRows(day, now: DateTime(2026, 10, 17, 11, 0));
      final dhuhr = rows.firstWhere((r) => r.slot == ReminderSlot.dhuhr);
      expect(rows.where((r) => r.active), isEmpty);
      expect(dhuhr.next && dhuhr.highlighted, isTrue);
      expect(rows.where((r) => r.past).map((r) => r.slot),
          [ReminderSlot.imsak, ReminderSlot.fajr, ReminderSlot.sunrise]);
    });

    test('after midnight Isha is still open and Fajr is next', () {
      final rows = timelineRows(day, now: DateTime(2026, 10, 17, 1, 0));
      expect(rows.firstWhere((r) => r.active).slot, ReminderSlot.isha);
      expect(rows.firstWhere((r) => r.next).slot, ReminderSlot.fajr);
    });

    test('another day has no current, next or passed rows', () {
      final rows = timelineRows(day);
      expect(rows.any((r) => r.active || r.next || r.past), isFalse);
      expect(rows.length, 7);
    });

    test('nafl windows follow the web page\'s offsets', () {
      final w = naflWindows(day);
      expect(w[Nafl.ishraq]!.text, '07:00 — 07:15');
      expect(w[Nafl.duha]!.text, '06:50 — 11:00');
      expect(w[Nafl.tahajjud]!.text, '02:10 — 05:00');
      expect(naflStatus(w[Nafl.tahajjud]!, DateTime(2026, 10, 17, 3, 35)).status, NaflStatus.active);
      expect(naflStatus(w[Nafl.duha]!, DateTime(2026, 10, 17, 11, 0)).status, NaflStatus.passed);
    });
  });

  testWidgets('the page shows today: countdown, timeline with chips, nafl', (tester) async {
    await openPrayers(tester);
    expect(find.text('Dhuhr'), findsWidgets);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('next'), findsOneWidget);
    expect(find.text('Iftar'), findsOneWidget);
    expect(find.text('Suhoor (ends)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Duha prayer'), 200);
    expect(find.text('Passed'), findsWidgets);
  });

  testWidgets('the date stepper moves a day and back to today', (tester) async {
    await openPrayers(tester);
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Next day'));
    await tester.pumpAndSettle();
    // The stepper, and the nafl statuses below it.
    expect(find.text('Tomorrow'), findsNWidgets(4));
    // Tomorrow has no "now" or "next".
    expect(find.text('next'), findsNothing);
    await tester.tap(find.text('Tomorrow').first);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('a bell opens that prayer\'s reminder; choices apply at once', (tester) async {
    final app = await openPrayers(tester);
    await tester.tap(find.bySemanticsLabel('Asr reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Today: 15:30 – 18:00'), findsOneWidget);

    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    expect(app.reminders.settings[ReminderSlot.asr].mode, ReminderMode.sound);

    await tester.tap(find.text('10 min after'));
    await tester.pumpAndSettle();
    expect(app.reminders.settings[ReminderSlot.asr].offset, 10);
    expect(find.text('15:40'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();
    expect(app.reminders.settings[ReminderSlot.asr].offset, 9);

    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsNothing);
    expect(find.text('+9'), findsOneWidget);
  });

  testWidgets('a reminder can\'t be set past the next time', (tester) async {
    final app = await openPrayers(tester);
    await tester.tap(find.bySemanticsLabel('Suhoor reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vibrate'));
    await tester.pumpAndSettle();
    // Suhoor ends 10 minutes before Fajr: "+10" and "+30" aren't offered.
    expect(find.text('10 min after'), findsNothing);
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
    }
    expect(app.reminders.settings[ReminderSlot.imsak].offset, 9);
  });

  testWidgets('the settings sheet changes the method', (tester) async {
    final app = await openPrayers(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karachi'));
    await tester.pumpAndSettle();
    expect(app.prayer.settings.method, '1');
    expect(find.text('Karachi  ·  Hanafi'), findsOneWidget);
  });
}
