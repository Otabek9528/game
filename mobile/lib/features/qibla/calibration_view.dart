import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'qibla_controller.dart';

/// Calibration in two steps, as on the web page: turn the phone through a
/// figure of eight until the eight turns are counted, then hold it flat
/// and still until the ring fills. Always skippable: the compass may
/// already be good enough.
class CalibrationView extends StatelessWidget {
  const CalibrationView({super.key, required this.controller, required this.onSkip});

  final QiblaController controller;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = controller;
    final moving = c.step == CalibrationStep.move;
    final r = c.reading;

    final String progress;
    if (moving) {
      progress = c.movements < QiblaController.movementsNeeded / 2 ? s.qiblaCalMoving : s.qiblaCalGood;
    } else if (c.calibrationDone) {
      progress = s.qiblaCalDone;
    } else if (r != null && r.tilt >= 35) {
      progress = s.qiblaHoldFlatShort;
    } else if (c.holdProgress < 0.4) {
      progress = s.qiblaCalHoldStill;
    } else {
      progress = s.qiblaCalChecking;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PhaseChip(number: 1, label: s.qiblaPhaseMove, active: moving, done: !moving),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: p.inkMuted),
              ),
              _PhaseChip(number: 2, label: s.qiblaPhaseHold, active: !moving, done: c.calibrationDone),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: moving
                ? const _FigureEight()
                : _Level(progress: c.holdProgress, levelX: r?.levelX ?? 0, levelY: r?.levelY ?? 0),
          ),
          const SizedBox(height: 14),
          Text(
            s.qiblaCalibrateTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
          ),
          const SizedBox(height: 6),
          Text(
            moving ? s.qiblaCalibrateMove : s.qiblaCalibrateHold,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
          ),
          if (moving) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < QiblaController.movementsNeeded; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 22,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i < c.movements ? p.accent : p.hairline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              s.qiblaMovements(c.movements, QiblaController.movementsNeeded),
              style: TextStyle(fontSize: 12.5, color: p.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            progress,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.accent),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: p.inkMuted, minimumSize: const Size(120, 44)),
            child: Text(s.qiblaSkip),
          ),
        ],
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.number, required this.label, required this.active, required this.done});

  final int number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final on = active || done;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
      decoration: BoxDecoration(
        color: active ? p.cardSelected : p.page,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? p.accent : p.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: on ? p.action : p.hairlineStrong,
            child: done
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : Text('$number', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: on ? p.accent : p.inkMuted)),
        ],
      ),
    );
  }
}

/// A phone travelling a dashed figure of eight, turning as it goes.
class _FigureEight extends StatefulWidget {
  const _FigureEight();

  @override
  State<_FigureEight> createState() => _FigureEightState();
}

class _FigureEightState extends State<_FigureEight> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) => CustomPaint(
        size: const Size(240, 150),
        painter: _EightPainter(t: _t.value, path: p.hairlineStrong, phone: p.accent, screen: p.cardSelected),
      ),
    );
  }
}

class _EightPainter extends CustomPainter {
  const _EightPainter({required this.t, required this.path, required this.phone, required this.screen});

  final double t;
  final Color path;
  final Color phone;
  final Color screen;

  // A lemniscate across the box.
  Offset _at(Size size, double u) {
    final a = u * 2 * math.pi;
    final d = 1 + math.pow(math.sin(a), 2);
    final x = math.cos(a) / d;
    final y = math.sin(a) * math.cos(a) / d;
    return Offset(size.width / 2 + x * size.width * 0.42, size.height / 2 + y * size.height * 0.8);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = path
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 64; i += 2) {
      canvas.drawLine(_at(size, i / 64), _at(size, (i + 1) / 64), dash);
    }
    final at = _at(size, t);
    final ahead = _at(size, t + 0.01);
    final angle = math.atan2(ahead.dy - at.dy, ahead.dx - at.dx) + math.pi / 2;
    // The wrist turns: the phone narrows twice a lap.
    final twist = 0.35 + 0.65 * math.cos(t * 4 * math.pi).abs();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.scale(twist, 1);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -19, 22, 38), const Radius.circular(5));
    canvas.drawRRect(body, Paint()..color = phone);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -14, 16, 25), const Radius.circular(2.5)),
      Paint()..color = screen,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EightPainter old) => old.t != t;
}

/// The hold-still step: a spirit level inside a ring that fills while the
/// phone stays flat and steady.
class _Level extends StatelessWidget {
  const _Level({required this.progress, required this.levelX, required this.levelY});

  final double progress;
  final double levelX;
  final double levelY;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    const size = 140.0;
    final dx = (levelX * 2).clamp(-1.0, 1.0) * 30;
    final dy = (-levelY * 2).clamp(-1.0, 1.0) * 30;
    final centered = math.sqrt(dx * dx + dy * dy) <= 8;
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                color: p.accent,
                backgroundColor: p.hairline,
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.hairlineStrong, width: 1.5)),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.inkMuted)),
            ),
            Transform.translate(
              offset: Offset(dx, dy),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (centered ? p.accent : Brand.gold400).withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
