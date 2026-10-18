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
    required this.markerLabel,
  });

  final QiblaController controller;

  /// Null while the camera starts or when it can't.
  final CameraFeed? feed;
  final CameraProblem? problem;
  final VoidCallback onOpenSettings;

  /// "12° o‘ngga buriling", as above the compass.
  final String instruction;

  /// Under the Kaaba marker: "Qibla · 3 466 km".
  final String markerLabel;

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
                      label: markerLabel,
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final upright = (controller.reading?.tilt ?? 90) >= 50;
                    final aligned = controller.facing == Facing.aligned;
                    final diff = controller.difference;
                    final warning = switch (controller.issue) {
                      SignalIssue.interference => s.qiblaInterference,
                      SignalIssue.needsCalibration => s.qiblaNeedsCalibration,
                      _ => null,
                    };
                    return Stack(
                      children: [
                        if (warning != null)
                          Positioned(
                            top: 92,
                            right: 12,
                            child: _Chip(
                              icon: Icons.warning_amber_rounded,
                              text: warning,
                              color: const Color(0xCC8A4B08),
                              small: true,
                            ),
                          ),
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
                              icon: aligned
                                  ? Icons.check_circle_rounded
                                  : diff > 0
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_back_rounded,
                              text: instruction,
                              color: aligned ? p.action : Colors.black.withValues(alpha: 0.62),
                              // The far instruction already says how far.
                              badge: aligned || controller.facing == Facing.far ? null : '${diff.abs().round()}°',
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
    required this.label,
  });

  /// Under the Kaaba: "Qibla · 3 466 km".
  final String label;
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

    // The heading tape, fading into the picture.
    const tapeH = 52.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, tapeH + 26),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, tapeH + 26)),
    );
    final half = hFov / 2 + 5;
    for (var d = (heading - half).floor(); d <= heading + half; d++) {
      if (d % 5 != 0) continue;
      final rel = signedDifference(heading, d.toDouble());
      if (rel.abs() >= 89) continue;
      final x = _x(size, rel);
      final major = d % 15 == 0;
      canvas.drawLine(
        Offset(x, tapeH),
        Offset(x, major ? tapeH - 14 : tapeH - 7),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.9 : 0.45)
          ..strokeWidth = major ? 1.6 : 1,
      );
      if (major) {
        final n = normalizeDegrees(d.toDouble()).round() % 360;
        final label = switch (n) { 0 => 'N', 90 => 'E', 180 => 'S', 270 => 'W', _ => '$n' };
        _text(canvas, label, Offset(x, 20), 12.5 * textScale, n % 90 == 0 ? Brand.gold300 : Colors.white);
      }
    }
    // The Qibla's place on the tape: a small Kaaba.
    if (diff.abs() < half) _kaaba(canvas, Offset(_x(size, diff), tapeH - 3), 11, gold);

    // Where the phone looks: a pointer and the heading, read out.
    canvas.drawPath(
      Path()
        ..moveTo(cx, tapeH)
        ..lineTo(cx - 6, tapeH + 8)
        ..lineTo(cx + 6, tapeH + 8)
        ..close(),
      Paint()..color = Colors.white,
    );
    _pill(canvas, Offset(cx, tapeH + 21), '${heading.round() % 360}°', Colors.white, Colors.black87, 14);

    // The horizon, which the Kaaba sits on.
    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1,
    );

    // The aim: a ring on the horizon the Kaaba should come into.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = aligned ? 3 : 1.6
      ..color = (aligned ? accent : Colors.white).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx, horizon), 30, ring);
    for (final dy in const [-1.0, 1.0]) {
      canvas.drawLine(Offset(cx, horizon + dy * 34), Offset(cx, horizon + dy * 46), ring);
    }

    if (diff.abs() < hFov / 2) {
      // In sight: the Kaaba on the horizon, a thin beam from its tape mark.
      final x = _x(size, diff);
      canvas.drawLine(
        Offset(x, tapeH + 30),
        Offset(x, horizon - 24),
        Paint()
          ..strokeWidth = 2
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gold.withValues(alpha: 0), gold.withValues(alpha: 0.9)],
          ).createShader(Rect.fromLTRB(x - 1, tapeH + 30, x + 1, horizon)),
      );
      canvas.drawCircle(Offset(x, horizon), aligned ? 40 : 34, Paint()..color = gold.withValues(alpha: aligned ? 0.3 : 0.18));
      _kaaba(canvas, Offset(x, horizon), 40, gold);
      _pill(canvas, Offset(x, horizon + 44), label, Colors.black.withValues(alpha: 0.62), Colors.white, 13, accentText: gold);
    } else {
      // Out of sight: an arrow on the side to turn to, with how far.
      final right = diff > 0;
      final x = right ? size.width - 30 : 30.0;
      final y = horizon;
      canvas.drawCircle(Offset(x, y), 26, Paint()..color = Colors.black.withValues(alpha: 0.5));
      canvas.drawPath(
        Path()
          ..moveTo(x + (right ? 13 : -13), y)
          ..lineTo(x + (right ? -7 : 7), y - 14)
          ..lineTo(x + (right ? -7 : 7), y + 14)
          ..close(),
        Paint()..color = Brand.gold300,
      );
      _pill(canvas, Offset(x, y + 42), '${diff.abs().round()}°', Colors.black.withValues(alpha: 0.62), Colors.white, 13);
    }
  }

  /// A Kaaba: black cube, gold band and door, gold edge.
  void _kaaba(Canvas canvas, Offset at, double s, Color edge) {
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: s, height: s), Radius.circular(s * 0.1));
    canvas.drawRRect(body.shift(Offset(0, s * 0.06)), Paint()..color = Colors.black38);
    canvas.drawRRect(body, Paint()..color = const Color(0xFF16130F));
    canvas.drawRect(Rect.fromLTWH(at.dx - s / 2, at.dy - s * 0.24, s, s * 0.14), Paint()..color = Brand.gold400);
    canvas.drawRect(
      Rect.fromLTWH(at.dx - s * 0.1, at.dy + s * 0.08, s * 0.2, s * 0.42),
      Paint()..color = Brand.gold500.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s > 20 ? 2 : 1
        ..color = edge,
    );
  }

  /// Text on a rounded pill, centred on [at]; the part before "·" in
  /// [accentText] colour when given.
  void _pill(Canvas canvas, Offset at, String text, Color bg, Color fg, double size, {Color? accentText}) {
    final dot = text.indexOf('·');
    final style = font.merge(TextStyle(fontSize: size * textScale, fontWeight: FontWeight.w700, color: fg));
    final tp = TextPainter(
      text: accentText == null || dot < 0
          ? TextSpan(text: text, style: style)
          : TextSpan(children: [
              TextSpan(text: text.substring(0, dot), style: style.copyWith(color: accentText)),
              TextSpan(text: text.substring(dot), style: style),
            ]),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(center: at, width: tp.width + 22, height: tp.height + 10);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(999)), Paint()..color = bg);
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
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
      old.heading != heading ||
      old.cameraUp != cameraUp ||
      old.qibla != qibla ||
      old.hFov != hFov ||
      old.label != label;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color, this.badge, this.small = false});

  final IconData icon;
  final String text;
  final Color color;

  /// "12°", set off at the end.
  final String? badge;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small ? const EdgeInsets.fromLTRB(9, 6, 12, 6) : const EdgeInsets.fromLTRB(12, 9, 9, 9),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: small ? 16 : 20),
          SizedBox(width: small ? 6 : 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: small ? 12.5 : 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ] else if (!small)
            const SizedBox(width: 7),
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
