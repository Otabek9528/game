import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'camera_projection.dart';
import 'qibla_controller.dart';
import 'qibla_math.dart';
import 'qibla_sensors.dart';

/// The Qibla seen through the camera, edge to edge: hold the phone up and
/// the Kaaba marker stands where the Qibla is, on the horizon, placed with
/// the lens's real field of view. A heading tape runs along the top. By day
/// a ring marks where the sun should be; if the real sun is elsewhere, a
/// tap on it corrects the compass.
class CameraQiblaView extends StatefulWidget {
  const CameraQiblaView({
    super.key,
    required this.controller,
    required this.feed,
    required this.problem,
    required this.onOpenSettings,
    required this.instruction,
    required this.markerLabel,
    this.insets = EdgeInsets.zero,
  });

  final QiblaController controller;

  /// Null while the camera starts or when it can't.
  final CameraFeed? feed;
  final CameraProblem? problem;
  final VoidCallback onOpenSettings;

  /// "Biroz chapga buriling", as above the compass.
  final String instruction;

  /// Under the Kaaba marker: "Qibla · 3 466 km".
  final String markerLabel;

  /// What the page's bar and switch cover at the top, and the system bar
  /// at the bottom.
  final EdgeInsets insets;

  @override
  State<CameraQiblaView> createState() => _CameraQiblaViewState();
}

class _CameraQiblaViewState extends State<CameraQiblaView> {
  /// How far above or below the sun's height a tap may be and still count
  /// as the sun.
  static const _sunBand = 8.0;

  String? _note;
  Timer? _noteTimer;

  @override
  void dispose() {
    _noteTimer?.cancel();
    super.dispose();
  }

  void _say(String text) {
    _noteTimer?.cancel();
    setState(() => _note = text);
    _noteTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _note = null);
    });
  }

  void _tap(Offset at, CameraPose pose) {
    final c = widget.controller;
    final sun = c.sun;
    if (sun == null || !sun.up) return;
    final (azimuth, elevation) = pose.unproject(at);
    // The sun's height is known exactly and no magnet changes it: a tap
    // far from it is not on the sun.
    if ((elevation - sun.elevation).abs() > _sunBand || pose.pitch.abs() > 80) {
      _say(AppLocalizations.of(context).qiblaSunNotThere);
      return;
    }
    HapticFeedback.mediumImpact();
    _noteTimer?.cancel();
    setState(() => _note = null);
    c.correctBySun(azimuth);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final feed = widget.feed;
    final problem = widget.problem;
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          if (problem != null) {
            return Padding(
              padding: widget.insets,
              child: _Problem(
                text: problem == CameraProblem.permission ? s.cameraDenied : s.qiblaCameraFailed,
                action: problem == CameraProblem.permission ? s.openSettings : null,
                onAction: widget.onOpenSettings,
              ),
            );
          }
          if (feed == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white54));
          }
          // The picture, upright, covering the screen; and how wide the part
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
                listenable: widget.controller,
                builder: (context, _) => _overlay(context, size, hFov, vFov),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _overlay(BuildContext context, Size size, double hFov, double vFov) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = widget.controller;
    final r = c.reading;
    final upright = (r?.tilt ?? 90) >= 50;
    final pose = CameraPose(
      heading: c.heading,
      pitch: r?.cameraUp ?? 0,
      // Lying nearly flat the roll means nothing.
      roll: r == null || r.tilt < 20 ? 0 : math.atan2(r.levelX, r.levelY) * 180 / math.pi,
      hFov: hFov,
      vFov: vFov,
      size: size,
    );
    final sun = c.sun;
    final sunUp = sun != null && sun.up;
    // The sun's height crosses the picture: the user is looking near it.
    final sunLevel = sunUp ? pose.project(c.heading, sun.elevation) : null;
    final sunInFrame =
        sunLevel != null && sunLevel.dy > widget.insets.top + 90 && sunLevel.dy < size.height - widget.insets.bottom - 90;
    final aligned = c.facing == Facing.aligned;
    final diff = c.difference;
    final warning = switch (c.issue) {
      SignalIssue.interference => s.qiblaInterference,
      SignalIssue.needsCalibration => s.qiblaNeedsCalibration,
      _ => null,
    };
    final degrees = c.correction.abs().round();
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _tap(d.localPosition, pose),
          child: CustomPaint(
            painter: _Overlay(
              pose: pose,
              qibla: c.qibla?.bearing ?? 0,
              aligned: aligned,
              accent: p.accent,
              font: DefaultTextStyle.of(context).style,
              textScale: MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
              label: widget.markerLabel,
              sun: sunUp ? sun : null,
              sunLabel: s.qiblaSunMarker,
              insets: widget.insets,
            ),
          ),
        ),
        if (warning != null)
          Positioned(
            top: widget.insets.top + 96,
            right: 12,
            child: _Chip(icon: Icons.warning_amber_rounded, text: warning, color: const Color(0xCC8A4B08), small: true),
          ),
        if (!upright)
          Center(
            child: _Chip(icon: Icons.screen_rotation_alt_rounded, text: s.qiblaHoldUpright, color: Colors.black54),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: widget.insets.bottom + 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (degrees > 0)
                _Chip(
                  icon: Icons.wb_sunny_rounded,
                  text: s.qiblaSunCorrected('${c.correction >= 0 ? '+' : '−'}$degrees'),
                  color: Colors.black.withValues(alpha: 0.62),
                  small: true,
                  action: s.qiblaUndo,
                  onAction: () {
                    HapticFeedback.selectionClick();
                    c.clearCorrection();
                  },
                )
              else if (_note != null)
                _Chip(icon: Icons.info_outline_rounded, text: _note!, color: const Color(0xCC8A4B08), small: true)
              else if (sunInFrame)
                _Chip(
                  icon: Icons.wb_sunny_rounded,
                  text: s.qiblaSunTapHint,
                  color: Colors.black.withValues(alpha: 0.55),
                  small: true,
                ),
              const SizedBox(height: 10),
              _Chip(
                icon: aligned
                    ? Icons.check_circle_rounded
                    : diff > 0
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                text: widget.instruction,
                color: aligned ? p.action : Colors.black.withValues(alpha: 0.62),
                badge: aligned ? null : '${diff.abs().round()}°',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The field of view of the part of the picture that shows.
  static double _visible(double fov, double fraction) =>
      2 * math.atan(math.tan(fov / 2 * math.pi / 180) * fraction.clamp(0.0, 1.0)) * 180 / math.pi;
}

class _Overlay extends CustomPainter {
  _Overlay({
    required this.pose,
    required this.qibla,
    required this.aligned,
    required this.accent,
    required this.font,
    required this.textScale,
    required this.label,
    required this.sun,
    required this.sunLabel,
    required this.insets,
  });

  final CameraPose pose;
  final double qibla;
  final bool aligned;
  final Color accent;

  /// The app's text style: a painter has no theme of its own.
  final TextStyle font;
  final double textScale;

  /// Under the Kaaba: "Qibla · 3 466 km".
  final String label;

  /// Where the sun stands, when it is up.
  final SunPosition? sun;
  final String sunLabel;
  final EdgeInsets insets;

  static const _rad = math.pi / 180;
  static const _tapeH = 52.0;

  /// Screen x on the tape of a direction [d] degrees right of the heading.
  double _x(Size size, double d) =>
      size.width / 2 + size.width / 2 * math.tan(d * _rad) / math.tan(pose.hFov / 2 * _rad);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = insets.top;
    final heading = pose.heading;
    final diff = signedDifference(heading, qibla);
    final gold = aligned ? accent : Brand.gold400;
    // Where the horizon's marks may sit, clear of the tape and of the two
    // chips at the bottom.
    final lo = top + _tapeH + 70;
    final hi = size.height - insets.bottom - 170;

    // A scrim under the bar, the switch and the tape.
    final scrim = Rect.fromLTWH(0, 0, size.width, top + _tapeH + 34);
    canvas.drawRect(
      scrim,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0),
          ],
          stops: [0, (top / scrim.height).clamp(0.0, 0.9), 1],
        ).createShader(scrim),
    );

    // The heading tape.
    final half = pose.hFov / 2 + 5;
    for (var d = (heading - half).floor(); d <= heading + half; d++) {
      if (d % 5 != 0) continue;
      final rel = signedDifference(heading, d.toDouble());
      if (rel.abs() >= 89) continue;
      final x = _x(size, rel);
      final major = d % 15 == 0;
      canvas.drawLine(
        Offset(x, top + _tapeH),
        Offset(x, top + (major ? _tapeH - 14 : _tapeH - 7)),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.9 : 0.45)
          ..strokeWidth = major ? 1.6 : 1,
      );
      if (major) {
        final n = normalizeDegrees(d.toDouble()).round() % 360;
        final text = switch (n) { 0 => 'N', 90 => 'E', 180 => 'S', 270 => 'W', _ => '$n' };
        _text(canvas, text, Offset(x, top + 20), 12.5 * textScale, n % 90 == 0 ? Brand.gold300 : Colors.white);
      }
    }
    // The sun and the Qibla on the tape.
    final sun = this.sun;
    if (sun != null) {
      final rel = signedDifference(heading, sun.azimuth);
      if (rel.abs() < half) _sunGlyph(canvas, Offset(_x(size, rel), top + _tapeH - 4), 4);
    }
    if (diff.abs() < half) _kaaba(canvas, Offset(_x(size, diff), top + _tapeH - 3), 11, gold);

    // Where the phone looks: a pointer and the heading, read out.
    canvas.drawPath(
      Path()
        ..moveTo(cx, top + _tapeH)
        ..lineTo(cx - 6, top + _tapeH + 8)
        ..lineTo(cx + 6, top + _tapeH + 8)
        ..close(),
      Paint()..color = Colors.white,
    );
    _pill(canvas, Offset(cx, top + _tapeH + 21), '${heading.round() % 360}°', Colors.white, Colors.black87, 14);

    // Below the tape the picture is the world's: the horizon, tilting with
    // the phone.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, top + _tapeH + 38, size.width, size.height));
    // Looking far up or down, the horizon and its marks stay in sight,
    // moved together to the edge of the picture.
    final ahead = pose.project(heading, 0);
    final aim = Offset(ahead?.dx ?? cx, (ahead?.dy ?? size.height / 2).clamp(lo, hi));
    final lift = Offset(0, ahead == null ? 0 : aim.dy - ahead.dy);
    final left = pose.project(heading - half - 20, 0);
    final right = pose.project(heading + half + 20, 0);
    if (left != null && right != null) {
      canvas.drawLine(
        left + lift,
        right + lift,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = 1,
      );
    }

    // The sun: a dashed line at its height, and a ring where the compass
    // says it is. The real sun should sit in the ring.
    if (sun != null) {
      final level = Path();
      var drawing = false;
      for (var d = -half - 10; d <= half + 10; d += 2) {
        final at = pose.project(heading + d, sun.elevation);
        if (at == null) {
          drawing = false;
          continue;
        }
        drawing ? level.lineTo(at.dx, at.dy) : level.moveTo(at.dx, at.dy);
        drawing = true;
      }
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Brand.gold300.withValues(alpha: 0.55);
      _dashed(canvas, level, dash);
      final at = pose.project(sun.azimuth, sun.elevation);
      if (at != null && at.dx > -30 && at.dx < size.width + 30) {
        _dashed(
          canvas,
          Path()..addOval(Rect.fromCircle(center: at, radius: 26)),
          dash
            ..strokeWidth = 2
            ..color = Brand.gold300.withValues(alpha: 0.9),
          dash: 5,
          gap: 4,
        );
        // Under the ring, unless that is down among the chips.
        final below = at.dy + 44 < size.height - insets.bottom - 120;
        _pill(canvas, Offset(at.dx, at.dy + (below ? 44 : -44)), sunLabel, Colors.black.withValues(alpha: 0.55),
            Brand.gold300, 12);
      }
    }

    // The aim: a ring on the horizon straight ahead, which the Kaaba should
    // come into.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = aligned ? 3 : 1.6
      ..color = (aligned ? accent : Colors.white).withValues(alpha: 0.85);
    canvas.drawCircle(aim, 30, ring);
    for (final dy in const [-1.0, 1.0]) {
      canvas.drawLine(Offset(aim.dx, aim.dy + dy * 34), Offset(aim.dx, aim.dy + dy * 46), ring);
    }

    final kaaba = pose.project(qibla, 0);
    if (kaaba != null && kaaba.dx >= 0 && kaaba.dx <= size.width) {
      // In sight: the Kaaba on the horizon, a thin beam from its tape mark.
      final at = Offset(kaaba.dx, (kaaba.dy + lift.dy).clamp(lo, hi));
      canvas.drawLine(
        Offset(at.dx, top + _tapeH + 30),
        Offset(at.dx, at.dy - 24),
        Paint()
          ..strokeWidth = 2
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gold.withValues(alpha: 0), gold.withValues(alpha: 0.9)],
          ).createShader(Rect.fromLTRB(at.dx - 1, top + _tapeH + 30, at.dx + 1, at.dy)),
      );
      canvas.drawCircle(at, aligned ? 40 : 34, Paint()..color = gold.withValues(alpha: aligned ? 0.3 : 0.18));
      _kaaba(canvas, at, 40, gold);
      _pill(canvas, Offset(at.dx, at.dy + 44), label, Colors.black.withValues(alpha: 0.62), Colors.white, 13,
          accentText: gold);
    } else {
      // Out of sight: an arrow on the side to turn to, with how far.
      final toRight = diff > 0;
      final x = toRight ? size.width - 30 : 30.0;
      final y = aim.dy;
      canvas.drawCircle(Offset(x, y), 26, Paint()..color = Colors.black.withValues(alpha: 0.5));
      canvas.drawPath(
        Path()
          ..moveTo(x + (toRight ? 13 : -13), y)
          ..lineTo(x + (toRight ? -7 : 7), y - 14)
          ..lineTo(x + (toRight ? -7 : 7), y + 14)
          ..close(),
        Paint()..color = Brand.gold300,
      );
      _pill(canvas, Offset(x, y + 42), '${diff.abs().round()}°', Colors.black.withValues(alpha: 0.62), Colors.white, 13);
    }
    canvas.restore();
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

  /// A small sun: a disc and eight rays.
  void _sunGlyph(Canvas canvas, Offset at, double r) {
    final paint = Paint()
      ..color = Brand.gold300
      ..strokeWidth = 1.4;
    canvas.drawCircle(at, r, paint);
    for (var k = 0; k < 8; k++) {
      final t = k * math.pi / 4;
      final ray = Offset(math.cos(t), math.sin(t));
      canvas.drawLine(at + ray * r * 1.5, at + ray * r * 2.1, paint);
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint, {double dash = 7, double gap = 6}) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
      }
    }
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

  void _text(Canvas canvas, String text, Offset at, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: font.merge(TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
        )),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  // Rebuilt with every reading, which nearly always moves something.
  @override
  bool shouldRepaint(_Overlay old) => true;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.color,
    this.badge,
    this.small = false,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final Color color;

  /// "12°", set off at the end.
  final String? badge;
  final bool small;

  /// A button at the end: "Bekor qilish".
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small
          ? EdgeInsets.fromLTRB(9, 6, action == null ? 12 : 4, 6)
          : const EdgeInsets.fromLTRB(12, 9, 9, 9),
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
          if (action != null) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.white,
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: onAction,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    action!,
                    style: const TextStyle(color: Colors.black87, fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ] else if (badge != null) ...[
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
