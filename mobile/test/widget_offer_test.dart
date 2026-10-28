import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/prayers/prayers_screen.dart';
import 'package:muslim_vegukin/features/widget/widget_offer.dart';

import 'account_test.dart' show tapScrolled;
import 'support/fakes.dart';

/// The widget channel as a phone would answer it; [calls] lists what the app asked.
class FakeWidgetChannel {
  FakeWidgetChannel(WidgetTester tester, {this.offer, this.placed = const [], this.pinned = true}) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('vegukin/widget'), (call) async {
      calls.add(call);
      return switch (call.method) {
        'offer' => offer,
        'placed' => placed,
        'pin' => pinned,
        'takeLaunchAction' => _take(),
        _ => null,
      };
    });
  }

  String? offer;
  List<String> placed;
  bool pinned;
  String? launchAction;
  final calls = <MethodCall>[];

  String? _take() {
    final action = launchAction;
    launchAction = null;
    return action;
  }

  Iterable<MethodCall> named(String method) => calls.where((c) => c.method == method);
}

Future<void> openPrayers(WidgetTester tester, TestApp app) async {
  await pushPage(tester, PrayersScreen(services: app.services));
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('the offer on the prayers page', () {
    testWidgets('Android, no widget yet: a size picked, and the launcher asked to add it', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final phone = FakeWidgetChannel(tester, offer: 'pin');
      await openPrayers(tester, app);
      expect(find.text('Prayer times on your home screen'), findsOneWidget);

      await tester.tap(find.text('Add to home screen'));
      await tester.pumpAndSettle();
      expect(find.text('Large · 4×2'), findsOneWidget);
      expect(find.text('Small · 2×2'), findsOneWidget);
      await tester.tap(find.text('Large · 4×2'));
      await tester.pumpAndSettle();
      expect(phone.named('pin').single.arguments, 'large');
      expect(app.activity.actions, contains('widget_pin_large'));
      expect(find.text('Large · 4×2'), findsNothing, reason: 'the sheet makes way for the launcher’s dialog');

      // Back from the dialog with the widget placed: the offer goes.
      phone.placed = ['large'];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Prayer times on your home screen'), findsNothing);
    });

    testWidgets('a launcher that says no: how to add it by hand', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      FakeWidgetChannel(tester, offer: 'pin', pinned: false);
      await openPrayers(tester, app);
      await tester.tap(find.text('Add to home screen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Small · 2×2'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Widgets → Muslim Vegukin'), findsOneWidget);
    });

    testWidgets('not offered: a widget already there, or nothing the phone can do', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final phone = FakeWidgetChannel(tester, offer: 'pin', placed: ['small']);
      await openPrayers(tester, app);
      expect(find.text('Prayer times on your home screen'), findsNothing);
      await back(tester);

      phone
        ..offer = null
        ..placed = [];
      await openPrayers(tester, app);
      expect(find.text('Prayer times on your home screen'), findsNothing);
    });

    testWidgets('closed, it stays closed', (tester) async {
      final app = TestApp(language: 'uz');
      await app.launch(tester);
      FakeWidgetChannel(tester, offer: 'pin');
      await openPrayers(tester, app);
      expect(find.text('Namoz vaqtlari bosh ekraningizda'), findsOneWidget);
      await tester.tap(find.byTooltip('Hozir emas'));
      await tester.pumpAndSettle();
      expect(find.text('Namoz vaqtlari bosh ekraningizda'), findsNothing);
      await back(tester);
      await openPrayers(tester, app);
      expect(find.text('Namoz vaqtlari bosh ekraningizda'), findsNothing);
    });

    testWidgets('iPhone: how to add it, since apps can’t', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final app = TestApp(language: 'ru');
        await app.launch(tester);
        final phone = FakeWidgetChannel(tester, offer: 'guide');
        await openPrayers(tester, app);
        await tester.tap(find.text('Добавить на главный экран'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Найдите Muslim Vegukin'), findsOneWidget);
        expect(app.activity.actions, contains('widget_guide'));
        expect(phone.named('pin'), isEmpty);
        await tester.tap(find.text('Понятно'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Найдите Muslim Vegukin'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  testWidgets('Account: the widget row, where the phone can add one', (tester) async {
    final app = TestApp(language: 'en');
    await app.launch(tester);
    final phone = FakeWidgetChannel(tester, offer: 'pin', placed: ['large']);
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tapScrolled(tester, find.text('Home-screen widget'));
    expect(find.text('Large · 4×2'), findsOneWidget, reason: 'another can be added, one there or not');
    await tester.tap(find.text('Small · 2×2'));
    await tester.pumpAndSettle();
    expect(phone.named('pin').single.arguments, 'small');
  });

  group('counting the widgets', () {
    testWidgets('Android: the widgets are told where to send and as whom', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final phone = FakeWidgetChannel(tester);
      await app.services.homeWidget.track(app.activity, app.store, DateTime(2026, 10, 28, 9));
      final args = phone.named('track').single.arguments as Map;
      expect(args['url'], 'https://vegukin-api.duckdns.org/api/log-interaction');
      expect(args['user_id'], -1234567890);
      expect(args['username'], 'Android app');
    });

    testWidgets('iPhone: the app reports the placed widgets, once a day', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final app = TestApp(language: 'en');
        await app.launch(tester);
        FakeWidgetChannel(tester, placed: ['lock', 'small']);
        final widget = app.services.homeWidget;
        await widget.track(app.activity, app.store, DateTime(2026, 10, 28, 9));
        await widget.track(app.activity, app.store, DateTime(2026, 10, 28, 21));
        expect(app.activity.actions.where((a) => a.startsWith('widget_')), ['widget_lock', 'widget_small']);
        await widget.track(app.activity, app.store, DateTime(2026, 10, 29, 7));
        expect(app.activity.actions.where((a) => a.startsWith('widget_')).length, 4, reason: 'a new day');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a widget tapped: counted; on iPhone it opens the prayers page', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final phone = FakeWidgetChannel(tester);
      Future<void> tapped(String action) async {
        phone.launchAction = action;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
      }

      await tapped('widget');
      expect(app.activity.actions.where((a) => a == 'widget_tap').length, 1);
      expect(find.byType(PrayersScreen), findsNothing);
      await tapped('widget_prayers');
      expect(app.activity.actions.where((a) => a == 'widget_tap').length, 2);
      expect(find.byType(PrayersScreen), findsOneWidget);
    });
  });

  testWidgets('the previews are in the app', (tester) async {
    for (final name in ['large', 'small']) {
      expect(await rootBundle.load('assets/widget/$name.webp'), isNotNull, reason: name);
    }
    await tester.pumpWidget(MaterialApp(home: widgetPreview('small')));
    expect(find.byType(Image), findsOneWidget);
  });
}
