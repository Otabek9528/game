import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/support/community_screen.dart';
import 'package:muslim_vegukin/features/support/donation_screen.dart';

import 'support/fakes.dart';

/// What the app put on the clipboard.
final copied = <String>[];

Future<TestApp> open(WidgetTester tester, String tile, {String language = 'uz'}) async {
  copied.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  final app = TestApp(language: language);
  await app.launch(tester);
  await tester.scrollUntilVisible(find.text(tile), 200);
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.tap(find.text(tile));
  await tester.pumpAndSettle();
  return app;
}

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  group('donation', () {
    testWidgets('why first, then the account: each detail copied with a tap', (tester) async {
      await open(tester, 'Qo‘llab-quvvatlash');
      expect(find.byType(DonationScreen), findsOneWidget);
      expect(find.text('KEB하나은행 (Hana Bank)'), findsOneWidget);
      expect(find.text('SATTAROV OTABEK'), findsOneWidget);

      await tapVisible(tester, find.text('Hisob raqamni nusxalash'));
      await tester.pump();
      expect(copied.last, '559-910261-05007');
      expect(find.text('Nusxa olindi!'), findsWidgets);
      await tester.pump(const Duration(seconds: 3));

      await tapVisible(tester, find.byTooltip('Ismni nusxalash'));
      await tester.pump();
      expect(copied.last, 'SATTAROV OTABEK');
      await tester.pumpAndSettle();
    });

    testWidgets('the banking apps on the phone open with the number copied', (tester) async {
      final app = await open(tester, 'Support us', language: 'en');
      await tester.scrollUntilVisible(find.text('Toss'), 200);
      expect(find.text('Hana 1Q'), findsOneWidget);
      expect(find.text('KakaoBank'), findsNothing, reason: 'not installed');
      await tapVisible(tester, find.text('Toss'));
      await tester.pumpAndSettle();
      expect(copied.last, '559-910261-05007');
      expect(app.system.opened, ['viva.republica.toss']);
    });

    testWidgets('no banking app: no such section', (tester) async {
      final app = TestApp(language: 'en');
      app.system.installed = [];
      await app.launch(tester);
      await tester.scrollUntilVisible(find.text('Support us'), 200);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Support us'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Collected funds will be used for'), 200);
      expect(find.text('Transfer in your bank app'), findsNothing);
    });

    testWidgets('the details shared', (tester) async {
      final app = await open(tester, 'Support us', language: 'en');
      await tapVisible(tester, find.byTooltip('Share the details'));
      expect(app.shared.single, contains('559-910261-05007'));
      expect(app.shared.single, contains('SATTAROV OTABEK'));
    });
  });

  group('community', () {
    testWidgets('join, always in reach', (tester) async {
      final app = await open(tester, 'Jamoa');
      expect(find.byType(CommunityScreen), findsOneWidget);
      expect(find.text('@MuslimVegukin\nFoydalanuvchilar jamiyati'), findsOneWidget);
      await tester.tap(find.text('Hoziroq qo‘shiling'));
      expect(app.links.last, Uri.parse('https://t.me/MuslimVegukin'));
    });

    testWidgets('a bug report comes as a template with the phone and app version', (tester) async {
      final app = await open(tester, 'Community', language: 'en');
      await tapVisible(tester, find.text('Bug reports'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Phone: samsung SM-S906N · Android 14'), findsOneWidget);
      await tester.tap(find.text('Copy and open the group'));
      await tester.pumpAndSettle();
      expect(copied.last, startsWith('🐛 Bug\nWhere: '));
      expect(copied.last, endsWith('App: 1.0.0 (1)'));
      expect(app.links.last, Uri.parse('https://t.me/MuslimVegukin'));
    });

    testWidgets('a new place too; closing the sheet sends nothing', (tester) async {
      final app = await open(tester, 'Community', language: 'en');
      await tapVisible(tester, find.text('Report new locations'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Type: mosque / restaurant / shop'), findsOneWidget);
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      expect(copied, isEmpty);
      expect(app.links, isEmpty);
    });

    testWidgets('rules shown; the link copied from the bar', (tester) async {
      await open(tester, 'Community', language: 'en');
      await tester.scrollUntilVisible(find.textContaining('Ads and sales announcements', findRichText: true), 300);
      expect(find.text('Messages violating rules will be deleted. If repeated, the user will be restricted from sending messages.'),
          findsOneWidget);
      await tapVisible(tester, find.byTooltip('Copy link'));
      await tester.pump();
      expect(copied.last, 'https://t.me/MuslimVegukin');
      await tester.pumpAndSettle();
    });
  });
}
