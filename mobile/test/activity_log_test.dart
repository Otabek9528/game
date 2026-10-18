import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/core/activity_log.dart';

import 'support/fakes.dart';

void main() {
  group('activity log', () {
    test('sent like the web app, with the platform after the action', () async {
      final sent = <http.Request>[];
      final store = MemoryStore();
      final log = HttpActivityLog(
        store,
        client: MockClient((request) async {
          sent.add(request);
          return http.Response('{"success":true}', 200);
        }),
        platform: TargetPlatform.android,
      );
      log.log('qibla');
      log.log('scanner_found', '8801234567890');
      await pumpEventQueue();

      expect(sent.map((r) => r.url.toString()), everyElement('https://vegukin-api.duckdns.org/api/log-interaction'));
      expect(sent.first.headers['Content-Type'], startsWith('application/json'));
      final bodies = [for (final r in sent) jsonDecode(r.body) as Map<String, dynamic>];
      expect(bodies.map((b) => b['action']), ['qibla_apk', 'scanner_found_apk:8801234567890']);
      expect(bodies.map((b) => b['username']), everyElement('Android app'));
    });

    test('one id per install: negative, so never a Telegram user', () {
      final store = MemoryStore();
      final first = HttpActivityLog(store, platform: TargetPlatform.android).installId;
      expect(first, isNegative);
      expect(HttpActivityLog(store, platform: TargetPlatform.android).installId, first);
      expect(HttpActivityLog(MemoryStore(), platform: TargetPlatform.android).installId, isNot(first));
    });

    test('on an iPhone: _ios', () {
      final log = HttpActivityLog(MemoryStore(), platform: TargetPlatform.iOS);
      expect(log.payload('parcel')['action'], 'parcel_ios');
      expect(log.payload('store_opened', 'GS25')['action'], 'store_opened_ios:GS25');
    });

    test('no connection: nothing thrown', () async {
      final log = HttpActivityLog(
        MemoryStore(),
        client: MockClient((_) async => throw http.ClientException('offline')),
        platform: TargetPlatform.android,
      );
      log.log('links');
      await pumpEventQueue();
    });
  });

  testWidgets('each section counted when opened from home', (tester) async {
    final app = TestApp(language: 'uz');
    await app.launch(tester);
    await tester.scrollUntilVisible(find.text('Foydali linklar'), 200);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foydali linklar'));
    await tester.pumpAndSettle();
    expect(app.activity.actions, ['links']);
  });
}
