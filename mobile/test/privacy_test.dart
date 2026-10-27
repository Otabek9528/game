import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/account/privacy_screen.dart';
import 'package:muslim_vegukin/features/account/privacy_text.dart';

import 'support/fakes.dart';

/// [text] as a reader sees it: no markup, single spaces.
String _plain(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  test('the app says what the web page says, in each language (else: python3 tool/privacy_text.py)', () {
    final page = File('store/privacy.html').readAsStringSync();
    for (final language in ['uz', 'en', 'ru']) {
      final section = RegExp('<section id="$language">(.*?)</section>', dotAll: true).firstMatch(page)![1]!;
      final web = _plain(section
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
          .replaceAll(RegExp(r'</?(b|a)\b[^>]*>'), '') // inline: part of the sentence
          .replaceAll(RegExp(r'<[^>]+>'), ' '));
      final app = _plain([
        for (final line in privacyText[language]!)
          if (!line.startsWith('[')) line.replaceFirst(RegExp(r'^(#+|_|-) '), '') else ' ',
      ].join(' ').replaceAll('**', '').replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'), (m) => m[1]!));
      expect(app, web, reason: language);
    }
  });

  testWidgets('in the app’s language; the contact opens Telegram', (tester) async {
    final app = TestApp(language: 'uz');
    await app.launch(tester);
    await pushPage(tester, PrivacyScreen(services: app.services));
    await tester.pumpAndSettle();
    expect(find.text('Muslim Vegukin — Maxfiylik siyosati'), findsOneWidget);
    expect(find.text('Akkauntni o‘chirish'), findsNothing, reason: 'further down');

    await tester.scrollUntilVisible(find.text('Akkauntni o‘chirish'), 300, scrollable: find.byType(Scrollable).last);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('@otabeksattarov').first);
    expect(app.links.last, Uri.parse('https://t.me/otabeksattarov'));
  });
}
