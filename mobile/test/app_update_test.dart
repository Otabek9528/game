import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/app_update.dart';
import 'package:muslim_vegukin/features/account/account_screen.dart';
import 'package:muslim_vegukin/features/home/update_banner.dart';

import 'support/fakes.dart';

void main() {
  group('the update controller', () {
    late FakePlayUpdates play;
    late MemoryStore store;
    late DateTime now;
    late FakeActivityLog activity;
    UpdateController controller() =>
        UpdateController(source: play, store: store, activity: activity, clock: () => now);

    setUp(() {
      play = FakePlayUpdates()..next = const PlayUpdate(versionCode: 5);
      store = MemoryStore();
      now = DateTime(2026, 11, 22, 9);
      activity = FakeActivityLog();
    });

    test('a version declined is offered again after three days, a newer one at once', () async {
      play.accept = false;
      final first = controller();
      await first.start();
      expect(play.asked, ['check', 'dialog']);
      expect(first.stage, UpdateStage.available, reason: 'still there, on the account page');
      expect(activity.actions, contains('update:declined'));

      now = now.add(const Duration(days: 2));
      play.asked.clear();
      await controller().start();
      expect(play.asked, ['check'], reason: 'two days: not again');

      play.next = const PlayUpdate(versionCode: 6);
      play.asked.clear();
      await controller().start();
      expect(play.asked, ['check', 'dialog'], reason: 'a newer version: offered at once');

      now = now.add(const Duration(days: 3));
      play.next = const PlayUpdate(versionCode: 6);
      play.asked.clear();
      await controller().start();
      expect(play.asked, ['check', 'dialog'], reason: 'three days on: again');
    });

    test('"Update" on the account page offers it whatever was answered before', () async {
      play.accept = false;
      final updates = controller();
      await updates.start();
      play.accept = true;
      await updates.update();
      expect(play.asked, ['check', 'dialog', 'dialog']);
      expect(updates.stage, UpdateStage.ready);
    });

    test('a failed download stays on offer', () async {
      play.downloadOk = false;
      final updates = controller();
      await updates.start();
      expect(updates.stage, UpdateStage.available);
      expect(activity.actions, containsAllInOrder(['update:accepted', 'update:failed']));
    });

    test('downloaded in an earlier session: ready at once, no dialog', () async {
      play.next = const PlayUpdate(versionCode: 5, downloaded: true);
      final updates = controller();
      await updates.start();
      expect(updates.stage, UpdateStage.ready);
      expect(play.asked, ['check']);
    });

    test('coming back asks Play again only after six hours, and never before the start', () async {
      final updates = controller();
      play.next = null;
      await updates.resumed();
      expect(play.asked, isEmpty, reason: 'the app\'s own first questions come first');
      await updates.start();
      now = now.add(const Duration(hours: 5));
      await updates.resumed();
      expect(play.asked, ['check']);
      now = now.add(const Duration(hours: 1));
      await updates.resumed();
      expect(play.asked, ['check', 'check']);
    });

    test('an install that didn\'t happen shows the version as ready again', () async {
      play.next = const PlayUpdate(versionCode: 5, downloaded: true);
      final updates = controller();
      await updates.start();
      updates.installQuietly();
      expect(updates.stage, UpdateStage.installing);
      expect(play.asked.last, 'install');
      await updates.resumed();
      expect(updates.stage, UpdateStage.ready);
    });

    test('nothing newer, or no Play to ask: nothing', () async {
      play.next = null;
      final updates = controller();
      await updates.start();
      expect(updates.stage, UpdateStage.none);
      updates.restart();
      updates.installQuietly();
      expect(play.asked, ['check'], reason: 'nothing to install');
    });
  });

  group('in the app', () {
    final banner = find.byType(UpdateBanner);

    // The download's progress bar moves until it ends: frames, not settling.
    Future<void> frames(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('a newer version: Play\'s dialog; the app keeps working while it downloads; then Restart', (tester) async {
      final app = TestApp(language: 'en');
      app.playUpdates
        ..next = const PlayUpdate(versionCode: 5)
        ..holdDownload = true;
      await app.launch(tester, settle: false);
      await frames(tester);
      expect(app.playUpdates.asked, ['check', 'dialog']);
      expect(find.descendant(of: banner, matching: find.text('Downloading the new version…')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Meanwhile the app works as ever.
      await tester.tap(find.byTooltip('Account'));
      await frames(tester);
      expect(find.byType(AccountScreen), findsOneWidget);
      final row = find.text('Downloading…');
      await tester.scrollUntilVisible(row, 150, scrollable: find.byType(Scrollable).last);
      expect(row, findsOneWidget, reason: 'its row on the account page');
      await tester.pageBack();
      await frames(tester);

      app.playUpdates.finishDownload();
      await tester.pumpAndSettle();
      expect(find.text('The new version is ready'), findsOneWidget);
      await tester.tap(find.descendant(of: banner, matching: find.text('Restart')));
      await tester.pump();
      expect(app.playUpdates.asked.last, 'install');
      expect(find.text('Installing…'), findsOneWidget);
    });

    testWidgets('ready while on another page: said once at the bottom, with Restart', (tester) async {
      final app = TestApp(language: 'uz');
      app.playUpdates
        ..next = const PlayUpdate(versionCode: 5)
        ..holdDownload = true;
      await app.launch(tester, settle: false);
      await frames(tester);
      await tester.tap(find.byTooltip('Akkaunt'));
      await frames(tester);
      app.playUpdates.finishDownload();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(SnackBar), matching: find.text('Qayta ishga tushirish')));
      await tester.pump();
      expect(app.playUpdates.asked.last, 'install');
    });

    testWidgets('left from the home screen it installs by itself; from any other page it waits', (tester) async {
      final app = TestApp(language: 'en');
      app.playUpdates.next = const PlayUpdate(versionCode: 5, downloaded: true);
      await app.launch(tester);
      expect(find.text('The new version is ready'), findsOneWidget);

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(app.playUpdates.asked, isNot(contains('install')), reason: 'a page that may hold unsaved work');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(app.playUpdates.asked.last, 'install');
      expect(app.activity.actions, contains('update:quiet'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    });

    testWidgets('declined: nothing on the home screen; the account page still offers it', (tester) async {
      final app = TestApp(language: 'en');
      app.playUpdates
        ..next = const PlayUpdate(versionCode: 5)
        ..accept = false;
      await app.launch(tester);
      expect(find.text('Downloading the new version…'), findsNothing);
      expect(find.text('The new version is ready'), findsNothing);

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      final row = find.text('New version available');
      expect(find.text('Update'), findsNothing, reason: 'not built yet: further down');
      await tester.scrollUntilVisible(row, 150, scrollable: find.byType(Scrollable).last);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      app.playUpdates.accept = true;
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(app.playUpdates.asked.where((a) => a == 'dialog'), hasLength(2));
      // The row says what is next, and so does the note at the bottom.
      expect(find.text('Restart'), findsNWidgets(2));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('nothing newer: no banner, no row', (tester) async {
      final app = TestApp(language: 'en');
      await app.launch(tester);
      expect(app.playUpdates.asked, ['check']);
      expect(find.text('Downloading the new version…'), findsNothing);
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Update'), findsNothing);
    });
  });
}
