import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/account.dart';
import 'package:muslim_vegukin/core/app_language.dart';
import 'package:muslim_vegukin/features/account/account_screen.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';

import 'support/fakes.dart';

AccountController controller(MemoryStore store, FakeAccounts accounts, {FakePush? push, AppLanguage language = AppLanguage.uz}) =>
    AccountController(
      store: store,
      source: accounts,
      push: push ?? FakePush(),
      google: FakeGoogle(),
      language: () => language,
    );

Future<TestApp> openAccountScreen(WidgetTester tester, {String language = 'en', TestApp? app}) async {
  app ??= TestApp(language: language);
  await app.launch(tester);
  final tooltip = switch (language) { 'uz' => 'Hisob', 'ru' => 'Аккаунт', _ => 'Account' };
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
  expect(find.byType(AccountScreen), findsOneWidget);
  return app;
}

/// The waiting screen's spinner never settles: step time instead.
Future<void> settleWaiting(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Top to bottom, the sign-in buttons on screen.
List<String> buttons(WidgetTester tester, List<String> labels) {
  final shown = [for (final l in labels) if (find.text(l).evaluate().isNotEmpty) l];
  return shown..sort((a, b) => tester.getTopLeft(find.text(a)).dy.compareTo(tester.getTopLeft(find.text(b)).dy));
}

void main() {
  group('the account', () {
    test('made once, on the first launch; the same one after', () async {
      final store = MemoryStore();
      final accounts = FakeAccounts();
      final first = controller(store, accounts);
      await first.ensure();
      expect(first.user!.signedIn, isFalse);
      expect(first.user!.id, lessThan(-9000000000000));
      expect(first.authHeaders, {'Authorization': 'Bearer token-1'});

      final again = controller(store, accounts);
      expect(again.user!.id, first.user!.id, reason: 'known at once, from the phone');
      await again.ensure();
      expect(accounts.devices.length, 1, reason: 'no second account');
    });

    test('offline at first: made on the next try; a lost session starts again', () async {
      final store = MemoryStore();
      final accounts = FakeAccounts()..fail = true;
      final c = controller(store, accounts);
      await c.ensure();
      expect(c.user, isNull);
      expect(c.authHeaders, isEmpty);
      accounts.fail = false;
      await c.ensure();
      expect(c.user, isNotNull);

      accounts.users.clear();
      await controller(store, accounts).ensure();
      expect(accounts.users.keys, ['token-2']);
    });

    test('the push token and the language reach the server', () async {
      var language = AppLanguage.uz;
      final accounts = FakeAccounts();
      final c = AccountController(
        store: MemoryStore(),
        source: accounts,
        push: FakePush()..token = 'fcm-1',
        google: FakeGoogle(),
        language: () => language,
      );
      await c.startPush();
      await c.startPush();
      expect(c.pushAllowed, isTrue);
      expect(accounts.devices.last, ('token-1', 'fcm-1', 'uz'));
      language = AppLanguage.ru;
      await c.languageChanged();
      expect(accounts.devices.last, ('token-1', null, 'ru'));
    });
  });

  group('the app', () {
    testWidgets('an account from the first launch; push after the permission questions', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      expect(app.accounts.users, hasLength(1));
      expect(app.push.starts, 1);
      expect(app.accounts.devices.last.$2, 'push-token');
    });

    testWidgets('a tapped notification opens its page; one arriving in the app shows, and opens', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      app.push.open({'url': 'https://vegukin-twa.pages.dev/pages/places/places-detail.html?id=8&type=restaurant'});
      app.push.open({'kind': 'hikorea'});
      app.push.open({});
      expect(app.opened.ids, ['restaurant', 'hikorea']);

      app.push.arrive('Kebab House', 'Now open', {'url': 'https://x/pages/notifications/notifications.html'});
      await tester.pumpAndSettle();
      expect(find.text('Kebab House\nNow open'), findsOneWidget);
      await tester.tap(find.text('Open'));
      expect(app.opened.ids.last, 'notifications');
    });

    test('which page a notification opens', () {
      final place = featureForPush({'url': 'https://a/pages/places/places-detail.html?id=7&type=mosque'})!;
      expect(place.id, 'mosque');
      expect(place.path, 'pages/places/places-detail.html?id=7&type=mosque');
      expect(featureForPush({'url': 'https://a/pages/notifications/notifications.html'})!.id, 'notifications');
      expect(featureForPush({'url': 'https://www.hikorea.go.kr/'}), isNull);
    });
  });

  group('signing in', () {
    testWidgets('the ways in, WhatsApp first for non-Uzbeks, Telegram first for Uzbeks', (tester) async {
      await openAccountScreen(tester);
      expect(buttons(tester, ['Continue with WhatsApp', 'Continue with Google', 'Continue with Telegram']),
          ['Continue with WhatsApp', 'Continue with Google', 'Continue with Telegram']);
    });

    testWidgets('in Uzbek, Telegram first', (tester) async {
      await openAccountScreen(tester, language: 'uz');
      expect(buttons(tester, ['Telegram orqali kirish', 'WhatsApp orqali kirish', 'Google orqali kirish']),
          ['Telegram orqali kirish', 'WhatsApp orqali kirish', 'Google orqali kirish']);
    });

    testWidgets('WhatsApp: the bot opens, the app waits, and is signed in when Yes is tapped', (tester) async {
      final app = await openAccountScreen(tester);
      await tester.tap(find.text('Continue with WhatsApp'));
      await settleWaiting(tester);
      expect(app.links.last, Uri.parse('https://wa.me/821012345678?text=LOGIN%20CODE1'));
      expect(find.text('Tap “Yes, log in” in WhatsApp'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Tap “Yes, log in” in WhatsApp'), findsOneWidget, reason: 'still waiting');

      app.accounts.confirm('CODE1',
          const AppUser(id: -9000000000001, signedIn: true, provider: 'whatsapp', name: 'Rahim', detail: '+821098765432'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Rahim'), findsOneWidget);
      expect(find.text('+821098765432'), findsOneWidget);
      expect(find.text('Signed in with WhatsApp'), findsOneWidget);
      expect(app.account.signedIn, isTrue);
    });

    testWidgets('back from the bot: looked at straight away', (tester) async {
      final app = await openAccountScreen(tester);
      await tester.tap(find.text('Continue with Telegram'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1', const AppUser(id: 555000111, signedIn: true, provider: 'telegram', name: 'Aziz'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Signed in with Telegram'), findsOneWidget);
    });

    testWidgets('cancelled in the bot: said so, and the ways in are back', (tester) async {
      final app = await openAccountScreen(tester);
      await tester.tap(find.text('Continue with Telegram'));
      await settleWaiting(tester);
      app.accounts.cancel('CODE1');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('That timed out or was cancelled. Please try again.'), findsOneWidget);
      expect(find.text('Continue with Telegram'), findsOneWidget);
    });

    testWidgets('Google: the picker, then signed in; closing the picker changes nothing', (tester) async {
      final app = await openAccountScreen(tester);
      app.google.answer = null;
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(app.account.signedIn, isFalse);
      expect(find.text('That didn’t work. Check your connection and try again.'), findsNothing);

      app.google.answer = 'google-id-token';
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('rahim@example.com'), findsOneWidget);
      expect(find.text('You’re signed in'), findsOneWidget);
    });

    testWidgets('offline: said so', (tester) async {
      final app = await openAccountScreen(tester);
      app.accounts.fail = true;
      await tester.tap(find.text('Continue with WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('That didn’t work. Check your connection and try again.'), findsOneWidget);
    });

    testWidgets('for a section that works through Telegram: Telegram alone, and why', (tester) async {
      final app = TestApp(language: 'uz');
      await app.launch(tester);
      final context = tester.element(find.byType(Scaffold).first);
      final result = askToSignIn(context, app.services, telegramOnly: true);
      await tester.pumpAndSettle();
      expect(find.textContaining('Bu bo‘lim Telegram orqali ishlaydi'), findsOneWidget);
      expect(find.text('Telegram orqali kirish'), findsOneWidget);
      expect(find.text('WhatsApp orqali kirish'), findsNothing);
      await tester.tap(find.text('Telegram orqali kirish'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1', const AppUser(id: 555000111, signedIn: true, provider: 'telegram', name: 'Aziz'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });
  });

  group('signed in', () {
    Future<TestApp> signedIn(WidgetTester tester, {String provider = 'whatsapp'}) async {
      final app = await openAccountScreen(tester);
      await tester.tap(find.text(provider == 'telegram' ? 'Continue with Telegram' : 'Continue with WhatsApp'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1', AppUser(id: provider == 'telegram' ? 555000111 : -9000000000001,
          signedIn: true, provider: provider, name: 'Rahim'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('signing out: this phone starts again as nobody in particular', (tester) async {
      final app = await signedIn(tester);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(app.account.signedIn, isFalse);
      expect(find.text('Continue with WhatsApp'), findsOneWidget);
    });

    testWidgets('deleting: asked first, then gone, and a new empty account', (tester) async {
      final app = await signedIn(tester, provider: 'telegram');
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This includes those made in the Telegram bot.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.accounts.deleted, isEmpty);

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(app.accounts.deleted, ['token-1']);
      expect(app.account.signedIn, isFalse);
      expect(app.account.authHeaders, {'Authorization': 'Bearer token-2'});
      expect(find.text('Account deleted'), findsOneWidget);
    });
  });

  testWidgets('notifications off: said so, with the way to the settings', (tester) async {
    final app = TestApp(language: 'en');
    app.push.allowed = false;
    await openAccountScreen(tester, app: app);
    expect(find.text('Notifications are off. Turn them on in settings.'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    expect(app.permissions.settingsOpened, 1);
  });
}
