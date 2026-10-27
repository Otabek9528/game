import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/core/widgets/brand_logos.dart';

void main() {
  group('reading SVG paths', () {
    test('absolute and relative lines, horizontal and vertical', () {
      expect(svgPath('M0 0h10v10H0z').getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
      expect(svgPath('m1 1 2 0 0 2z').getBounds(), const Rect.fromLTRB(1, 1, 3, 3), reason: 'pairs after a move are lines');
    });

    test('numbers run together, as minified paths write them', () {
      expect(svgPath('M0-.5.5.5').getBounds(), const Rect.fromLTRB(0, -0.5, 0.5, 0.5));
      expect(svgPath('M1e1 0L0 1E1').getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
    });

    test('arc flags touching the next number', () {
      // From (0, 0) to (10, 0) on a radius of 5: a half circle. The sweep
      // flag goes through growing angles, which on a y-down screen is up.
      final above = svgPath('M0 0a5 5 0 0110 0').getBounds();
      expect(above.top, closeTo(-5, 0.1));
      expect(above.bottom, closeTo(0, 0.1));
      final below = svgPath('M0 0a5 5 0 0010 0').getBounds();
      expect(below.bottom, closeTo(5, 0.1));
    });

    test('smooth curves mirror the last control point', () {
      final b = svgPath('M0 0c0 10 10 10 10 0s10-10 10 0').getBounds();
      expect(b.left, 0);
      expect(b.right, 20);
      expect(b.top, lessThan(-5));
      expect(b.bottom, greaterThan(5));
    });
  });

  testWidgets('every logo draws', (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [for (final logo in BrandLogo.values) BrandLogoMark(logo, size: 40)]),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(BrandLogoMark), findsNWidgets(BrandLogo.values.length));
  });
}
