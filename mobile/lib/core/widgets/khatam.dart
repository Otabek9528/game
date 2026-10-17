import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The eight-pointed star (khatam) the web app already uses as its progress
/// marker. It is the brand mark here too: simple enough to read at launcher
/// icon size, and familiar from mosque tilework.
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

/// The app mark: a gold khatam with an emerald one cut into it and a small
/// gold one at the heart, on an emerald disc.
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
    final outer = size.width * 0.62;
    final outerRect = Rect.fromCenter(center: c, width: outer, height: outer);

    canvas.drawPath(
      khatamPath(c, outer),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.gold300, Brand.gold500],
        ).createShader(outerRect),
    );
    canvas.drawPath(
      khatamPath(c, outer * 0.64),
      Paint()..color = Brand.emerald800,
    );
    canvas.drawPath(
      khatamPath(c, outer * 0.28, rotation: math.pi / 8),
      Paint()..color = Brand.gold300,
    );
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
