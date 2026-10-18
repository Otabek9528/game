import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'qibla_controller.dart';
import 'qibla_math.dart';
import 'qibla_sensors.dart';

/// The Qibla seen through the camera: hold the phone up and the Kaaba
/// marker stands where the Qibla is, on the horizon, placed with the lens's
/// real field of view. A heading tape runs along the top.
class CameraQiblaView extends StatelessWidget {
  const CameraQiblaView({
    super.key,
    required this.controller,
    required this.feed,
    required this.problem,
    required this.onOpenSettings,
    required this.instruction,
  });

  final QiblaController controller;

  /// Null while the camera starts or when it can't.
  final CameraFeed? feed;
  final CameraProblem? problem;
  final VoidCallback onOpenSettings;

  /// "12° o‘ngga buriling", as above the compass.
  final String instruction;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final feed = this.feed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: Colors.black,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            if (problem != null) {
              return _Problem(
                text: problem == CameraProblem.permission ? s.cameraDenied : s.qiblaCameraFailed,
                action: problem == CameraProblem.permission ? s.openSettings : null,
                onAction: onOpenSettings,
              );
            }
            if (feed == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white54));
            }
            // The picture, upright, covering the box; and how wide the part
            // that shows sees.
            final portraitW = feed.height.toDouble();
            final portraitH = feed.width.toDouble();
            final scale = math.max(size.width / portraitW, size.height / portraitH);
            final hFov = _visible(feed.fovShort, size.width / (portraitW * scale));
            final vFov = _visible(feed.fovLong, size.height / (portraitH * scale));
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: SizedBox(
                      width: portraitW * scale,
                      height: portraitH * scale,
                      child: feed.rotateInApp
                          ? RotatedBox(
                              quarterTurns: feed.sensorOrientation ~/ 90,
                              child: Texture(textureId: feed.textureId),
                            )
                          : Texture(textureId: feed.textureId),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => CustomPaint(
                    painter: _Overlay(
                      heading: controller.heading,
                      cameraUp: controller.reading?.cameraUp ?? 0,
                      qibla: controller.qibla?.bearing ?? 0,
                      hFov: hFov,
                      vFov: vFov,
                      accent: p.accent,
                      font: DefaultTextStyle.of(context).style,
                      textScale: MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final upright = (controller.reading?.tilt ?? 90) >= 50;
                    final aligned = controller.facing == Facing.aligned;
                    return Stack(
                      children: [
                        if (!upright)
                          Center(
                            child: _Chip(
                              icon: Icons.screen_rotation_alt_rounded,
                              text: s.qiblaHoldUpright,
                              color: Colors.black54,
                            ),
                          ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 18,
                          child: Center(
                            child: _Chip(
                              icon: aligned ? Icons.check_circle_rounded : Icons.explore_rounded,
                              text: instruction,
                              color: aligned ? p.action : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The field of view of the part of the picture that shows.
  static double _visible(double fov, double fraction) =>
      2 * math.atan(math.tan(fov / 2 * math.pi / 180) * fraction.clamp(0.0, 1.0)) * 180 / math.pi;
}

class _Overlay extends CustomPainter {
  _Overlay({
    required this.heading,
    required this.cameraUp,
    required this.qibla,
    required this.hFov,
    required this.vFov,
    required this.accent,
    required this.font,
    required this.textScale,
  });

  final TextStyle font;
  final double heading;
  final double cameraUp;
  final double qibla;
  final double hFov;
  final double vFov;
  final Color accent;
  final double textScale;

  static const _rad = math.pi / 180;

  /// Screen x of a direction [d] degrees right of where the camera looks.
  double _x(Size size, double d) => size.width / 2 + size.width / 2 * math.tan(d * _rad) / math.tan(hFov / 2 * _rad);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // The horizon: where a direction level with the eye appears.
    final horizon = (size.height / 2 + size.height / 2 * math.tan(cameraUp * _rad) / math.tan(vFov / 2 * _rad))
        .clamp(70.0, size.height - 90.0);
    final diff = signedDifference(heading, qibla);
    final aligned = diff.abs() <= QiblaController.alignedWithin;
    final gold = aligned ? accent : Brand.gold400;

    // The heading tape.
    final tape = Rect.fromLTWH(0, 0, size.width, 54);
    canvas.drawRect(tape, Paint()..color = Colors.black.withValues(alpha: 0.38));
    final half = hFov / 2 + 5;
    for (var d = (heading - half).floor(); d <= heading + half; d++) {
      if (d % 5 != 0) continue;
      final rel = signedDifference(heading, d.toDouble());
      if (rel.abs() >= 89) continue;
      final x = _x(size, rel);
      final major = d % 15 == 0;
      canvas.drawLine(
        Offset(x, 54),
        Offset(x, major ? 38 : 46),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.9 : 0.5)
          ..strokeWidth = major ? 1.6 : 1,
      );
      if (major) {
        final n = normalizeDegrees(d.toDouble()).round() % 360;
        final label = switch (n) { 0 => 'N', 90 => 'E', 180 => 'S', 270 => 'W', _ => '$n' };
        _text(canvas, label, Offset(x, 22), 12.5 * textScale, n % 90 == 0 ? Brand.gold300 : Colors.white);
      }
    }
    // The heading's own mark, and the Qibla's on the tape.
    canvas.drawPath(
      Path()
        ..moveTo(cx, 54)
        ..lineTo(cx - 7, 64)
        ..lineTo(cx + 7, 64)
        ..close(),
      Paint()..color = Colors.white,
    );

    // The centre line the Qibla should come to.
    final centre = Paint()
      ..color = (aligned ? accent : Colors.white).withValues(alpha: 0.75)
      ..strokeWidth = aligned ? 3 : 1.5;
    for (var y = 70.0; y < size.height - 70; y += 14) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 7), centre);
    }

    if (diff.abs() < hFov / 2) {
      // In sight: the Kaaba on the horizon, with a beam down to it.
      final x = _x(size, diff);
      canvas.drawLine(
        Offset(x, 64),
        Offset(x, horizon),
        Paint()
          ..strokeWidth = 3
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gold.withValues(alpha: 0), gold],
          ).createShader(Rect.fromLTRB(x - 2, 64, x + 2, horizon)),
      );
      canvas.drawCircle(Offset(x, horizon), 34, Paint()..color = gold.withValues(alpha: 0.22));
      final s = 34.0;
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, horizon), width: s, height: s),
        const Radius.circular(4),
      );
      canvas.drawRRect(body, Paint()..color = const Color(0xFF16130F));
      canvas.drawRect(Rect.fromLTWH(x - s / 2, horizon - s * 0.22, s, s * 0.14), Paint()..color = Brand.gold400);
      canvas.drawRRect(body, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = gold);
      _text(canvas, 'QIBLA', Offset(x, horizon + 32), 12 * textScale, gold, bold: true);
      // Its tick on the tape.
      canvas.drawCircle(Offset(x, 58), 4, Paint()..color = gold);
    } else {
      // Out of sight: an arrow on the side to turn to.
      final right = diff > 0;
      final x = right ? size.width - 26 : 26.0;
      final y = horizon;
      final arrow = Path()
        ..moveTo(x + (right ? 14 : -14), y)
        ..lineTo(x + (right ? -8 : 8), y - 16)
        ..lineTo(x + (right ? -8 : 8), y + 16)
        ..close();
      canvas.drawCircle(Offset(x, y), 26, Paint()..color = Colors.black.withValues(alpha: 0.45));
      canvas.drawPath(arrow, Paint()..color = Brand.gold300);
      _text(canvas, '${diff.abs().round()}°', Offset(x, y + 40), 13 * textScale, Colors.white, bold: true);
    }
  }

  void _text(Canvas canvas, String text, Offset at, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: font.merge(TextStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
        )),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_Overlay old) =>
      old.heading != heading || old.cameraUp != cameraUp || old.qibla != qibla || old.hFov != hFov;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 16, 9),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.text, required this.action, required this.onAction});

  final String text;
  final String? action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
            if (action != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
