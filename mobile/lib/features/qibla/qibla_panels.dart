import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'qibla_controller.dart';
import 'qibla_math.dart';

/// "12° o‘ngga buriling", in the web page's steps.
String turnInstruction(AppLocalizations s, QiblaController c) {
  final d = c.difference;
  final degrees = d.abs().round();
  final right = d > 0;
  return switch (c.facing) {
    Facing.aligned => s.qiblaAligned,
    Facing.close => right ? s.qiblaSlightlyRight : s.qiblaSlightlyLeft,
    Facing.turn => right ? s.qiblaTurnRight : s.qiblaTurnLeft,
    Facing.far => right ? s.qiblaTurnRightBy(degrees) : s.qiblaTurnLeftBy(degrees),
  };
}

/// The most important line: which way to turn and how far, coloured by how
/// close the phone is.
class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key, required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = controller;
    final facing = c.facing;
    final aligned = facing == Facing.aligned;
    final (Color tone, Color bg) = switch (facing) {
      Facing.aligned => (Colors.white, p.action),
      Facing.close => (p.accent, p.cardSelected),
      Facing.turn => (Brand.gold500, p.gold.withValues(alpha: 0.12)),
      Facing.far => (p.ink, p.card),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: aligned ? p.action : p.hairline),
        boxShadow: aligned ? [BoxShadow(color: p.action.withValues(alpha: 0.35), blurRadius: 18)] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aligned ? Colors.white.withValues(alpha: 0.2) : p.page,
            ),
            child: aligned
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                : Transform.flip(
                    flipX: c.difference < 0,
                    child: Icon(Icons.rotate_right_rounded, color: tone, size: 28),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turnInstruction(s, c),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: tone),
                ),
                if (!aligned)
                  Text(
                    s.qiblaDegreesLeft(c.difference.abs().round()),
                    style: TextStyle(
                      fontSize: 13,
                      color: p.inkMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The Qibla's bearing and the phone's, side by side.
class AnglesCard extends StatelessWidget {
  const AnglesCard({super.key, required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final c = controller;
    return _Pair(
      left: _Figure(
        icon: Icons.mosque_rounded,
        label: s.qiblaAngle,
        value: c.qibla == null ? '--°' : '${c.qibla!.bearing.toStringAsFixed(1)}°',
      ),
      right: _Figure(
        icon: Icons.explore_outlined,
        label: s.qiblaYourDirection,
        value: '${c.heading.round() % 360}°',
      ),
    );
  }
}

/// Where the page computed from, and how far Makkah is.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.controller, required this.language});

  final QiblaController controller;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final c = controller;
    final km = c.qibla == null ? '--' : NumberFormat.decimalPattern(language.code).format(c.qibla!.distanceKm.round());
    return _Pair(
      left: _Figure(icon: Icons.location_on_outlined, label: s.qiblaLocation, value: c.city ?? s.locationPlaceholder),
      right: _Figure(icon: Icons.flight_takeoff_rounded, label: s.qiblaToMakkah, value: '$km km'),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: left),
            VerticalDivider(color: p.hairline, width: 1),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: p.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.inkMuted)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How far the compass can be trusted right now, and why not when it can't.
class SignalCard extends StatelessWidget {
  const SignalCard({super.key, required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = controller;
    final q = c.quality;
    final label = switch (c.issue) {
      SignalIssue.needsCalibration => s.qiblaNeedsCalibration,
      SignalIssue.tilted => s.qiblaHoldFlatShort,
      SignalIssue.interference => s.qiblaInterference,
      SignalIssue.none => switch (q) {
          4 => s.qiblaQualityExcellent,
          3 => s.qiblaQualityGood,
          2 => s.qiblaQualityMedium,
          _ => s.qiblaQualityPoor,
        },
    };
    final colour = q >= 3 ? p.accent : (q == 2 ? Brand.gold500 : const Color(0xFFDC5B2E));
    final accuracy = c.reading?.accuracy ?? -1;
    final decl = c.magnet?.declination ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.issue == SignalIssue.interference ? colour : p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.qiblaSignal, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.inkSoft)),
              const SizedBox(width: 10),
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < q ? colour : p.hairline,
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colour),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (accuracy >= 0) s.qiblaAccuracy(accuracy.round()),
              s.qiblaDeclination('${decl >= 0 ? '+' : '−'}${decl.abs().toStringAsFixed(1)}'),
            ].join('  ·  '),
            style: TextStyle(fontSize: 12, color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// A check no magnet can disturb: where the sun stands relative to the
/// Qibla, and when it next stands right over the Kaaba.
class SunCard extends StatelessWidget {
  const SunCard({super.key, required this.controller, required this.language});

  final QiblaController controller;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = controller;
    final sun = c.sun;
    final qibla = c.qibla?.bearing;
    String line;
    if (sun == null || qibla == null || !sun.up) {
      line = s.qiblaSunDown;
    } else {
      final rel = signedDifference(sun.azimuth, qibla);
      final az = sun.azimuth.round();
      final deg = rel.abs().round();
      line = deg <= 3
          ? s.qiblaSunAhead(az)
          : rel > 0
              ? s.qiblaSunRight(az, deg)
              : s.qiblaSunLeft(az, deg);
    }
    final next = nextSunOverKaaba(c.now).toLocal();
    final when = DateFormat(language == AppLanguage.uz ? 'd-MMMM, HH:mm' : 'd MMMM, HH:mm', language.code).format(next);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, size: 19, color: Brand.gold400),
              const SizedBox(width: 8),
              Text(s.qiblaSunTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
            ],
          ),
          const SizedBox(height: 6),
          Text(line, style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft)),
          const SizedBox(height: 6),
          Text(s.qiblaSunOverKaaba(when), style: TextStyle(fontSize: 12.5, height: 1.45, color: p.inkMuted)),
        ],
      ),
    );
  }
}

/// The web page's four tips, plus the camera.
class TipsCard extends StatelessWidget {
  const TipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 19, color: p.gold),
              const SizedBox(width: 8),
              Text(s.qiblaTipsTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
            ],
          ),
          const SizedBox(height: 6),
          for (final tip in [s.qiblaTip1, s.qiblaTip2, s.qiblaTip3, s.qiblaTip4, s.qiblaTip5])
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 9, left: 2),
                    child: Container(width: 5, height: 5, decoration: BoxDecoration(color: p.gold, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(tip, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// For checking the compass against a known direction (seven taps on the
/// title, as on the web page): raw and corrected headings, declination,
/// accuracy, and a three-second recording.
Future<void> showDiagnostics(BuildContext context, QiblaController controller) {
  final ref = TextEditingController();
  String? result;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withValues(alpha: 0.9),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller;
          final r = c.reading;
          String f(double? v, [int digits = 1]) => v == null ? '--' : v.toStringAsFixed(digits);
          const style = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5, color: Color(0xFF39FF6A));
          return Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'source: ${r?.source ?? '--'} | status: ${r?.status ?? '--'} | accuracy: ${f(r?.accuracy)}°\n'
                  'raw (magnetic): ${f(c.rawMagnetic)}° → true: ${f(normalizeDegrees(c.rawMagnetic + (c.magnet?.declination ?? 0)))}° → smoothed: ${f(c.heading)}°\n'
                  'declination: ${f(c.magnet?.declination, 2)}° (WMM-2025) | tilt: ${f(r?.tilt, 0)}° | camera up: ${f(r?.cameraUp, 0)}°\n'
                  'field: ${f(r?.field)} µT vs model ${f(c.expectedField)} µT | qibla: ${f(c.qibla?.bearing, 3)}°',
                  style: style,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('ref az:', style: style),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: ref,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: style,
                        decoration: const InputDecoration(isDense: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () async {
                        setState(() => result = 'recording...');
                        final rec = await c.record();
                        final refValue = double.tryParse(ref.text.replaceAll(',', '.'));
                        setState(() => result = 'n=${rec.count} mean=${f(rec.mean, 2)}° std=${f(rec.std, 2)}°'
                            '${refValue == null ? '' : ' | error vs ref: ${f(signedDifference(refValue, rec.mean), 2)}°'}');
                      },
                      child: const Text('REC 3s'),
                    ),
                  ],
                ),
                if (result != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(result!, style: style)),
              ],
            ),
          );
        },
      ),
    ),
  );
}
