import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslim_vegukin/features/qna/qna_answer_screen.dart';
import 'package:muslim_vegukin/features/qna/qna_models.dart';
import 'package:muslim_vegukin/features/qna/qna_screen.dart';
import 'package:muslim_vegukin/features/qna/qna_search_screen.dart';
import 'package:muslim_vegukin/features/qna/qna_source.dart';

import 'support/fakes.dart';

/// What the app put on the clipboard.
final copied = <String>[];

Future<TestApp> openQna(WidgetTester tester, {String language = 'uz', TestApp? app}) async {
  copied.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  app ??= TestApp(language: language);
  await app.launch(tester);
  final tile = switch (language) { 'ru' => 'Спросите знающих', 'en' => 'Ask the scholars', _ => 'Zikr ahlidan so‘rang' };
  await tester.scrollUntilVisible(find.text(tile), 200);
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text(tile));
  await tester.pumpAndSettle();
  expect(find.byType(QnaScreen), findsOneWidget);
  return app;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the answer page down to [finder], then taps it.
Future<void> tapOnAnswer(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(finder, find.byType(ListView), const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Android's back.
Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  group('the page', () {
    testWidgets('today’s selection: kept all day, more as it scrolls, a new one on asking', (tester) async {
      final app = await openQna(tester);
      expect(app.activity.actions, ['qna']);
      expect(find.text('Kunlik tanlov'), findsOneWidget);
      expect(find.text('Safarda namozni qasr qilish qanday bo‘ladi?'), findsOneWidget);
      expect(app.qna.browses, 1);

      await tester.fling(find.byType(CustomScrollView), const Offset(0, -6000), 3000);
      await tester.pumpAndSettle();
      expect(app.qna.browses, greaterThan(1), reason: 'more after the first fifteen');

      // Opened again the same day: the same selection, from the phone.
      await back(tester);
      final browses = app.qna.browses;
      await tester.tap(find.text('Zikr ahlidan so‘rang'));
      await tester.pumpAndSettle();
      expect(app.qna.browses, browses);
      expect(find.text('Safarda namozni qasr qilish qanday bo‘ladi?'), findsOneWidget);

      await tester.tap(find.byTooltip('Yangi savollar'));
      await tester.pumpAndSettle();
      expect(app.qna.browses, browses + 1);
    });

    testWidgets('the verse it is named after, and the search in view', (tester) async {
      await openQna(tester);
      expect(find.text(qnaVerse), findsOneWidget);
      expect(find.text('Nahl surasi, 43-oyat'), findsOneWidget);
      expect(find.text('Savolingizni o‘z so‘zlaringiz bilan yozing…'), findsOneWidget);
    });

    testWidgets('in another language: told the archive is in Uzbek', (tester) async {
      await openQna(tester, language: 'en');
      expect(find.text('Questions and answers are in Uzbek (Latin or Cyrillic).'), findsOneWidget);
      expect(find.text('Write your question in Uzbek…'), findsOneWidget);
    });

    testWidgets('no connection: said so, with a retry', (tester) async {
      final app = TestApp(language: 'uz');
      app.qna.fail = true;
      await openQna(tester, app: app);
      expect(find.text('Savollar yuklanmadi'), findsOneWidget);
      app.qna.fail = false;
      await tapVisible(tester, find.text('Qayta urinish'));
      expect(find.text('Safarda namozni qasr qilish qanday bo‘ladi?'), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('in one’s own words; the question stays to be refined, and is remembered', (tester) async {
      final app = await openQna(tester);
      await tester.tap(find.text('Savolingizni o‘z so‘zlaringiz bilan yozing…'));
      await tester.pumpAndSettle();
      expect(find.byType(QnaSearchScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'na');
      await tester.pump();
      expect(find.text('Kamida 3 ta harf yozing'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Qidirish')).onPressed, isNull);

      await search(tester, 'Krab yeyish mumkinmi');
      expect(app.qna.searches, ['Krab yeyish mumkinmi']);
      expect(app.qna.who, {'user_id': -1234567890, 'username': 'Android app'});
      expect(find.text('3 ta natija'), findsOneWidget);
      expect(find.text('Qisqichbaqa yeyish joizmi?'), findsOneWidget);
      expect(find.text('Krab yeyish mumkinmi'), findsOneWidget, reason: 'still in the box');

      // A new visit: the search is among the recent ones, one tap away.
      await back(tester);
      await tester.tap(find.byTooltip('Savol qidirish'));
      await tester.pumpAndSettle();
      expect(find.text('So‘nggi qidiruvlar'), findsOneWidget);
      await tester.tap(find.text('Krab yeyish mumkinmi'));
      await tester.pumpAndSettle();
      expect(app.qna.searches, hasLength(2));
    });

    testWidgets('an example to start from; nothing found; no connection', (tester) async {
      final app = await openQna(tester);
      await tester.tap(find.byTooltip('Savol qidirish'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(qnaExamples.first));
      expect(app.qna.searches, [qnaExamples.first]);
      expect(find.text('3 ta natija'), findsOneWidget);

      await search(tester, 'bunday savol yo‘q');
      expect(find.text('Hech narsa topilmadi'), findsOneWidget);

      app.qna.fail = true;
      await search(tester, 'Namoz vaqtlari');
      expect(find.text('Internet yo‘q'), findsOneWidget);
      expect(find.text('Hech narsa topilmadi'), findsNothing, reason: 'no connection is not "nothing found"');
      app.qna.fail = false;
      await tapVisible(tester, find.text('Qayta urinish'));
      expect(find.text('3 ta natija'), findsOneWidget);
    });
  });

  group('an answer', () {
    testWidgets('read on its own page; a similar question opens on top, Back returns', (tester) async {
      final app = await openQna(tester);
      await tapVisible(tester, find.text('Qisqichbaqa yeyish joizmi?'));
      expect(find.byType(QnaAnswerScreen), findsOneWidget);
      expect(find.text('SAVOL'), findsOneWidget);
      expect(find.text('JAVOB'), findsOneWidget);
      expect(find.text('Shayx Muhammad Sodiq Muhammad Yusuf'), findsOneWidget);
      expect(app.qna.details, ['2']);

      await tapOnAnswer(tester, find.text('Manbaga o‘tish'));
      expect(app.links.last, Uri.parse('https://savollar.islom.uz/s/2'));

      await tapOnAnswer(tester, find.text('Dengiz mahsulotlarining hukmi'));
      expect(find.byType(QnaAnswerScreen, skipOffstage: false), findsNWidgets(2));
      expect(app.qna.details, ['2', '900']);
      expect(find.text('Safarda namozni qasr qilish qanday bo‘ladi? (900)'), findsOneWidget, reason: 'fetched in full');

      await back(tester);
      expect(find.byType(QnaAnswerScreen), findsOneWidget);
      expect(find.text('Dengiz mahsulotlarining hukmi'), findsOneWidget, reason: 'the first answer, where it was left');
    });

    testWidgets('saved, and read again without a connection', (tester) async {
      final app = await openQna(tester);
      await tapVisible(tester, find.text('Qisqichbaqa yeyish joizmi?'));
      await tester.tap(find.byTooltip('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Saqlandi'), findsOneWidget);
      expect(find.byTooltip('Saqlanganlardan olib tashlash'), findsOneWidget);
      await back(tester);

      app.qna.fail = true;
      await tester.scrollUntilVisible(find.text('Saqlangan javoblar'), -200);
      await tapVisible(tester, find.text('Saqlangan javoblar'));
      await tapVisible(tester, find.text('Qisqichbaqa yeyish joizmi?'));
      expect(find.textContaining('Ulamolarimiz bu masalada', findRichText: true), findsOneWidget);
      expect(find.text('Javob yuklanmadi'), findsNothing);
    });

    testWidgets('larger text, copied whole, shared with its link', (tester) async {
      final app = await openQna(tester);
      await tapVisible(tester, find.text('Qisqichbaqa yeyish joizmi?'));
      double size() => tester.widget<SelectableText>(find.byType(SelectableText).first).style!.fontSize!;
      expect(size(), 21);
      await tester.tap(find.byTooltip('Matn o‘lchami'));
      await tester.pump();
      expect(size(), closeTo(21 * 1.15, 0.01));

      await tapOnAnswer(tester, find.text('Nusxalash'));
      expect(copied.last, startsWith('Qisqichbaqa yeyish joizmi?'));
      expect(copied.last, contains('Javob (Shayx Muhammad Sodiq Muhammad Yusuf):'));
      expect(copied.last, endsWith('https://savollar.islom.uz/s/2'));

      await tester.tap(find.byTooltip('Ulashish'));
      expect(app.shared.single, '📖 Qisqichbaqa yeyish joizmi?\n\n🔗 https://savollar.islom.uz/s/2');
    });

    testWidgets('a similar question that can’t be fetched: said so, with a retry', (tester) async {
      final app = await openQna(tester);
      await tapVisible(tester, find.text('Qisqichbaqa yeyish joizmi?'));
      app.qna.fail = true;
      await tapOnAnswer(tester, find.text('Halol va harom taomlar'));
      expect(find.text('Javob yuklanmadi'), findsOneWidget);
      expect(find.byTooltip('Saqlash'), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.bookmark_border_rounded)).onPressed, isNull);
      app.qna.fail = false;
      await tapVisible(tester, find.text('Qayta urinish'));
      expect(find.textContaining('Ulamolarimiz', findRichText: true), findsOneWidget);
    });
  });

  group('API', () {
    test('as the web page asks', () async {
      final asked = <http.Request>[];
      final source = HttpQnaSource(MockClient((request) async {
        asked.add(request);
        final body = switch (request.url.path) {
          '/api/questions/browse' => {
              'success': true,
              'questions': [
                {'id': 7, 'title': 'Savol', 'topic': '🕌 Namoz', 'views': 1530, 'answerBody': 'Javob', 'link': '#'},
              ],
            },
          '/api/questions/search' => {'success': true, 'count': 0, 'alphabet': 'latin', 'questions': []},
          '/api/questions/7' => {
              'success': true,
              'question': {'id': 7, 'title': 'Savol', 'answerBody': 'Javob', 'link': 'https://savollar.islom.uz/s/7'},
              'related': [
                {'id': 8, 'title': 'Boshqa savol'},
              ],
            },
          _ => {'success': false, 'error': 'no'},
        };
        return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }));

      final browsed = await source.browse();
      expect(asked.last.url.toString(), 'https://vegukin-api.duckdns.org/api/questions/browse?limit=15');
      expect(browsed.single.id, '7');
      expect(browsed.single.link, isNull, reason: '"#" is no link');

      await source.search('Namoz', who: const {'user_id': -5, 'username': 'Android app'});
      expect(jsonDecode(asked.last.body), {'query': 'Namoz', 'limit': 20, 'user_id': -5, 'username': 'Android app'});

      final detail = await source.detail('7');
      expect(detail.question.link, Uri.parse('https://savollar.islom.uz/s/7'));
      expect(detail.related.single.title, 'Boshqa savol');
      expect(detail.related.single.isComplete, isFalse);

      expect(source.detail('404'), throwsA(isA<QnaException>()));
    });

    test('views counted as on the web page', () {
      expect(compactCount(950), '950');
      expect(compactCount(1530), '1.5k');
    });
  });
}
