import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/housing/housing_parts.dart';
import 'package:muslim_vegukin/features/housing/housing_screen.dart';

import 'support/fakes.dart';

Future<TestApp> openHousing(WidgetTester tester, {TestApp? app}) async {
  app ??= TestApp(language: 'uz');
  await app.launch(tester);
  await tester.scrollUntilVisible(find.text('Uy-joy e’lonlari'), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('Uy-joy e’lonlari'));
  await tester.pumpAndSettle();
  return app;
}

Future<void> signIn(WidgetTester tester, TestApp app) async {
  await tester.tap(find.text('Google orqali kirish'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  app.housing.signedIn = true;
}

void main() {
  test('addresses split as the web page does; numbers written as in Korea', () {
    expect(splitAddress('경기도 안산시 단원구 원곡동 123'), ('경기도 · 안산시 단원구', '원곡동 123'));
    expect(splitAddress('서울 관악구 신림동'), ('서울 · 관악구', '신림동'));
    expect(splitAddress('원곡동 123'), (null, '원곡동 123'));
    expect(formatPhone('01012345678'), '010-1234-5678');
    expect(formatPhone('0212345678'), '02-1234-5678');
    String typed(String t) => const PhoneTyping().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t)).text;
    expect(typed('0101234'), '010-1234');
    expect(typed('021234567'), '02-123-4567');
    expect(typed('03112345678'), '031-1234-5678');
  });

  testWidgets('the board, natively: newest first, numbers hidden until a post is opened; a call from it', (tester) async {
    final app = await openHousing(tester);
    expect(find.byType(HousingScreen), findsOneWidget);
    expect(app.opened.ids, isEmpty, reason: 'not the web page');
    expect(find.text('경기도 · 안산시 단원구'), findsOneWidget);
    expect(find.textContaining('•••'), findsOneWidget);
    expect(find.text('Raqamni ko‘rish'), findsOneWidget);
    expect(find.text('Telegram orqali bog‘lanish'), findsOneWidget);
    await tester.tap(find.text('원곡동 123'));
    await tester.pumpAndSettle();
    expect(find.text('010-1234-5678'), findsOneWidget);
    await tester.tap(find.text('010-1234-5678'));
    await tester.pumpAndSettle();
    expect(app.links.last, Uri.parse('tel:01012345678'));
  });

  testWidgets('near an address: nearest first with how far; an address not found said so', (tester) async {
    final app = await openHousing(tester);
    await tester.enterText(find.byType(TextField).first, '부산');
    await tester.tap(find.text('Izlash'));
    await tester.pumpAndSettle();
    expect(find.text('Manzil topilmadi'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '안산 원곡동');
    await tester.tap(find.text('Izlash'));
    await tester.pumpAndSettle();
    expect(app.housing.asked, contains('posts near'));
    expect(find.text('Yaqinlik bo‘yicha'), findsWidgets);
    expect(find.text('1.1 km'), findsOneWidget);
  });

  testWidgets('a post: signing in first; what’s missing said; posted, listed as mine, extended, deleted', (tester) async {
    final app = await openHousing(tester);
    await tester.tap(find.text('Joylash'));
    await tester.pumpAndSettle();
    await signIn(tester, app);
    await tester.tap(find.text('E’lonni joylash'));
    await tester.pumpAndSettle();
    expect(find.text('Manzilni koreys tilida, to‘liq yozing.'), findsOneWidget);
    expect(find.text('Telefon raqami yoki Telegram — kamida bittasini ko‘rsating.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '안산시 원곡동 77');
    await tester.enterText(find.byType(TextField).at(1), '01099998888');
    expect(find.text('010-9999-8888'), findsOneWidget, reason: 'grouped as typed');
    await tester.enterText(find.byType(TextField).last, 'Bir kishilik xona, oyiga 400,000 won, kommunal alohida.');
    await tester.tap(find.text('E’lonni joylash'));
    await tester.pumpAndSettle();
    expect(app.housing.asked, contains('create 안산시 원곡동 77 010-9999-8888 -'));
    expect(find.text('E’loningiz joylandi'), findsOneWidget);

    await tester.tap(find.text('E’lonlarim'));
    await tester.pumpAndSettle();
    expect(find.text('30 kun qoldi'), findsOneWidget);
    await tester.tap(find.text('Uzaytirish'));
    await tester.pumpAndSettle();
    expect(find.text('Muddat yana 30 kunga uzaytirildi'), findsOneWidget);
    await tester.tap(find.text('O‘chirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    expect(find.text('Sizda e’lon yo‘q'), findsOneWidget);
  });

  testWidgets('alerts: a radius picked, added, listed, deleted', (tester) async {
    final app = await openHousing(tester);
    await tester.tap(find.text('Xabarnoma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akkauntga kirish'));
    await tester.pumpAndSettle();
    await signIn(tester, app);
    await tester.tap(find.text('Xabarnoma').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '원곡동');
    await tester.tap(find.text('5 km'));
    await tester.tap(find.text('Qo‘shish'));
    await tester.pumpAndSettle();
    expect(app.housing.asked, contains('alert 원곡동 5'));
    expect(find.text('Bildirishnoma qo‘shildi'), findsOneWidget);
    await tester.tap(find.byTooltip('O‘chirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    expect(find.text('Hozircha bildirishnoma yo‘q'), findsOneWidget);
  });

  testWidgets('a notification about a post opens it', (tester) async {
    final app = TestApp(language: 'uz');
    await app.launch(tester);
    app.push.open({'url': 'https://vegukin-twa.pages.dev/pages/housing/housing.html?post=2', 'kind': 'housing'});
    await tester.pumpAndSettle();
    expect(find.byType(HousingScreen), findsOneWidget);
    expect(find.text('@xonador'), findsOneWidget);
  });
}
