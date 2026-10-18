import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// The compass: a rose that turns with the phone (north stays north), the
/// Kaaba on its ring at the Qibla's bearing, the sun where it stands, an arc
/// for how far to turn, and in the hub the heading over a spirit level.
class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.heading,
    required this.qibla,
    required this.aligned,
    required this.cardinals,
    required this.headingLabel,
    this.accuracy,
    this.sunAzimuth,
    this.levelX = 0,
    this.levelY = 0,
  });

  /// Degrees from true north the phone faces.
  final double heading;
  final double qibla;
  final bool aligned;

  /// Names under N, E, S, W.
  final List<String> cardinals;
  final String headingLabel;

  /// "±4°", or null when unknown.
  final String? accuracy;

  /// Where the sun is, when it is up.
  final double? sunAzimuth;

  /// The level's bubble, −1…1 (right, toward the top).
  final double levelX;
  final double levelY;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.maxWidth;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _DialPainter(
                  heading: heading,
                  qibla: qibla,
                  aligned: aligned,
                  cardinals: cardinals,
                  sunAzimuth: sunAzimuth,
                  palette: p,
                  font: DefaultTextStyle.of(context).style,
                  textScale: MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
                ),
              ),
              _Hub(
                size: size * 0.36,
                heading: heading,
                label: headingLabel,
                accuracy: accuracy,
                aligned: aligned,
                levelX: levelX,
                levelY: levelY,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.heading,
    required this.qibla,
    required this.aligned,
    required this.cardinals,
    required this.sunAzimuth,
    required this.palette,
    required this.font,
    required this.textScale,
  });

  /// The app's text style: a painter has no theme of its own.
  final TextStyle font;
  final double heading;
  final double qibla;
  final bool aligned;
  final List<String> cardinals;
  final double? sunAzimuth;
  final VegukinPalette palette;
  final double textScale;

  static const _rad = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ring = r * 0.86;
    final glow = aligned ? p.accent : Brand.gold400;

    // Face and bezel.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [p.card, Color.lerp(p.card, p.page, 0.7)!]).createShader(
          Rect.fromCircle(center: c, radius: r),
        ),
    );
    canvas.drawCircle(
      c,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = aligned ? p.accent.withValues(alpha: 0.7) : p.hairlineStrong,
    );
    canvas.drawCircle(
      c,
      ring - r * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = p.hairline,
    );

    // How far to turn: from the top of the dial to the Qibla.
    final diff = _signed(heading, qibla);
    final arcRect = Rect.fromCircle(center: c, radius: ring - r * 0.07);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      diff * _rad,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round
        ..color = glow.withValues(alpha: aligned ? 0.35 : 0.22),
    );

    // The rose turns: north stays north.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-heading * _rad);

    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      final mid = d % 10 == 0;
      final len = major ? r * 0.09 : mid ? r * 0.06 : r * 0.035;
      final a = d * _rad;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        dir * ring,
        dir * (ring - len),
        Paint()
          ..strokeWidth = major ? 2 : 1.2
          ..color = d == 0 ? Brand.gold500 : (major ? p.inkSoft : p.inkMuted.withValues(alpha: 0.6)),
      );
    }

    // Degrees every 30°, and the four cardinals with their names.
    for (var d = 0; d < 360; d += 30) {
      final a = d * _rad;
      final dir = Offset(math.sin(a), -math.cos(a));
      if (d % 90 == 0) {
        final i = d ~/ 90;
        // Letter over name, stacked on the screen however the rose turns.
        _stack(
          canvas,
          dir * (ring - r * 0.24),
          const ['N', 'E', 'S', 'W'][i],
          TextStyle(fontSize: r * 0.13, fontWeight: FontWeight.w800, color: i == 0 ? Brand.gold500 : p.ink),
          cardinals[i],
          TextStyle(fontSize: r * 0.052 * textScale, fontWeight: FontWeight.w600, color: p.inkMuted),
        );
      } else {
        _text(
          canvas,
          '$d',
          dir * (ring - r * 0.17),
          TextStyle(fontSize: r * 0.06 * textScale, fontWeight: FontWeight.w600, color: p.inkMuted),
          upright: true,
        );
      }
    }

    // The sun, where it stands.
    if (sunAzimuth != null) {
      final a = sunAzimuth! * _rad;
      final at = Offset(math.sin(a), -math.cos(a)) * (ring + r * 0.065);
      final sun = Paint()..color = Brand.gold400;
      canvas.drawCircle(at, r * 0.03, sun);
      for (var k = 0; k < 8; k++) {
        final t = k * math.pi / 4;
        final ray = Offset(math.cos(t), math.sin(t));
        canvas.drawLine(
          at + ray * r * 0.042,
          at + ray * r * 0.058,
          sun..strokeWidth = 1.6,
        );
      }
    }

    // The needle to the Kaaba, and the Kaaba on the ring.
    final qa = qibla * _rad;
    final qdir = Offset(math.sin(qa), -math.cos(qa));
    canvas.drawLine(
      qdir * r * 0.2,
      qdir * (ring - r * 0.16),
      Paint()
        ..strokeWidth = r * 0.022
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [glow.withValues(alpha: 0.15), glow]).createShader(
          Rect.fromPoints(qdir * r * 0.2, qdir * ring),
        ),
    );
    _kaaba(canvas, qdir * (ring - r * 0.04), r * 0.1, heading * _rad);
    canvas.restore();

    // The phone's own direction: fixed at the top.
    final tip = Offset(c.dx, c.dy - r + r * 0.02);
    final marker = Path()
      ..moveTo(tip.dx, tip.dy + r * 0.13)
      ..lineTo(tip.dx - r * 0.06, tip.dy)
      ..lineTo(tip.dx + r * 0.06, tip.dy)
      ..close();
    canvas.drawPath(marker, Paint()..color = aligned ? p.accent : p.ink);
  }

  /// A small Kaaba: a black cube with its gold band, kept upright.
  void _kaaba(Canvas canvas, Offset at, double s, double rotation) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rotation);
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s, height: s), Radius.circular(s * 0.12));
    canvas.drawRRect(body.shift(Offset(0, s * 0.06)), Paint()..color = Colors.black26);
    canvas.drawRRect(body, Paint()..color = const Color(0xFF16130F));
    canvas.drawRect(
      Rect.fromLTWH(-s / 2, -s * 0.22, s, s * 0.14),
      Paint()..color = Brand.gold400,
    );
    canvas.drawRect(
      Rect.fromLTWH(-s * 0.12, s * 0.05, s * 0.24, s * 0.45),
      Paint()..color = Brand.gold500.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  void _stack(Canvas canvas, Offset at, String top, TextStyle topStyle, String bottom, TextStyle bottomStyle) {
    TextPainter layout(String text, TextStyle style) =>
        TextPainter(text: TextSpan(text: text, style: font.merge(style)), textDirection: TextDirection.ltr)..layout();
    final a = layout(top, topStyle);
    final b = layout(bottom, bottomStyle);
    final height = a.height + b.height * 0.85;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(heading * _rad);
    a.paint(canvas, Offset(-a.width / 2, -height / 2));
    b.paint(canvas, Offset(-b.width / 2, -height / 2 + a.height * 0.92));
    canvas.restore();
  }

  void _text(Canvas canvas, String text, Offset at, TextStyle style, {bool upright = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: font.merge(style)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    if (upright) canvas.rotate(heading * _rad);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  static double _signed(double from, double to) {
    var d = (to - from) % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.heading != heading ||
      old.qibla != qibla ||
      old.aligned != aligned ||
      old.sunAzimuth != sunAzimuth ||
      old.palette != palette;
}

/// The middle of the dial: the heading in large numbers, over a level whose
/// bubble shows when the phone lies flat.
class _Hub extends StatelessWidget {
  const _Hub({
    required this.size,
    required this.heading,
    required this.label,
    required this.accuracy,
    required this.aligned,
    required this.levelX,
    required this.levelY,
  });

  final double size;
  final double heading;
  final String label;
  final String? accuracy;
  final bool aligned;
  final double levelX;
  final double levelY;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    // Up leaning right moves the bubble right; up toward the top edge moves
    // it up the screen.
    final reach = size * 0.36;
    final dx = (levelX * 2).clamp(-1.0, 1.0) * reach;
    final dy = (-levelY * 2).clamp(-1.0, 1.0) * reach;
    // Lying flat the hub stays clean; tilted, a level shows which way.
    final level = math.sqrt(dx * dx + dy * dy) < size * 0.07;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: aligned ? p.cardSelected : p.card,
        border: Border.all(color: aligned ? p.accent : p.hairlineStrong, width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!level) ...[
            Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: p.hairlineStrong),
              ),
            ),
            Transform.translate(
              offset: Offset(dx, dy),
              child: Container(
                width: size * 0.13,
                height: size * 0.13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Brand.gold500, width: 1.6),
                ),
              ),
            ),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  '${heading.round() % 360}°',
                  style: TextStyle(
                    fontSize: size * 0.26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: aligned ? p.accent : p.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(height: size * 0.03),
              Text(
                accuracy == null ? label : '$label  $accuracy',
                style: TextStyle(fontSize: size * 0.085, fontWeight: FontWeight.w600, color: p.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
