import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/widgets/fit.dart';
import 'package:muslim_vegukin/core/widgets/tap_pad.dart';

Widget _host(Widget child, {double textScale = 1}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('TapPad', () {
    testWidgets('a small control gets 48 × 48, looks the same, and answers around itself', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          TapPad(
            child: Material(
              color: Colors.green,
              child: InkWell(onTap: () => taps++, child: const SizedBox(width: 30, height: 24)),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(TapPad)), const Size(48, 48));
      expect(tester.getSize(find.byType(InkWell)), const Size(30, 24), reason: 'what is seen is unchanged');

      final area = tester.getRect(find.byType(TapPad));
      await tester.tapAt(area.center);
      await tester.tapAt(area.topLeft + const Offset(2, 2));
      await tester.tapAt(area.bottomRight - const Offset(2, 2));
      expect(taps, 3, reason: 'the middle, and both corners of the area around it');

      await tester.tapAt(area.topLeft - const Offset(4, 4));
      expect(taps, 3, reason: 'outside the area: nothing');
    });

    testWidgets('one target for a screen reader, as large as the area', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          TapPad(
            child: Material(
              child: InkWell(onTap: () {}, child: const SizedBox(width: 30, height: 24, child: Text('x'))),
            ),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('a control already large enough is left alone', (tester) async {
      await tester.pumpWidget(_host(const TapPad(child: SizedBox(width: 120, height: 56))));
      expect(tester.getSize(find.byType(TapPad)), const Size(120, 56));
    });
  });

  group('FitLine', () {
    double shown(WidgetTester tester) {
      final box = tester.renderObject<RenderBox>(find.byType(Text));
      // The line's height on screen over its height as laid out: its scale.
      return tester.getSize(find.byType(FitLine)).height / box.size.height;
    }

    // The test font's letters are all one em wide: ten of them are 200.
    const style = TextStyle(fontSize: 20);
    const ten = 'abcdefghij';

    testWidgets('a line that fits is left as it is', (tester) async {
      await tester.pumpWidget(_host(const SizedBox(width: 300, child: FitLine('Qibla', style: style))));
      expect(shown(tester), 1);
      expect(find.text('Qibla'), findsOneWidget);
    });

    testWidgets('a line a little too long gets smaller, whole', (tester) async {
      await tester.pumpWidget(_host(const SizedBox(width: 170, child: FitLine(ten, style: style))));
      expect(shown(tester), closeTo(0.85, 0.02));
      expect(tester.getSize(find.byType(FitLine)).width, lessThanOrEqualTo(170));
      final paragraph = tester.renderObject<RenderParagraph>(find.byType(RichText));
      expect(paragraph.didExceedMaxLines, isFalse, reason: 'no "…"');
    });

    testWidgets('a line far too long stops at its floor and is cut', (tester) async {
      await tester.pumpWidget(
        _host(const SizedBox(width: 170, child: FitLine('$ten$ten$ten', style: style))),
      );
      expect(shown(tester), closeTo(0.72, 0.01));
      expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).didExceedMaxLines, isTrue);
    });

    testWidgets('larger text may give its growth back before it is cut', (tester) async {
      await tester.pumpWidget(
        _host(const SizedBox(width: 170, child: FitLine(ten, style: style)), textScale: 1.3),
      );
      expect(shown(tester), lessThan(0.72), reason: 'the floor is of the designed size, not of the grown one');
      expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).didExceedMaxLines, isFalse);
    });

    testWidgets('works inside a row that measures its children first', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            child: IntrinsicHeight(
              child: Row(children: [Expanded(child: FitLine(ten, style: style))]),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('TightText stops text growing past its limit', (tester) async {
      await tester.pumpWidget(_host(const TightText(child: Text('a', style: style)), textScale: 2));
      final scaler = MediaQuery.textScalerOf(tester.element(find.byType(Text)));
      expect(scaler.scale(10), 13);
    });
  });
}
