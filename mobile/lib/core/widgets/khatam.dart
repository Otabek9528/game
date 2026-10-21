import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The eight-pointed star (khatam) the web app already uses as its progress
/// marker. It is the heart of the brand mark too ([Emblem]): simple enough
/// to read at launcher icon size, and familiar from mosque tilework.
///
/// Points are on a 16×16 grid, the same path as index.html's progress dot.
const _khatamPoints = <Offset>[
  Offset(8.00, 0.00), Offset(10.34, 2.34), Offset(13.66, 2.34),
  Offset(13.66, 5.66), Offset(16.00, 8.00), Offset(13.66, 10.34),
  Offset(13.66, 13.66), Offset(10.34, 13.66), Offset(8.00, 16.00),
  Offset(5.66, 13.66), Offset(2.34, 13.66), Offset(2.34, 10.34),
  Offset(0.00, 8.00), Offset(2.34, 5.66), Offset(2.34, 2.34),
  Offset(5.66, 2.34),
];

/// A khatam [size] wide, centred on [center], turned by [rotation] radians.
Path khatamPath(Offset center, double size, {double rotation = 0}) {
  final scale = size / 16;
  final cosR = math.cos(rotation);
  final sinR = math.sin(rotation);
  final path = Path();
  for (var i = 0; i < _khatamPoints.length; i++) {
    final dx = (_khatamPoints[i].dx - 8) * scale;
    final dy = (_khatamPoints[i].dy - 8) * scale;
    final x = center.dx + dx * cosR - dy * sinR;
    final y = center.dy + dx * sinR + dy * cosR;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}

/// The emblem's shapes, in units of the star's half-width (centre to tip).
/// tool/emblem.py draws the Android icon and splash from the same numbers;
/// change both together.
abstract final class Emblem {
  /// The emerald star cut into the gold one.
  static const ringCut = 0.76;
  static const mWidth = 0.62;
  static const mHeight = 0.40;

  /// Below the star's centre, to make room for the roof.
  static const mCentre = 0.13;

  /// Of the M's width.
  static const mStem = 0.21;

  /// The V's arms leave the top a little wider than the stems.
  static const mFlare = 1.12;

  /// Depth of the M's top valley, and where the V's underside meets the
  /// stems, of the M's height.
  static const mNotch = 0.50;
  static const mJoin = 0.30;

  /// The small star at the heart, where the opening starts.
  static const heartStar = 0.28;

  /// The roof, front view: a level ridge, hips that sag as they run down,
  /// and eave corners that lift; the eave line is lowest in the middle.
  /// [roofEave]: that lowest point, from the star's centre; the ridge and
  /// the corners are [roofHeight] and [roofLift] above it.
  static const roofEave = -0.10;
  static const roofHeight = 0.17;
  static const roofLift = 0.08;
  static const roofWidth = 0.92;

  /// Half the ridge's length.
  static const roofRidge = 0.26;

  /// Where the hips' and the eave line's curves are pulled to.
  static const roofSag = 0.25;
  static const roofCurve = 0.50;

  static const cream = Color(0xFFFFF6E0);

  /// The gold star with the emerald one cut out of it: a ring.
  static Path ring(Offset center, double radius, {double rotation = 0}) => Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(khatamPath(center, radius * 2, rotation: rotation), Offset.zero)
    ..addPath(khatamPath(center, radius * 2 * ringCut, rotation: rotation), Offset.zero);

  /// A hanok roof: with the M's stems for pillars, a Korean house.
  static Path roof(Offset center, double radius) {
    final half = roofWidth * radius / 2;
    final ridge = roofRidge * radius;
    final eave = center.dy + roofEave * radius;
    final top = eave - roofHeight * radius;
    final corner = eave - roofLift * radius;
    final x = center.dx;
    double hip(double side) => x + side * (ridge + roofSag * (half - ridge));
    return Path()
      ..moveTo(x + ridge, top)
      ..quadraticBezierTo(hip(1), corner, x + half, corner)
      ..quadraticBezierTo(x + roofCurve * half, eave, x, eave)
      ..quadraticBezierTo(x - roofCurve * half, eave, x - half, corner)
      ..quadraticBezierTo(hip(-1), corner, x - ridge, top)
      ..close();
  }

  /// The M's two stems, and the V that is its middle: M for Muslim, V for
  /// Vegukin.
  static (Path stems, Path v) monogram(Offset center, double radius) {
    final w = mWidth * radius;
    final h = mHeight * radius;
    final origin = center + Offset(-w / 2, mCentre * radius - h / 2);
    Offset p(double x, double y) => origin + Offset(x * w, y * h);
    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
    const t = mStem;
    const a = mStem * mFlare;
    final stems = polygon([p(0, 0), p(t, 0), p(t, 1), p(0, 1)])
      ..addPolygon([p(1 - t, 0), p(1, 0), p(1, 1), p(1 - t, 1)], true);
    final v = polygon([
      p(t, 0), p(a, 0), p(0.5, mNotch), p(1 - a, 0), p(1 - t, 0), //
      p(1 - t, mJoin), p(0.5, 1), p(t, mJoin),
    ]);
    return (stems, v);
  }

  /// The gold of the ring: light top-left, deep bottom-right.
  static Shader gold(Offset center, double radius) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Brand.gold300, Brand.gold500],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
}

/// The app mark, on an emerald disc: a gold khatam with an emerald one cut
/// into it, and in its heart a Korean house whose pillars and gold V spell
/// M·V. Islam's star, around a home in Korea, that spells the name.
class KhatamMark extends StatelessWidget {
  const KhatamMark({super.key, this.size = 96, this.glow = true});

  final double size;

  /// A soft gold halo, for when the mark sits on the dark hero.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Brand.emerald700, Brand.emerald900],
          stops: [0.0, 1.0],
        ),
        border: Border.all(
          color: Brand.gold300.withValues(alpha: 0.55),
          width: size * 0.016,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Brand.gold400.withValues(alpha: 0.28),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.02,
                ),
              ]
            : null,
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.35;
    canvas.drawPath(khatamPath(c, r * 2 * Emblem.ringCut), Paint()..color = Brand.emerald800);
    canvas.drawPath(Emblem.ring(c, r), Paint()..shader = Emblem.gold(c, r));
    canvas.drawPath(Emblem.roof(c, r), Paint()..color = Brand.gold300);
    final (stems, v) = Emblem.monogram(c, r);
    canvas.drawPath(stems, Paint()..color = Emblem.cream);
    canvas.drawPath(v, Paint()..color = Brand.gold400);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

/// Faint tilework: a lattice of small star outlines.
class KhatamLatticePainter extends CustomPainter {
  const KhatamLatticePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gap = 46.0;
    const star = 15.0;
    var row = 0;
    for (var y = gap / 2; y < size.height + gap; y += gap * 0.5, row++) {
      final shift = row.isEven ? 0.0 : gap / 2;
      for (var x = shift; x < size.width + gap; x += gap) {
        canvas.drawPath(khatamPath(Offset(x, y), star), paint);
      }
    }
  }

  @override
  bool shouldRepaint(KhatamLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// [child] framed by a large rosette — two khatams, one turned, twice over —
/// drawn outside the child's own box so it doesn't push anything around.
class KhatamRosette extends StatelessWidget {
  const KhatamRosette({
    super.key,
    required this.color,
    required this.size,
    required this.child,
  });

  final Color color;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              maxWidth: size,
              maxHeight: size,
              child: CustomPaint(
                size: Size.square(size),
                painter: _RosettePainter(color),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final scale in const [1.0, 0.72]) {
      final s = size.width * scale;
      canvas.drawPath(khatamPath(c, s), paint);
      canvas.drawPath(khatamPath(c, s, rotation: math.pi / 8), paint);
    }
  }

  @override
  bool shouldRepaint(_RosettePainter oldDelegate) => oldDelegate.color != color;
}
