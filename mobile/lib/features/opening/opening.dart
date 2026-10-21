import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';

/// The app's opening, over [child] for a moment at launch.
///
/// It starts from the system splash screen's picture: the emblem on emerald
/// (ic_splash_mark.xml, the same size and place), so the hand-over can't be
/// seen. The star turns an eighth, a glint runs over the gold, the name
/// rises beneath, and the app shows through. Under a second and a half,
/// while the app loads behind it. A tap skips it; with animations turned
/// off in the phone's settings there is none.
class Opening extends StatefulWidget {
  const Opening({super.key, required this.child});

  final Widget child;

  /// How long it plays, fading out included.
  static const duration = Duration(milliseconds: 1400);

  /// The star's half-width: 29 of the splash icon's 108 units, on Android's
  /// 288 dp splash icon.
  static const starRadius = 29 / 108 * 288;

  @override
  State<Opening> createState() => _OpeningState();
}

class _OpeningState extends State<Opening> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(vsync: this, duration: Opening.duration)
    ..addStatusListener((status) {
      // Also after a skip, which starts it again from further on.
      if (status == AnimationStatus.completed && mounted) setState(() => _done = true);
    });
  bool _done = false;

  // Where the fading out begins.
  static const _leaving = 0.80;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _play.isAnimating || _play.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _done = true;
      return;
    }
    unawaited(_play.forward());
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  void _skip() {
    if (_play.value < _leaving) _play.forward(from: _leaving);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnnotatedRegion<SystemUiOverlayStyle>(
          key: const ValueKey('opening'),
          value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
          child: GestureDetector(
            onTap: _skip,
            behavior: HitTestBehavior.opaque,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _play,
                builder: (context, _) {
                  final t = _play.value;
                  final name = _phase(t, 0.40, 0.64, Curves.easeOutCubic);
                  return Opacity(
                    opacity: 1 - _phase(t, _leaving, 1, Curves.easeInOut),
                    child: ColoredBox(
                      color: Brand.emerald900,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _OpeningPainter(t)),
                          Center(
                            child: Transform.translate(
                              offset: Offset(0, Opening.starRadius + 52 - 10 * name),
                              child: Opacity(
                                opacity: name,
                                child: const Text(
                                  'Muslim Vegukin',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontFamily: Brand.displayFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How far into [from]..[to] the opening is at [t], 0 to 1, eased.
double _phase(double t, double from, double to, [Curve curve = Curves.linear]) =>
    curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

class _OpeningPainter extends CustomPainter {
  const _OpeningPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = Opening.starRadius;

    // The star turns an eighth (where it looks as it began), drawing in a
    // breath as it goes; on leaving it opens towards the viewer.
    final turn = _phase(t, 0.04, 0.40, Curves.easeInOutCubic);
    final scale = (1 - 0.05 * math.sin(turn * math.pi)) * (1 + 0.08 * _phase(t, 0.80, 1, Curves.easeInCubic));
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..scale(scale)
      ..translate(-c.dx, -c.dy);

    final ring = Emblem.ring(c, r, rotation: turn * math.pi / 4);
    final roof = Emblem.roof(c, r);
    final (stems, v) = Emblem.monogram(c, r);
    canvas
      ..drawPath(ring, Paint()..shader = Emblem.gold(c, r))
      ..drawPath(roof, Paint()..color = Brand.gold300)
      ..drawPath(stems, Paint()..color = Emblem.cream)
      ..drawPath(v, Paint()..color = Brand.gold400);

    // A glint of light across the gold, top left to bottom right.
    final glint = _phase(t, 0.30, 0.66, Curves.easeInOut);
    if (glint > 0 && glint < 1) {
      final along = Offset(r, r) * (2.6 * glint - 1.3);
      final light = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCenter(center: c + along, width: r * 0.7, height: r * 0.7));
      canvas
        ..drawPath(ring, light)
        ..drawPath(roof, light)
        ..drawPath(v, light);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OpeningPainter oldDelegate) => oldDelegate.t != t;
}
