import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_controller.dart';
import '../prayer/prayer_models.dart';

/// Today at a glance: date, city, a countdown to the next prayer, and the
/// whole day as a strip. Mirrors the web app's home card.
class PrayerCard extends StatefulWidget {
  const PrayerCard({
    super.key,
    required this.controller,
    required this.language,
    required this.onOpen,
  });

  final PrayerController controller;
  final AppLanguage language;

  /// Opens the full prayer times page.
  final VoidCallback onOpen;

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final c = widget.controller;
    final day = c.day;
    // After midnight, today's times are needed; loadTimes() is a no-op
    // otherwise.
    if (day != null && !_sameDay(day.date, c.now)) c.loadTimes();
    setState(() {});
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final ready = c.status == PrayerStatus.ready && c.day != null;
        return Material(
          color: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: p.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: ready
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onOpen();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopRow(controller: c, language: widget.language),
                  const SizedBox(height: 14),
                  if (ready)
                    _Today(day: c.day!, now: c.now)
                  else if (c.status == PrayerStatus.starting || c.status == PrayerStatus.loading)
                    const _Skeleton()
                  else
                    _NeedsAction(controller: c),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.controller, required this.language});

  final PrayerController controller;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = controller;
    final day = c.day;

    final String meta;
    if (c.locating) {
      meta = s.locating;
    } else if (c.lastLocateFailed) {
      meta = s.locationFailedShort;
    } else if (c.place != null) {
      meta = ageText(s, c.now.difference(c.place!.timestamp));
    } else {
      meta = '';
    }
    final stale = c.place != null &&
        c.now.difference(c.place!.timestamp) > PrayerController.staleAfter;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gregorianLine(c.now, language),
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.ink),
              ),
              const SizedBox(height: 2),
              Text(
                day == null ? ' ' : hijriLine(day, language),
                style: TextStyle(fontSize: 12.5, color: p.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (c.place != null || c.locating)
          Semantics(
            button: true,
            label: s.refreshLocation,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: c.locating
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      c.locate(userAsked: true);
                    },
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                      decoration: BoxDecoration(
                        color: p.cardSelected,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: p.accent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded, size: 15, color: p.accent),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              c.place?.city ?? s.locationPlaceholder,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: p.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _SpinningRefresh(spinning: c.locating, color: p.accent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: c.lastLocateFailed
                            ? Theme.of(context).colorScheme.error
                            : stale
                                ? Brand.gold500
                                : p.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpinningRefresh extends StatefulWidget {
  const _SpinningRefresh({required this.spinning, required this.color});

  final bool spinning;
  final Color color;

  @override
  State<_SpinningRefresh> createState() => _SpinningRefreshState();
}

class _SpinningRefreshState extends State<_SpinningRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(_SpinningRefresh old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Icon(Icons.refresh_rounded, size: 15, color: widget.color),
    );
  }
}

/// Countdown and strip, once the day's times are known.
class _Today extends StatelessWidget {
  const _Today({required this.day, required this.now});

  final PrayerDay day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final moment = PrayerMoment.at(day, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          countdownLabel(s, moment.next).toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: p.accent,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            countdownText(moment.remaining(now)),
            style: TextStyle(
              fontSize: 42,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: p.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Strip(day: day, moment: moment),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.day, this.moment});

  /// Null while loading: names and "--:--".
  final PrayerDay? day;
  final PrayerMoment? moment;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final moment = this.moment;

    return Column(
      children: [
        Row(
          children: [
            for (final prayer in Prayer.values)
              Expanded(
                child: _Cell(
                  name: prayerName(s, prayer),
                  time: day == null ? '--:--' : hhmm(day!.times[prayer]!),
                  current: moment?.current == prayer,
                  boundary: prayer == Prayer.sunrise,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            final fraction = moment?.dayFraction ?? 0;
            final width = box.maxWidth;
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 4,
                    width: width * fraction,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Notches on the window boundaries keep the six segments
                  // readable, so a filled segment always means a passed window.
                  for (var i = 1; i < Prayer.values.length; i++)
                    Positioned(
                      left: width * i / Prayer.values.length - 1,
                      child: Container(width: 2, height: 4, color: p.card),
                    ),
                  if (moment != null)
                    Positioned(
                      left: width * fraction - 7,
                      child: CustomPaint(
                        size: const Size.square(14),
                        painter: _StarPainter(fill: p.accent, edge: p.card),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.fill, required this.edge});

  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final path = khatamPath(size.center(Offset.zero), size.width);
    canvas.drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawPath(path, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill || old.edge != edge;
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.name,
    required this.time,
    required this.current,
    required this.boundary,
  });

  final String name;
  final String time;
  final bool current;

  /// Sunrise: drawn quieter, since it ends a window rather than starting a
  /// prayer.
  final bool boundary;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final nameColor = current ? p.accent : (boundary ? p.inkMuted : p.inkSoft);
    final timeColor = current ? p.accent : (boundary ? p.inkMuted : p.ink);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: current ? p.cardSelected : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: nameColor),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: timeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 90,
            height: 10,
            decoration: BoxDecoration(color: p.hairline, borderRadius: BorderRadius.circular(5)),
          ),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '--:--:--',
            style: TextStyle(
              fontSize: 42,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: p.hairlineStrong,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Strip(day: null),
      ],
    );
  }
}

/// Shown instead of the times when the app can't get a location or times.
class _NeedsAction extends StatelessWidget {
  const _NeedsAction({required this.controller});

  final PrayerController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final c = controller;

    final (IconData icon, String? title, String body, String action, VoidCallback onAction) =
        switch (c.status) {
      PrayerStatus.permissionBlocked => (
          Icons.location_disabled_rounded,
          null,
          s.locationDeniedBody,
          s.openSettings,
          c.openAppSettings,
        ),
      PrayerStatus.locationOff => (
          Icons.location_off_rounded,
          null,
          s.locationOffBody,
          s.turnOnLocation,
          c.openLocationSettings,
        ),
      PrayerStatus.locationFailed => (
          Icons.location_searching_rounded,
          null,
          s.locationFailedBody,
          s.retry,
          () => c.locate(userAsked: true),
        ),
      PrayerStatus.timesFailed => (
          Icons.wifi_off_rounded,
          null,
          s.timesFailedBody,
          s.retry,
          c.loadTimes,
        ),
      _ => (
          Icons.location_on_rounded,
          s.locationNeededTitle,
          s.locationNeededBody,
          s.useMyLocation,
          () => c.locate(userAsked: true),
        ),
    };

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
          child: Icon(icon, color: p.accent, size: 26),
        ),
        const SizedBox(height: 12),
        if (title != null) ...[
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: onAction,
          style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
          child: Text(action),
        ),
      ],
    );
  }
}
