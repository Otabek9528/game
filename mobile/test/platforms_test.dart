import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/support/platforms_sheet.dart';

import 'support/fakes.dart';

void main() {
  group('the project on its other platforms', () {
    testWidgets('the home screen\'s emblem opens them; each opens its own app', (tester) async {
      final app = TestApp(language: 'uz');
      await app.launch(tester);
      await tester.tap(find.bySemanticsLabel('Muslim Vegukin: boshqa platformalar'));
      await tester.pumpAndSettle();
      expect(find.byType(PlatformsSheet), findsOneWidget);
      expect(find.text('Boshqa platformalar'), findsOneWidget);

      await tester.tap(find.text('Telegram bot'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://t.me/muslim_vegukin_bot'));

      await tester.tap(find.text('WhatsApp bot'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://wa.me/821081174783?text=start'), reason: '"start" typed in, ready to send');

      await tester.tap(find.text('Telegram guruh'));
      await tester.pumpAndSettle();
      expect(app.links.last, Uri.parse('https://t.me/MuslimVegukin'));

      expect(app.activity.actions, containsAll(['platforms', 'platforms:telegram_bot', 'platforms:whatsapp_bot', 'platforms:group']));
    });

    testWidgets('shared in one message: the app and every other way in', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      await tester.tap(find.bySemanticsLabel('Muslim Vegukin on other platforms'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Share'));
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      final text = app.shared.single;
      for (final link in [
        'https://play.google.com/store/apps/details?id=com.muslimVegukin.myapp',
        'https://t.me/muslim_vegukin_bot',
        'https://wa.me/821081174783?text=start',
        'https://t.me/MuslimVegukin',
      ]) {
        expect(text, contains(link));
      }
    });

    testWidgets('also from the account page', (tester) async {
      final app = TestApp(language: 'ru');
      await app.launch(tester);
      await tester.tap(find.byTooltip('Аккаунт'));
      await tester.pumpAndSettle();
      final row = find.text('Другие платформы');
      await tester.scrollUntilVisible(row, 150, scrollable: find.byType(Scrollable).last);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(PlatformsSheet), findsOneWidget);
    });

    testWidgets('fits a small phone with large text, in Russian', (tester) async {
      final app = TestApp(language: 'ru');
      await app.launch(tester, screen: const Size(360, 640), textScale: 1.6);
      await tester.tap(find.bySemanticsLabel('Muslim Vegukin: другие платформы'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Поделиться'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
