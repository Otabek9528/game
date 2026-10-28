import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../core/widgets/spinning_refresh.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_controller.dart';
import '../prayer/prayer_models.dart';
import '../reminders/reminder_sheet.dart';
import '../reminders/reminders.dart';
import '../widget/widget_offer.dart';
import 'nafl_card.dart';
import 'prayer_timeline.dart';
import 'settings_sheet.dart';

/// The full prayer times page, opened from the home card: today's
/// countdown, any day's times with a reminder on each, and the nafl
/// prayers. The app's own version of the web app's pages/prayers.html.
class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  PrayerController get _prayer => widget.services.prayer;

  Timer? _ticker;

  /// Midnight of the day the timeline and nafl show; the header always
  /// counts down today.
  late DateTime _viewDate = _midnight(_prayer.now);

  /// Follows the date across midnight unless the user stepped away.
  bool _pinnedToToday = true;
  PrayerDay? _viewDay;
  bool _viewFailed = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _prayer.addListener(_reload);
    widget.services.reminders.checkNotifications();
    _show(_viewDate);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _prayer.removeListener(_reload);
    super.dispose();
  }

  void _tick() {
    final today = _midnight(_prayer.now);
    if (_pinnedToToday && today != _viewDate) {
      _show(today);
    } else {
      setState(() {});
    }
  }

  /// The place, settings or saved days changed: the shown day may be stale.
  void _reload() {
    if (mounted) _show(_viewDate);
  }

  static DateTime _midnight(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Calendar days from today (in UTC, so a daylight-saving night still
  /// counts as one day).
  int get _offset {
    final today = _prayer.now;
    return DateTime.utc(_viewDate.year, _viewDate.month, _viewDate.day)
        .difference(DateTime.utc(today.year, today.month, today.day))
        .inDays;
  }

  Future<void> _show(DateTime date) async {
    final token = ++_token;
    final place = _prayer.place;
    PrayerDay? saved;
    if (place != null) {
      final key = PrayerDay.keyFor(date, _prayer.settings, place);
      for (final d in _prayer.days) {
        if (d.key == key) saved = d;
      }
    }
    setState(() {
      _viewDate = date;
      _viewDay = saved;
      _viewFailed = false;
    });
    if (saved != null) {
      _prefetchAround(date);
      return;
    }
    final day = await _prayer.dayAt(date);
    if (!mounted || token != _token) return;
    setState(() {
      _viewDay = day;
      _viewFailed = day == null;
    });
    if (day != null) _prefetchAround(date);
  }

  /// The next tap either way is then instant.
  void _prefetchAround(DateTime date) {
    for (final n in const [-1, 1]) {
      _prayer.dayAt(DateTime(date.year, date.month, date.day + n));
    }
  }

  void _step(int days) {
    HapticFeedback.selectionClick();
    final date = DateTime(_viewDate.year, _viewDate.month, _viewDate.day + days);
    _pinnedToToday = date == _midnight(_prayer.now);
    _show(date);
  }

  void _goToday() {
    _pinnedToToday = true;
    if (_offset == 0) return;
    HapticFeedback.selectionClick();
    _show(_midnight(_prayer.now));
  }

  void _openSettings() {
    HapticFeedback.selectionClick();
    showSettingsSheet(context, _prayer);
  }

  void _openReminder(ReminderSlot slot) {
    HapticFeedback.selectionClick();
    showReminderSheet(
      context,
      slot: slot,
      reminders: widget.services.reminders,
      prayer: _prayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = widget.services.locale.language ?? AppLanguage.uz;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(title: s.prayersTitle),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([_prayer, widget.services.reminders]),
                builder: (context, _) => ListView(
                  padding: EdgeInsets.only(bottom: 28 + bottom),
                  children: [
                    _Hero(
                      prayer: _prayer,
                      services: widget.services,
                      onSettings: _openSettings,
                      onReminder: _openReminder,
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              WidgetOfferCard(services: widget.services),
                              _DateNav(
                                date: _viewDate,
                                offset: _offset,
                                day: _viewDay,
                                language: language,
                                onPrevious: () => _step(-1),
                                onNext: () => _step(1),
                                onToday: _goToday,
                              ),
                              const SizedBox(height: 8),
                              if (_viewDay != null)
                                PrayerTimeline(
                                  day: _viewDay!,
                                  now: _offset == 0 ? _prayer.now : null,
                                  reminders: widget.services.reminders.settings,
                                  onReminder: _openReminder,
                                )
                              else
                                _TimelineMessage(
                                  failed: _viewFailed || _prayer.place == null,
                                  onRetry: () => _show(_viewDate),
                                ),
                              const SizedBox(height: 12),
                              _Legend(),
                              const SizedBox(height: 16),
                              if (_viewDay != null)
                                NaflCard(
                                  day: _viewDay!,
                                  now: _prayer.now,
                                  offset: _offset,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ header

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return ColoredBox(
      color: p.hero.first,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: Brand.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The emerald block under the bar: where we are, the method, and today's
/// countdown with its progress and the next reminder.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.prayer,
    required this.services,
    required this.onSettings,
    required this.onReminder,
  });

  final PrayerController prayer;
  final AppServices services;
  final VoidCallback onSettings;
  final ValueChanged<ReminderSlot> onReminder;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final day = prayer.day;
    final now = prayer.now;
    final moment = day == null ? null : PrayerMoment.at(day, now);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.hero.first, p.hero[1], p.hero.last],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -10,
              child: IgnorePointer(
                child: KhatamRosette(
                  size: 210,
                  color: Brand.gold300.withValues(alpha: 0.16),
                  child: const SizedBox(width: 210, height: 210),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _PlacePill(prayer: prayer),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _GlassButton(
                            tooltip: s.settingsShort,
                            onTap: onSettings,
                            child: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (moment?.next == Prayer.sunrise ? s.untilFajrEnds : s.nextPrayer)
                                  .toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: Brand.gold300,
                              ),
                            ),
                          ),
                          _MethodPill(settings: prayer.settings, onTap: onSettings),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: moment == null ? '—' : prayerName(s, moment.next),
                              style: const TextStyle(
                                fontFamily: Brand.displayFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                            if (moment != null)
                              TextSpan(
                                text: '  ·  ${hhmm(moment.nextAt)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                moment == null ? '--:--:--' : countdownText(moment.remaining(now)),
                                style: const TextStyle(
                                  fontSize: 46,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.remaining,
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Progress(value: moment?.progress ?? 0),
                      const SizedBox(height: 12),
                      _NextReminder(prayer: prayer, services: services, onReminder: onReminder),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePill extends StatelessWidget {
  const _PlacePill({required this.prayer});

  final PrayerController prayer;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final c = prayer;
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
    final stale = c.place != null && c.now.difference(c.place!.timestamp) > PrayerController.staleAfter;

    return Semantics(
      button: true,
      label: s.refreshLocation,
      child: _Glass(
        onTap: c.locating
            ? null
            : () {
                HapticFeedback.selectionClick();
                c.locate(userAsked: true);
              },
        padding: const EdgeInsets.fromLTRB(11, 0, 12, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, size: 17, color: Brand.gold300),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                c.place?.city ?? s.locationPlaceholder,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            if (meta.isNotEmpty) ...[
              Text(
                '  ·  ',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
              ),
              Text(
                meta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.lastLocateFailed
                      ? const Color(0xFFFDBA74)
                      : stale
                          ? Brand.gold300
                          : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(width: 6),
            SpinningRefresh(spinning: c.locating, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Frosted control on the emerald header.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.onTap, this.padding = EdgeInsets.zero});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.16))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(height: 40, child: Padding(padding: padding, child: Center(widthFactor: 1, child: child))),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.child, required this.onTap, required this.tooltip});

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(width: 40, child: _Glass(onTap: onTap, child: child)),
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({required this.settings, required this.onTap});

  final PrayerSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 5, 11, 5),
          child: Text(
            '${methodShort(s, settings.method)}  ·  '
            '${settings.madhab == '1' ? s.schoolHanafi : s.schoolShafiiShort}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// How far through the current window we are, with the khatam at the tip.
class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 5,
                width: w * value,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Brand.gold500, Brand.gold300]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                left: (w * value - 8).clamp(-2.0, w - 14),
                child: CustomPaint(size: const Size.square(16), painter: _StarPainter()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = khatamPath(size.center(Offset.zero), size.width);
    canvas.drawPath(path, Paint()..color = Brand.gold300);
    canvas.drawPath(
      path,
      Paint()
        ..color = Brand.gold500
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// "🔔 12:19 · Peshin · 10 daq keyin": the next reminder, and the way to it.
class _NextReminder extends StatelessWidget {
  const _NextReminder({required this.prayer, required this.services, required this.onReminder});

  final PrayerController prayer;
  final AppServices services;
  final ValueChanged<ReminderSlot> onReminder;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final reminders = services.reminders;
    if (!reminders.notificationsAllowed) {
      return _Line(
        icon: Icons.notifications_off_rounded,
        color: const Color(0xFFFDBA74),
        text: s.notificationsOff,
        onTap: reminders.openNotificationSettings,
      );
    }
    final next = reminderSchedule(
      days: prayer.days,
      settings: reminders.settings,
      s: s,
      city: '',
      now: prayer.now,
    ).firstOrNull;
    if (next == null) return const SizedBox.shrink();
    return _Line(
      icon: switch (next.mode) {
        ReminderMode.sound => Icons.notifications_active_rounded,
        ReminderMode.vibrate => Icons.vibration_rounded,
        _ => Icons.notifications_none_rounded,
      },
      color: Brand.gold300,
      text: '${hhmm(next.at)}  ·  ${slotName(s, next.slot)}  ·  ${offsetText(s, next.offset)}',
      onTap: () => onReminder(next.slot),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text, required this.onTap});

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.black.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ date

class _DateNav extends StatelessWidget {
  const _DateNav({
    required this.date,
    required this.offset,
    required this.day,
    required this.language,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime date;
  final int offset;
  final PrayerDay? day;
  final AppLanguage language;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final away = offset != 0;
    final main = switch (offset) {
      0 => s.dayToday,
      1 => s.dayTomorrow,
      -1 => s.dayYesterday,
      _ => _capitalized(DateFormat('EEEE', language.code).format(date)),
    };
    final gregorian = DateFormat(language == AppLanguage.uz ? 'd-MMMM' : 'd MMMM', language.code).format(date);
    final sub = day == null ? gregorian : '$gregorian  ·  ${hijriLine(day!, language)}';

    Widget arrow(IconData icon, String label, VoidCallback onTap) => Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(width: 48, child: Icon(icon, color: p.accent, size: 26)),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.badge, borderRadius: BorderRadius.circular(15)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            arrow(Icons.chevron_left_rounded, s.previousDay, onPrevious),
            const SizedBox(width: 3),
            Expanded(
              child: Semantics(
                button: away,
                label: away ? s.backToToday : null,
                child: Material(
                  color: away ? p.cardSelected : p.card,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 0.6,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onToday,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Column(
                        children: [
                          Text(
                            main,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.accent),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: away ? p.accent : p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            arrow(Icons.chevron_right_rounded, s.nextDay, onNext),
          ],
        ),
      ),
    );
  }

  static String _capitalized(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          Text(
            failed ? s.dayLoadFailed : s.dayLoading,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: p.inkMuted),
          ),
          if (failed) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(foregroundColor: p.accent, shape: const StadiumBorder()),
              child: Text(s.retry),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(s.fastWindow, style: TextStyle(fontSize: 11.5, color: p.gold))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(width: 18, child: Icon(Icons.notifications_none_rounded, size: 15, color: p.inkMuted)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.reminderHint, style: TextStyle(fontSize: 11.5, color: p.inkMuted))),
            ],
          ),
        ],
      ),
    );
  }
}
