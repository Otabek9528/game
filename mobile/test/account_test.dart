import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/account.dart';
import 'package:muslim_vegukin/core/app_language.dart';
import 'package:muslim_vegukin/features/account/account_screen.dart';
import 'package:muslim_vegukin/features/account/inbox_message.dart';
import 'package:muslim_vegukin/features/account/inbox_screen.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_models.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_screen.dart';
import 'package:muslim_vegukin/features/hikorea/hikorea_watches.dart';
import 'package:muslim_vegukin/features/home/feature_catalog.dart';

import 'package:muslim_vegukin/features/places/place_detail.dart';

import 'package:muslim_vegukin/features/notifications/notifications_screen.dart';
import 'package:muslim_vegukin/features/notifications/notify_models.dart';
import 'package:muslim_vegukin/features/places/places_models.dart';
import 'package:muslim_vegukin/features/support/community_screen.dart';

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
  final tooltip = switch (language) { 'uz' => 'Akkaunt', 'ru' => 'Аккаунт', _ => 'Account' };
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
  expect(find.byType(AccountScreen), findsOneWidget);
  return app;
}

/// The account page, and its sign-in sheet open.
Future<TestApp> openSignIn(WidgetTester tester, {String language = 'en', TestApp? app}) async {
  app = await openAccountScreen(tester, language: language, app: app);
  await tester.tap(find.text(switch (language) { 'uz' => 'Kirish', 'ru' => 'Войти', _ => 'Sign in' }));
  await tester.pumpAndSettle();
  return app;
}

Future<void> tapScrolled(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 150, scrollable: find.byType(Scrollable).last);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The waiting screen's spinner never settles: step time instead.
Future<void> settleWaiting(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Taps the link [text] in the message's selectable text.
void tapSpan(WidgetTester tester, String text) {
  final spans = <TextSpan>[];
  for (final widget in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
    widget.textSpan?.visitChildren((span) {
      if (span is TextSpan && span.text == text) spans.add(span);
      return true;
    });
  }
  (spans.single.recognizer! as TapGestureRecognizer).onTap!();
}

/// Top to bottom, the sign-in buttons on screen.
List<String> buttons(WidgetTester tester, List<String> labels) {
  final shown = [for (final l in labels) if (find.text(l).evaluate().isNotEmpty) l];
  return shown..sort((a, b) => tester.getTopLeft(find.text(a)).dy.compareTo(tester.getTopLeft(find.text(b)).dy));
}

/// Answers [channel]'s calls (with [answers], else null) and lists them.
List<String> recordChannel(WidgetTester tester, String channel, {Map<String, Object?> answers = const {}}) {
  final calls = <String>[];
  final c = MethodChannel(channel);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(c, (call) async {
    calls.add(call.method);
    return answers[call.method];
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(c, null));
  return calls;
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

    test('a phone the server has the wrong language for is put right on launch', () async {
      final store = MemoryStore();
      final accounts = FakeAccounts();
      await controller(store, accounts).ensure();
      expect(accounts.devices.single, ('token-1', null, 'uz'));
      store.write('app_session_lang', '');

      await controller(store, accounts, language: AppLanguage.ru).ensure();
      expect(accounts.devices.last, ('token-1', null, 'ru'));
      final told = accounts.devices.length;
      await controller(store, accounts, language: AppLanguage.ru).ensure();
      expect(accounts.devices.length, told, reason: 'told once');
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

    testWidgets('the first language change after launch reaches the server (the bots ask in it)', (tester) async {
      final app = TestApp(language: 'uz');
      await app.launch(tester);
      await app.services.locale.choose(AppLanguage.ru);
      await tester.pumpAndSettle();
      expect(app.accounts.devices.last.$3, 'ru');
    });

    testWidgets('a tapped notification opens its page; one arriving in the app shows, and opens', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      app.push.open({'url': 'https://vegukin-twa.pages.dev/pages/places/places-detail.html?id=8&type=restaurant'});
      app.push.open({});
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailScreen), findsOneWidget, reason: 'the place itself, native');
      expect(app.opened.ids, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      app.push.open({'kind': 'hikorea'});
      await tester.pumpAndSettle();
      expect(find.byType(HikoreaScreen), findsOneWidget, reason: 'native, not the web page');
      await tester.pageBack();
      await tester.pumpAndSettle();

      app.push.arrive('Kebab House', 'Now open', {'url': 'https://x/pages/notifications/notifications.html'});
      await tester.pumpAndSettle();
      expect(find.text('Kebab House\nNow open'), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget, reason: 'native now');
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
      await openSignIn(tester);
      expect(buttons(tester, ['Continue with WhatsApp', 'Continue with Google', 'Continue with Telegram']),
          ['Continue with WhatsApp', 'Continue with Google', 'Continue with Telegram']);
    });

    testWidgets('in Uzbek, Telegram first', (tester) async {
      await openSignIn(tester, language: 'uz');
      expect(buttons(tester, ['Telegram orqali kirish', 'WhatsApp orqali kirish', 'Google orqali kirish']),
          ['Telegram orqali kirish', 'WhatsApp orqali kirish', 'Google orqali kirish']);
    });

    testWidgets('WhatsApp: the bot opens, the app waits, and is signed in when Yes is tapped', (tester) async {
      final app = await openSignIn(tester);
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
      final app = await openSignIn(tester);
      await tester.tap(find.text('Continue with Telegram'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1', const AppUser(id: 555000111, signedIn: true, provider: 'telegram', name: 'Aziz'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Signed in with Telegram'), findsOneWidget);
    });

    testWidgets('cancelled in the bot: said so, and the ways in are back', (tester) async {
      final app = await openSignIn(tester);
      await tester.tap(find.text('Continue with Telegram'));
      await settleWaiting(tester);
      app.accounts.cancel('CODE1');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('That timed out or was cancelled. Please try again.'), findsOneWidget);
      expect(find.text('Continue with Telegram'), findsOneWidget);
    });

    testWidgets('Google: the picker, then signed in; closing the picker changes nothing', (tester) async {
      final app = await openSignIn(tester);
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
      final app = await openSignIn(tester);
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
      final app = await openSignIn(tester);
      await tester.tap(find.text(provider == 'telegram' ? 'Continue with Telegram' : 'Continue with WhatsApp'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1', AppUser(id: provider == 'telegram' ? 555000111 : -9000000000001,
          signedIn: true, provider: provider, name: 'Rahim'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // "You're signed in" goes, and with it what it covers.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('signing out: this phone starts again as nobody in particular', (tester) async {
      final app = await signedIn(tester);
      await tapScrolled(tester, find.text('Sign out'));
      expect(app.account.signedIn, isFalse);
      await tester.scrollUntilVisible(find.text('Guest'), -150, scrollable: find.byType(Scrollable).last);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('deleting: asked first, then gone, and a new empty account', (tester) async {
      final app = await signedIn(tester, provider: 'telegram');
      await tapScrolled(tester, find.text('Delete account'));
      expect(find.textContaining('This includes those made in the Telegram bot.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.accounts.deleted, isEmpty);

      await tapScrolled(tester, find.text('Delete account'));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(app.accounts.deleted, ['token-1']);
      expect(app.account.signedIn, isFalse);
      expect(app.account.authHeaders, {'Authorization': 'Bearer token-2'});
      expect(find.text('Account deleted'), findsOneWidget);
    });
  });

  group('the inbox', () {
    test('unread: what came since it was last opened, remembered between launches', () async {
      final store = MemoryStore();
      final accounts = FakeAccounts();
      final c = controller(store, accounts);
      await c.ensure();
      final me = c.user!.id;
      accounts
        ..alert(me, 'One')
        ..alert(me, 'Two');
      expect(await c.refreshInbox(), isTrue);
      expect(c.inbox.map((i) => i.title), ['Two', 'One']);
      expect(c.unread, 2);
      c.markInboxSeen();
      expect(c.unread, 0);

      accounts.alert(me, 'Three');
      final again = controller(store, accounts);
      await again.refreshInbox();
      expect(again.unread, 1);
    });

    test('as the server sends it: UTC time, shown local; what a tap opens', () {
      final item = InboxItem.fromJson({
        'id': 7,
        'title': 'HiKorea',
        'body': 'Ready',
        'data': {'kind': 'hikorea', 'n': 3},
        'at': '2026-10-21T03:15:00Z',
      })!;
      expect(item.at, DateTime.utc(2026, 10, 21, 3, 15).toLocal());
      expect(item.at.isUtc, isFalse);
      expect(item.data, {'kind': 'hikorea', 'n': '3'});
      expect(InboxItem.fromJson({'id': 8, 'title': 'x'}), isNull, reason: 'no time');
    });

    test('a page at a time, older after', () async {
      final accounts = FakeAccounts()..pageSize = 2;
      final c = controller(MemoryStore(), accounts);
      await c.ensure();
      for (final title in ['1', '2', '3', '4', '5']) {
        accounts.alert(c.user!.id, title);
      }
      await c.refreshInbox();
      expect(c.inbox.map((i) => i.title), ['5', '4']);
      expect(c.inboxMore, isTrue);
      await c.loadMoreInbox();
      await c.loadMoreInbox();
      expect(c.inbox.map((i) => i.title), ['5', '4', '3', '2', '1']);
      expect(c.inboxMore, isFalse);
    });

    test('signed in as someone else: their alerts; offline: the list stays', () async {
      final accounts = FakeAccounts();
      final c = controller(MemoryStore(), accounts);
      await c.ensure();
      accounts
        ..alert(c.user!.id, 'Before signing in')
        ..alert(555000111, 'HiKorea: result');
      await c.refreshInbox();
      expect(c.inbox.map((i) => i.title), ['Before signing in']);

      await c.startLink('telegram');
      accounts.confirm('CODE1', const AppUser(id: 555000111, signedIn: true, provider: 'telegram', name: 'Aziz'));
      await c.checkLink('CODE1');
      await pumpEventQueue();
      expect(c.inbox.map((i) => i.title), ['HiKorea: result']);

      accounts.fail = true;
      expect(await c.refreshInbox(), isFalse);
      expect(c.inbox, hasLength(1));
    });

    Finder badge(String text) => find.descendant(of: find.byType(Badge), matching: find.text(text));

    Future<TestApp> withAlerts(WidgetTester tester, {String language = 'en', void Function(TestApp app)? setUp}) async {
      final app = TestApp(language: language);
      setUp?.call(app);
      await app.launch(tester);
      final me = app.account.user!.id;
      app.accounts
        ..alert(me, 'Eid prayer times', body: 'Eid al-Adha prayer at 7:00', at: DateTime(2026, 10, 2, 8, 0))
        ..alert(me, 'HiKorea', body: 'Your residence card is ready', data: {'kind': 'hikorea'}, at: DateTime(2026, 10, 16, 20, 15))
        ..alert(me, 'Kebab House', body: 'A new restaurant near you',
            data: {'url': 'https://x/pages/places/places-detail.html?id=8&type=restaurant'});
      // Back to the app: looked at again.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('the bell counts what is new; the inbox shows it by day; each opens whole', (tester) async {
      await withAlerts(tester);
      expect(badge('3'), findsOneWidget);

      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();
      expect(find.byType(InboxScreen), findsOneWidget);
      expect(buttons(tester, ['Today', 'Kebab House', 'Yesterday', 'HiKorea', '2 October', 'Eid prayer times']),
          ['Today', 'Kebab House', 'Yesterday', 'HiKorea', '2 October', 'Eid prayer times']);
      expect(find.text('Your residence card is ready'), findsOneWidget);

      await tester.tap(find.text('Kebab House'));
      await tester.pumpAndSettle();
      expect(find.byType(InboxMessageScreen), findsOneWidget);
      expect(find.textContaining('A new restaurant near you', findRichText: true), findsOneWidget);
      await tester.tap(find.text('Open Restaurants'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      expect(badge('3'), findsNothing, reason: 'seen');
    });

    test('as the server sends it: the whole text, and its photos (https only)', () {
      final item = InboxItem.fromJson({
        'id': 9,
        'title': 'Eid',
        'body': 'Eid prayer at…',
        'text': 'Eid prayer at 7:00, Ansan mosque.',
        'images': ['https://x/a.jpg', 'http://x/b.jpg', 3],
        'at': '2026-10-21T03:15:00Z',
      })!;
      expect(item.text, 'Eid prayer at 7:00, Ansan mosque.');
      expect(item.images, ['https://x/a.jpg']);
      expect(InboxItem.fromJson({'id': 1, 'title': 'x', 'body': 'Short', 'at': '2026-10-21T03:15:00Z'})!.text, 'Short');
    });

    testWidgets('a long message with photos: the start on its card; all of it, and the photos, on its page',
        (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final long = 'Ramadan timetable for Ansan.\n${'Details of the day. ' * 40}\nCall +82 10-1234-5678 or see https://vegukin.uz/r';
      app.accounts.alert(app.account.user!.id, 'Ramadan', body: 'Ramadan timetable for Ansan.', text: long,
          images: ['https://x/a.jpg', 'https://x/b.jpg'], data: {'kind': 'message'});
      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsOneWidget, reason: 'a second photo');

      await tester.tap(find.text('Ramadan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Details of the day. Details', findRichText: true), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Open Restaurants'), findsNothing, reason: 'no section');

      final page = find.descendant(of: find.byType(InboxMessageScreen), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.textContaining('vegukin.uz', findRichText: true), 300, scrollable: page);
      tapSpan(tester, 'https://vegukin.uz/r');
      expect(app.links.last, Uri.parse('https://vegukin.uz/r'));
      tapSpan(tester, '+82 10-1234-5678');
      expect(app.links.last, Uri.parse('tel:+821012345678'));

      await tester.scrollUntilVisible(find.bySemanticsLabel('Photo 1 of 2'), -300, scrollable: page);
      await tester.tap(find.bySemanticsLabel('Photo 1 of 2'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(InboxMessageScreen), findsOneWidget);
    });

    testWidgets('a tapped notification that is a message opens it whole', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final item = app.accounts.alert(app.account.user!.id, 'Eid', text: 'Eid prayer at 7:00.', data: {'kind': 'message'});
      app.push.open({'kind': 'message', 'inbox_id': '${item.id}'});
      await tester.pumpAndSettle();
      expect(find.byType(InboxMessageScreen), findsOneWidget);
      expect(find.textContaining('Eid prayer at 7:00.', findRichText: true), findsOneWidget);
    });

    testWidgets('one arriving while the app is open is counted', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      app.accounts.alert(app.account.user!.id, 'Kebab House');
      app.push.arrive('Kebab House', 'Now open');
      await tester.pumpAndSettle();
      expect(badge('1'), findsOneWidget);
    });

    testWidgets('nothing yet: said so; offline: said so, and tried again', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing here yet'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      app.accounts.fail = true;
      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load. Check your connection.'), findsOneWidget);
      app.accounts
        ..fail = false
        ..alert(app.account.user!.id, 'Kebab House');
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Kebab House'), findsOneWidget);
    });

    testWidgets('notifications off on the phone: alerts still here, and the way to turn them on', (tester) async {
      final app = await withAlerts(tester, setUp: (app) => app.push.allowed = false);
      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications are off on this phone. New alerts still show up here.'), findsOneWidget);
      await tester.tap(find.text('Turn on'));
      expect(app.permissions.settingsOpened, 1);
    });

    testWidgets('older ones on request; in Uzbek, by day too', (tester) async {
      await withAlerts(tester, language: 'uz', setUp: (app) => app.accounts.pageSize = 2);
      await tester.tap(find.byTooltip('Kelgan xabarlar'));
      await tester.pumpAndSettle();
      expect(find.text('Bugun'), findsOneWidget);
      expect(find.text('Eid prayer times'), findsNothing);
      await tester.tap(find.text('Avvalgilarini ko‘rsatish'));
      await tester.pumpAndSettle();
      expect(find.text('Eid prayer times'), findsOneWidget);
      expect(find.text('Avvalgilarini ko‘rsatish'), findsNothing);
    });
  });

  group('the account page', () {
    testWidgets('notifications off: said so at the top, with the way to turn them on; on again when back', (
      tester,
    ) async {
      final app = TestApp(language: 'en');
      app.push.allowed = false;
      await openAccountScreen(tester, app: app);
      final calls = recordChannel(tester, 'vegukin/reminders');
      expect(find.text('Notifications are off'), findsOneWidget);
      expect(find.text('Alerts still reach your Inbox, but this phone won’t show them.'), findsOneWidget);
      expect(find.text('Test message'), findsNothing, reason: 'nothing to test while they are off');
      await tester.tap(find.text('Turn on'));
      expect(calls, ['openNotificationSettings'], reason: 'the app’s notification settings, channels and all');

      app.push.allowed = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Notifications are off'), findsNothing);
      expect(find.text('On'), findsOneWidget, reason: 'this phone: on');
    });

    testWidgets('the test says what arrived: here at once, or not within 20 s, with what to check', (tester) async {
      final app = await openAccountScreen(tester);
      expect(find.text('Goes to this phone.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Send'), 150, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(app.accounts.testPushes, ['token-1']);
      expect(find.text('Waiting for it on this phone…'), findsOneWidget, reason: '"sent" is not "arrived"');

      app.push.arrive('Notifications work ✅', 'Muslim Vegukin alerts reach this phone.', {'kind': 'test'});
      await tester.pump();
      expect(find.text('Arrived on this phone'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing, reason: 'shown as a real notification instead');

      await tester.tap(find.text('Send'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      expect(find.text('Didn’t arrive on this phone'), findsOneWidget);
      expect(find.textContaining('battery saving'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      app.accounts.testPushOutcome = 'no_token';
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('This phone isn’t registered yet. Check the internet and reopen the app.'), findsOneWidget);

      app.accounts.testPushOutcome = 'sent';
      await tester.tap(find.text('Send'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.text('Look in the phone’s notification panel'),
        findsOneWidget,
        reason: 'away meanwhile: it may be there, unseen by the app',
      );
    });

    testWidgets('a Telegram account: the test comes from the bot too, and a blocked bot is said', (tester) async {
      final app = TestApp(language: 'en');
      await openSignIn(tester, app: app);
      await tester.tap(find.text('Continue with Telegram'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1', const AppUser(id: 555000111, signedIn: true, provider: 'telegram', name: 'Aziz'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Goes to this phone and to the Telegram bot.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Send'), 150, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(find.text('Sent to the Telegram bot'), findsOneWidget);
      await tester.tap(find.text('Open the bot'));
      expect(app.links.last, Uri.parse('https://t.me/MuslimVegukinBot'));

      app.push.arrive('Notifications work ✅', '…', {'kind': 'test'});
      await tester.pump();
      expect(find.text('Arrived on this phone'), findsOneWidget);
      app.accounts.testTelegramOutcome = 'blocked';
      await tester.tap(find.text('Send'));
      await tester.pump();
      expect(find.text('The bot can’t write to you: open it and tap Start.'), findsOneWidget);
    });

    testWidgets('prayer reminders that would come late: said at the top, with the way to allow', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      final calls = recordChannel(tester, 'vegukin/widget', answers: {'exactAlarmsMissing': true});
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Prayer reminders may come late'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      expect(calls.last, 'openExactAlarmSettings');
      expect(find.text('5 prayers'), findsOneWidget, reason: 'the reminders that are on');
    });

    testWidgets('the Telegram photo, on the page and on the home screen; fetched once', (tester) async {
      final app = TestApp(language: 'en');
      app.accounts.photos[555000111] = transparentPng;
      await openSignIn(tester, app: app);
      await tester.tap(find.text('Continue with Telegram'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1',
          const AppUser(id: 555000111, signedIn: true, provider: 'telegram', name: 'Aziz Karimov', detail: '@aziz', photo: 'v1'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AccountAvatar), matching: find.byType(Image)), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AccountAvatar), matching: find.byType(Image)), findsOneWidget,
          reason: 'the home screen shows who is signed in');
      expect(app.accounts.photoFetches, 1);
      expect(app.store.read('app_photo_v'), 'v1', reason: 'kept for the next launch');
    });

    testWidgets('WhatsApp: initials, and why there is no photo', (tester) async {
      final app = await openSignIn(tester);
      await tester.tap(find.text('Continue with WhatsApp'));
      await settleWaiting(tester);
      app.accounts.confirm('CODE1',
          const AppUser(id: -9000000000001, signedIn: true, provider: 'whatsapp', name: 'Rahim Aliyev', detail: '+8210'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('RA'), findsOneWidget);
      expect(find.text('WhatsApp doesn’t share profile photos with apps.'), findsOneWidget);
    });

    testWidgets('what reaches them and what they follow, one tap away; the app; the version', (tester) async {
      final app = TestApp(language: 'en');
      app.hikorea.watchList.add(
        HkWatch(
          id: 1,
          officeId: '1270100',
          officeNameEn: 'Seoul Immigration Office',
          deskSeq: 201,
          start: DateTime(2026, 10, 18),
          end: DateTime(2026, 10, 31),
          status: 'active',
        ),
      );
      app.places.areas.add(
        const NotifyArea(
          id: 9,
          fromLocation: false,
          label: '안산 원곡동',
          lat: 37.33,
          lon: 126.81,
          radiusKm: 5,
          types: {PlaceKind.mosque},
        ),
      );
      app.places.watches[1] = app.places.watches[1]!.copyWith(watching: true);
      await app.launch(tester);
      app.accounts.alert(app.account.user!.id, 'Kebab House');
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('1 new'), findsOneWidget);
      expect(find.text('1 area · 1 place'), findsOneWidget, reason: 'from the server, kept for next time');
      expect(find.text('1 active'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Inbox')).dy,
        lessThan(tester.getTopLeft(find.text('Test message')).dy),
        reason: 'what they use most comes before settings',
      );

      await tapScrolled(tester, find.text('Places & areas'));
      expect(find.byType(NotificationsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapScrolled(tester, find.text('HiKorea watches'));
      expect(find.byType(HkWatchesScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget, reason: 'the language');
      await tapScrolled(tester, find.text('Share the app'));
      expect(app.shared.single, contains('play.google.com/store/apps/details?id=com.vegukin.muslim_vegukin'));
      await tapScrolled(tester, find.text('Suggest an idea or report a bug'));
      expect(find.byType(CommunityScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Muslim Vegukin · Version 1.0.0 (1)'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tapScrolled(tester, find.text('Dark mode'));
      expect(Theme.of(tester.element(find.byType(AccountScreen))).brightness, Brightness.dark);
    });
  });
}
