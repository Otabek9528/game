import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/jobs/jobs_posts.dart';
import 'package:muslim_vegukin/features/jobs/jobs_screen.dart';
import 'package:muslim_vegukin/features/jobs/jobs_source.dart';

import 'support/fakes.dart';

Future<TestApp> openJobs(WidgetTester tester) async {
  final app = TestApp(language: 'uz');
  await app.launch(tester);
  await tester.scrollUntilVisible(find.text('Ish e’lonlari'), 200, scrollable: find.byType(Scrollable).first);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ish e’lonlari'));
  await tester.pumpAndSettle();
  return app;
}

/// From the landing page: "post", signed in on the way.
Future<void> openPosting(WidgetTester tester) async {
  await tester.tap(find.text('E’lon joylash'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Google orqali kirish'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.descendant(of: find.byType(JobsPostsPage), matching: find.byType(Scrollable)).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('times come in Korean time; done is offered three hours after taken', () {
    final post = JobPost.fromJson({'id': 7, 'message': 'x', 'status': 'reserved', 'reserved_at': '2026-10-17 20:00:00', 'commission': false})!;
    final reserved = DateTime.utc(2026, 10, 17, 11);
    expect(post.reservedAt, reserved);
    expect(post.commission, isFalse);
    expect(post.finishIn(reserved.add(const Duration(hours: 1))), const Duration(hours: 2));
    expect(post.finishIn(reserved.add(const Duration(hours: 4))), Duration.zero);
    expect(JobPost.fromJson({'id': 1, 'message': 'x', 'status': 'available'})!.commission, isTrue, reason: 'as the web page reads it');
  });

  testWidgets('the group link, natively: 15 seconds to join, then a new one', (tester) async {
    final app = await openJobs(tester);
    expect(find.byType(JobsScreen), findsOneWidget);
    expect(app.opened.ids, isEmpty, reason: 'not the web page');
    await tester.tap(find.text('Guruh linkini olish'));
    await tester.pumpAndSettle();
    final link = find.textContaining('https://t.me/+test');
    expect(link, findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    await tester.tap(find.text('Guruhga qo‘shilish'));
    await tester.pumpAndSettle();
    expect(app.links.last.toString(), startsWith('https://t.me/+test'));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.text('Havola muddati tugadi'), findsOneWidget);
    expect(link, findsNothing);
    app.jobs.fail = true;
    await tester.tap(find.text('Qayta urinish'));
    await tester.pumpAndSettle();
    expect(find.text('Tarmoq xatosi. Qayta urinib ko‘ring.'), findsOneWidget);
  });

  testWidgets('posting: sign in, what is missing said on the button, the fee chosen, sent', (tester) async {
    final app = await openJobs(tester);
    await openPosting(tester);
    expect(find.text('Yangi e’lon'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Ansanga zavodga 3 kishi kerak');
    await tester.enterText(find.byType(TextField).at(1), '010-3333-4444');
    await tapVisible(tester, find.text('E’lonni joylash'));
    expect(find.text('Komissiya turini tanlang'), findsOneWidget);
    await tapVisible(tester, find.text('Komissiyasiz'));
    expect(find.textContaining('hech qanday komissiya olinmaydi'), findsOneWidget, reason: 'the footnote shown');
    await tapVisible(tester, find.text('E’lonni joylash'));
    expect(find.text('Qoidalarga rozilik belgisini qo‘ying'), findsOneWidget);
    expect(app.jobs.sent, isEmpty);
    await tapVisible(tester, find.byType(Checkbox));
    await tapVisible(tester, find.text('E’lonni joylash'));
    expect(find.text('E’lon yuborildi!'), findsOneWidget);
    expect(app.jobs.sent.single, containsPair('contact', '010-3333-4444'));
    expect(app.jobs.sent.single, containsPair('commission', false));
    await tester.tap(find.text('E’lonlarim').last);
    await tester.pumpAndSettle();
    expect(find.text('Ansanga zavodga 3 kishi kerak'), findsOneWidget);
  });

  testWidgets('one’s posts: taken, done not before three hours, changed, deleted', (tester) async {
    final app = await openJobs(tester);
    await openPosting(tester);
    await tester.tap(find.text('E’lonlarim'));
    await tester.pumpAndSettle();
    expect(find.text('Band'), findsOneWidget);
    expect(find.textContaining('Yakunlash uchun: 2 soat 0 daq. qoldi'), findsOneWidget);
    final finish = tester.widget<FilledButton>(find.ancestor(of: find.text('Yakunlash'), matching: find.byType(FilledButton)));
    expect(finish.onPressed, isNull);

    await tapVisible(tester, find.text('Band qilish'));
    await tester.tap(find.text('Ha'));
    await tester.pumpAndSettle();
    expect(app.jobs.asked, contains('status 1 reserved'));
    expect(find.text('Band'), findsNWidgets(2));

    await tapVisible(tester, find.text('Faol qilish').first);
    await tester.tap(find.text('Ha'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Tahrirlash'));
    expect(find.text('E’lonni tahrirlash'), findsOneWidget);
    expect(find.text('Qurilishga ishchi kerak, Hwaseong, bir haftaga'), findsOneWidget, reason: 'its text to change');
    await tester.enterText(find.byType(TextField).first, 'Qurilishga 2 ishchi kerak, Hwaseong');
    await tapVisible(tester, find.text('O‘zgarishlarni saqlash'));
    expect(find.text('E’lon yangilandi!'), findsOneWidget);
    expect(app.jobs.mine.last['message'], 'Qurilishga 2 ishchi kerak, Hwaseong');

    await tester.tap(find.text('E’lonlarim').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('O‘chirish').first);
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    expect(app.jobs.mine, hasLength(1));
  });
}
