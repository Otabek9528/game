import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/core/account.dart';
import 'package:muslim_vegukin/core/push_reports.dart';
import 'package:muslim_vegukin/core/theme.dart';
import 'package:muslim_vegukin/features/account/rich_message.dart';

void main() {
  group('parseRichMessage', () {
    test('runs keep their formatting, quotes are their own blocks', () {
      final blocks = parseRichMessage(
        '<b>Salom <i>do\'st</i></b> &amp; <a href="https://x.org/a?b=1&amp;c=2">bu yer</a>\n'
        '<blockquote>Iqtibos <u>muhim</u></blockquote>\nOxiri <s>eski</s>',
      );
      expect(blocks, hasLength(3));
      expect(blocks[0].quote, isFalse);
      expect(blocks[0].runs, [
        const RichRun('Salom ', bold: true),
        const RichRun("do'st", bold: true, italic: true),
        const RichRun(' & '),
        const RichRun('bu yer', href: 'https://x.org/a?b=1&c=2'),
      ]);
      expect(blocks[1].quote, isTrue);
      expect(blocks[1].text, 'Iqtibos muhim');
      expect(blocks[1].runs.last, const RichRun('muhim', underline: true));
      expect(blocks[2].text, 'Oxiri eski');
      expect(blocks[2].runs.last.strike, isTrue);
    });

    test('lines stay, unknown tags show as written', () {
      final blocks = parseRichMessage('Bir\n\nIkki &lt;b&gt; <span>x</span>');
      expect(blocks.single.text, 'Bir\n\nIkki <b> <span>x</span>');
    });

    test('empty and broken input', () {
      expect(parseRichMessage(''), isEmpty);
      expect(parseRichMessage('</b>yolg\'iz</i>').single.runs.single, const RichRun("yolg'iz"));
    });
  });

  testWidgets('RichMessage shows the words and taps links', (tester) async {
    final tapped = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [VegukinPalette.light]),
        home: Scaffold(
          body: RichMessage(
            '<b>Muhim</b> xabar: <a href="https://example.org/t">taqvim</a>\n<blockquote>Eslatma</blockquote>',
            style: const TextStyle(fontSize: 16),
            onLink: tapped.add,
          ),
        ),
      ),
    );
    expect(find.textContaining('Muhim', findRichText: true), findsOneWidget);
    expect(find.textContaining('Eslatma', findRichText: true), findsOneWidget);
    final rich = tester.widget<SelectableText>(find.byType(SelectableText).first);
    final link = rich.textSpan!.children!.whereType<TextSpan>().firstWhere((s) => s.text == 'taqvim');
    (link.recognizer! as dynamic).onTap();
    expect(tapped, [Uri.parse('https://example.org/t')]);
    final bold = rich.textSpan!.children!.whereType<TextSpan>().firstWhere((s) => s.text == 'Muhim');
    expect(bold.style!.fontWeight, FontWeight.w700);
  });

  test('inbox items carry the formatted message', () {
    final item = InboxItem.fromJson({
      'id': 5,
      'title': 'T',
      'body': 'b',
      'text': 'Muhim',
      'html': '<b>Muhim</b>',
      'data': {'kind': 'campaign', 'c': 3, 'd': 41, 'k': 'abc'},
      'at': '2026-11-09T01:00:00Z',
    })!;
    expect(item.html, '<b>Muhim</b>');
    expect(item.data, {'kind': 'campaign', 'c': '3', 'd': '41', 'k': 'abc'});
    expect(InboxItem.fromJson({'id': 6, 'title': 'T', 'at': '2026-11-09T01:00:00Z'})!.html, isNull);
  });

  group('PushReports', () {
    const campaign = {'kind': 'campaign', 'd': '41', 'k': 'key-41'};

    test('sends the delivery, its key and what happened', () async {
      final sent = <Map<String, dynamic>>[];
      final reports = PushReports(
        client: MockClient((r) async {
          expect(r.url.path, '/api/app/push-event');
          sent.add(jsonDecode(r.body) as Map<String, dynamic>);
          return http.Response('{"success": true}', 200);
        }),
      );
      await reports.send(campaign, PushEvent.opened);
      await reports.send(campaign, PushEvent.clicked, link: 'https://example.org');
      expect(sent, [
        {'d': 41, 'k': 'key-41', 'e': 'opened'},
        {'d': 41, 'k': 'key-41', 'e': 'clicked', 'link': 'https://example.org'},
      ]);
    });

    test('other messages are never reported', () async {
      var calls = 0;
      final reports = PushReports(
        client: MockClient((r) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await reports.send({'kind': 'hikorea', 'd': '1', 'k': 'x'}, PushEvent.received);
      await reports.send({'kind': 'campaign', 'd': 'one', 'k': 'x'}, PushEvent.received);
      await reports.send({'kind': 'campaign', 'd': '1'}, PushEvent.received);
      expect(calls, 0);
    });

    test('tried once more when the server fails, not when it refuses', () async {
      var calls = 0;
      final failing = PushReports(
        retryAfter: Duration.zero,
        client: MockClient((r) async {
          calls++;
          return http.Response('', 503);
        }),
      );
      await failing.send(campaign, PushEvent.read);
      expect(calls, 2);
      calls = 0;
      final refusing = PushReports(
        retryAfter: Duration.zero,
        client: MockClient((r) async {
          calls++;
          return http.Response('', 403);
        }),
      );
      await refusing.send(campaign, PushEvent.read);
      expect(calls, 1);
    });
  });
}
