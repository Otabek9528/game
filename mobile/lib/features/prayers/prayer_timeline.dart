import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_models.dart';
import '../reminders/reminders.dart';
import 'day_view.dart';

/// The day as a vertical timeline, as on the web page: a rail with a node
/// per time, the fasting band in gold from suhoor to iftar, "hozir" and
/// "keyingi" chips, and here a reminder bell at the end of each row.
class PrayerTimeline extends StatelessWidget {
  const PrayerTimeline({
    super.key,
    required this.day,
    required this.now,
    required this.reminders,
    required this.onReminder,
  });

  final PrayerDay day;

  /// Only when [day] is today.
  final DateTime? now;
  final ReminderSettings reminders;
  final ValueChanged<ReminderSlot> onReminder;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final rows = timelineRows(day, now: now);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 4, 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          for (final row in rows)
            _Row(row: row, reminder: reminders[row.slot], onReminder: () => onReminder(row.slot)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.reminder, required this.onReminder});

  final TimelineRow row;
  final Reminder reminder;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final quiet = row.kind != RowKind.prayer;
    final marked = row.highlighted || row.next;

    final Color nameColor;
    final Color timeColor;
    if (marked) {
      nameColor = p.accent;
      timeColor = p.accent;
    } else if (row.past) {
      nameColor = quiet ? p.inkMuted : p.inkSoft;
      timeColor = p.inkMuted;
    } else {
      nameColor = quiet ? p.inkSoft : p.ink;
      timeColor = quiet ? p.inkSoft : p.ink;
    }

    final comment = switch (row.slot) {
      ReminderSlot.fajr => s.commentFajr,
      ReminderSlot.sunrise => s.commentSunrise,
      ReminderSlot.asr => s.commentAsr,
      ReminderSlot.maghrib => s.commentMaghrib,
      ReminderSlot.isha => s.commentIsha,
      _ => null,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: row.highlighted ? p.cardSelected : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 32, child: CustomPaint(painter: _RailPainter(row: row, palette: p))),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          row.slot == ReminderSlot.imsak ? s.suhoorLabel : slotName(s, row.slot),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: nameColor),
                        ),
                        if (row.active) _Chip(text: s.chipNow, kind: _ChipKind.now),
                        if (row.next) _Chip(text: s.chipNext, kind: _ChipKind.next),
                        if (row.slot == ReminderSlot.maghrib) _Chip(text: s.iftarLabel, kind: _ChipKind.iftar),
                      ],
                    ),
                    if (comment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          '($comment)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: p.inkMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                row.time == null ? '--:--' : hhmm(row.time!),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: timeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Center(child: ReminderBell(reminder: reminder, onTap: onReminder, label: slotName(s, row.slot))),
          ],
        ),
      ),
    );
  }
}

/// A row's reminder at a glance: its mode as the icon, its offset under it.
class ReminderBell extends StatelessWidget {
  const ReminderBell({super.key, required this.reminder, required this.onTap, required this.label});

  final Reminder reminder;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final on = reminder.isOn;
    final offset = reminder.offset;
    return Semantics(
      button: true,
      label: s.reminderFor(label),
      value: on ? offsetText(s, offset) : s.reminderOff,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 46,
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                reminderIcon(reminder.mode),
                size: 22,
                color: on ? p.accent : p.inkMuted.withValues(alpha: 0.55),
              ),
              if (on && offset != 0)
                Text(
                  '${offset < 0 ? '−' : '+'}${offset.abs()}',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData reminderIcon(ReminderMode mode) => switch (mode) {
      ReminderMode.off => Icons.notifications_off_outlined,
      ReminderMode.silent => Icons.notifications_none_rounded,
      ReminderMode.vibrate => Icons.vibration_rounded,
      ReminderMode.sound => Icons.notifications_active_rounded,
    };

enum _ChipKind { now, next, iftar }

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.kind});

  final String text;
  final _ChipKind kind;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final (Color fg, Color bg, Color? edge) = switch (kind) {
      _ChipKind.now => (Colors.white, p.action, null),
      _ChipKind.next => (p.accent, p.cardSelected, p.accent.withValues(alpha: 0.3)),
      _ChipKind.iftar => (p.gold, p.gold.withValues(alpha: 0.14), null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: edge == null ? null : Border.all(color: edge),
      ),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// The rail through a row: the line above and below the node (gold inside
/// the fasting band), and the node itself.
class _RailPainter extends CustomPainter {
  const _RailPainter({required this.row, required this.palette});

  final TimelineRow row;
  final VegukinPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final x = size.width / 2 + 2;
    final y = size.height / 2;
    final line = p.hairlineStrong;
    final band = p.gold.withValues(alpha: 0.85);

    final (Color? top, Color? bottom) = switch (row.slot) {
      ReminderSlot.imsak => (null, band),
      ReminderSlot.maghrib => (band, line),
      ReminderSlot.isha => (line, null),
      _ => (band, band),
    };
    void segment(Color? color, double from, double to) {
      if (color == null) return;
      canvas.drawLine(
        Offset(x, from),
        Offset(x, to),
        Paint()
          ..color = color
          ..strokeWidth = 2.4,
      );
    }

    segment(top, 0, y);
    segment(bottom, y, size.height);

    final center = Offset(x, y);
    switch (row.kind) {
      case RowKind.suhoor:
        canvas.drawCircle(center, 6, Paint()..color = p.gold);
      case RowKind.boundary:
        canvas.drawCircle(center, 4, Paint()..color = row.past ? p.hairlineStrong : p.inkMuted);
      case RowKind.prayer:
        if (row.highlighted) {
          canvas.drawCircle(center, 11, Paint()..color = p.accent.withValues(alpha: 0.18));
          canvas.drawCircle(center, 7.5, Paint()..color = p.accent);
        } else if (row.past) {
          canvas.drawCircle(center, 6, Paint()..color = p.hairlineStrong);
        } else {
          canvas.drawCircle(center, 6, Paint()..color = p.card);
          canvas.drawCircle(
            center,
            5,
            Paint()
              ..color = p.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.row.highlighted != row.highlighted || old.row.past != row.past || old.palette != palette;
}
