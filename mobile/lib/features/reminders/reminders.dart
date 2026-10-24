import 'dart:math' as math;

import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import '../prayer/prayer_models.dart';

/// The times a reminder can follow: the six on the prayer card plus the end
/// of suhoor (Imsak), which matters in Ramadan.
enum ReminderSlot { imsak, fajr, sunrise, dhuhr, asr, maghrib, isha }

/// How a reminder arrives. Each has its own Android notification channel.
enum ReminderMode {
  off,

  /// A notification with no sound and no vibration.
  silent,
  vibrate,

  /// The app's short chime, with a light vibration.
  sound,
}

/// One slot's reminder: how, and how many minutes from the slot's time
/// (negative: before it).
class Reminder {
  const Reminder({this.mode = ReminderMode.off, this.offset = 0});

  final ReminderMode mode;
  final int offset;

  bool get isOn => mode != ReminderMode.off;

  Reminder copyWith({ReminderMode? mode, int? offset}) =>
      Reminder(mode: mode ?? this.mode, offset: offset ?? this.offset);

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        mode: ReminderMode.values.firstWhere(
          (m) => m.name == json['mode'],
          orElse: () => ReminderMode.off,
        ),
        offset: (json['offset'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'mode': mode.name, 'offset': offset};

  @override
  bool operator ==(Object other) =>
      other is Reminder && other.mode == mode && other.offset == offset;

  @override
  int get hashCode => Object.hash(mode, offset);
}

/// Every slot's reminder.
class ReminderSettings {
  const ReminderSettings(this._bySlot);

  final Map<ReminderSlot, Reminder> _bySlot;

  /// A vibration at each of the five prayers; sunrise and suhoor are off.
  static const defaults = ReminderSettings({
    ReminderSlot.fajr: Reminder(mode: ReminderMode.vibrate),
    ReminderSlot.dhuhr: Reminder(mode: ReminderMode.vibrate),
    ReminderSlot.asr: Reminder(mode: ReminderMode.vibrate),
    ReminderSlot.maghrib: Reminder(mode: ReminderMode.vibrate),
    ReminderSlot.isha: Reminder(mode: ReminderMode.vibrate),
  });

  Reminder operator [](ReminderSlot slot) => _bySlot[slot] ?? const Reminder();

  ReminderSettings withReminder(ReminderSlot slot, Reminder reminder) =>
      ReminderSettings({..._bySlot, slot: reminder});

  factory ReminderSettings.fromJson(Map<String, dynamic> json) => ReminderSettings({
        for (final slot in ReminderSlot.values)
          if (json[slot.name] is Map<String, dynamic>)
            slot: Reminder.fromJson(json[slot.name] as Map<String, dynamic>),
      });

  Map<String, dynamic> toJson() => {
        for (final slot in ReminderSlot.values) slot.name: this[slot].toJson(),
      };
}

/// When a slot starts on a day, when the next one starts (the reminder may
/// not go past it) and when the one before started.
class SlotWindow {
  const SlotWindow({required this.start, required this.end, required this.previous});

  final DateTime start;
  final DateTime end;
  final DateTime previous;

  /// How far a reminder may move: up to an hour before (never back past the
  /// previous time) and up to a minute short of the next time.
  ({int before, int after}) get range => (
        before: math.max(0, math.min(60, previous.difference(start).abs().inMinutes - 1)),
        after: math.max(0, end.difference(start).inMinutes - 1),
      );

  int clamp(int offset) {
    final r = range;
    return offset.clamp(-r.before, r.after);
  }

  DateTime at(int offset) => start.add(Duration(minutes: clamp(offset)));
}

/// [slot]'s window on [day]; [nextDay] gives Isha its end. Null for suhoor
/// in days saved without it.
SlotWindow? slotWindow(PrayerDay day, ReminderSlot slot, {PrayerDay? nextDay}) {
  final t = day.times;
  final lastNight = t[Prayer.isha]!.subtract(const Duration(days: 1));
  return switch (slot) {
    ReminderSlot.imsak => day.imsak == null
        ? null
        : SlotWindow(start: day.imsak!, end: t[Prayer.fajr]!, previous: lastNight),
    ReminderSlot.fajr =>
      SlotWindow(start: t[Prayer.fajr]!, end: t[Prayer.sunrise]!, previous: lastNight),
    ReminderSlot.sunrise =>
      SlotWindow(start: t[Prayer.sunrise]!, end: t[Prayer.dhuhr]!, previous: t[Prayer.fajr]!),
    ReminderSlot.dhuhr =>
      SlotWindow(start: t[Prayer.dhuhr]!, end: t[Prayer.asr]!, previous: t[Prayer.sunrise]!),
    ReminderSlot.asr =>
      SlotWindow(start: t[Prayer.asr]!, end: t[Prayer.maghrib]!, previous: t[Prayer.dhuhr]!),
    ReminderSlot.maghrib =>
      SlotWindow(start: t[Prayer.maghrib]!, end: t[Prayer.isha]!, previous: t[Prayer.asr]!),
    ReminderSlot.isha => SlotWindow(
        start: t[Prayer.isha]!,
        end: nextDay?.times[Prayer.fajr] ?? t[Prayer.fajr]!.add(const Duration(days: 1)),
        previous: t[Prayer.maghrib]!,
      ),
  };
}

String slotName(AppLocalizations s, ReminderSlot slot) => switch (slot) {
      ReminderSlot.imsak => s.suhoorShort,
      ReminderSlot.fajr => s.prayerFajr,
      ReminderSlot.sunrise => s.prayerSunrise,
      ReminderSlot.dhuhr => s.prayerDhuhr,
      ReminderSlot.asr => s.prayerAsr,
      ReminderSlot.maghrib => s.prayerMaghrib,
      ReminderSlot.isha => s.prayerIsha,
    };

/// "45 daq", "2 soat", "1 soat 30 daq".
String durationText(AppLocalizations s, int minutes) {
  final m = minutes.abs();
  if (m < 60) return s.durationMinutes(m);
  if (m % 60 == 0) return s.durationHours(m ~/ 60);
  return s.durationHoursMinutes(m ~/ 60, m % 60);
}

/// "Vaqtida", "10 daq oldin", "20 daq keyin".
String offsetText(AppLocalizations s, int offset) {
  if (offset == 0) return s.offsetOnTime;
  final duration = durationText(s, offset);
  return offset < 0 ? s.offsetBefore(duration) : s.offsetAfter(duration);
}

/// A notification the phone should show, worked out here so it arrives in
/// the app's language; Android only keeps time (android/…/reminders/).
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.slot,
    required this.at,
    required this.offset,
    required this.mode,
    required this.title,
    required this.body,
  });

  final int id;
  final ReminderSlot slot;
  final DateTime at;

  /// Minutes from the slot's time, after fitting it into that day's window.
  final int offset;
  final ReminderMode mode;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'channel': mode.name,
        'title': title,
        'body': body,
      };
}

/// Every reminder still to come in the saved [days], soonest first.
List<ScheduledReminder> reminderSchedule({
  required List<PrayerDay> days,
  required ReminderSettings settings,
  required AppLocalizations s,
  required String city,
  required DateTime now,
}) {
  final out = <ScheduledReminder>[];
  for (var i = 0; i < days.length; i++) {
    final day = days[i];
    final next = i + 1 < days.length ? days[i + 1] : null;
    for (final slot in ReminderSlot.values) {
      final reminder = settings[slot];
      if (!reminder.isOn) continue;
      final window = slotWindow(day, slot, nextDay: next);
      if (window == null) continue;
      final offset = window.clamp(reminder.offset);
      final at = window.start.add(Duration(minutes: offset));
      if (!at.isAfter(now)) continue;
      out.add(ScheduledReminder(
        // Days since 2024 × 10 + slot: stable, unique, small.
        id: day.date.difference(DateTime(2024)).inDays * 10 + slot.index,
        slot: slot,
        at: at,
        offset: offset,
        mode: reminder.mode,
        title: _title(s, slot, offset),
        body: s.notifyBody(slotName(s, slot), hhmm(window.start), hhmm(window.end), city),
      ));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

String _title(AppLocalizations s, ReminderSlot slot, int offset) {
  final d = durationText(s, offset);
  return switch (slot) {
    ReminderSlot.imsak => offset == 0
        ? s.notifyImsakAt
        : offset < 0
            ? s.notifyImsakBefore(d)
            : s.notifyImsakAfter(d),
    ReminderSlot.sunrise => offset == 0
        ? s.notifySunriseAt
        : offset < 0
            ? s.notifySunriseBefore(d)
            : s.notifySunriseAfter(d),
    _ => offset == 0
        ? s.notifyAt(slotName(s, slot))
        : offset < 0
            ? s.notifyBefore(slotName(s, slot), d)
            : s.notifyAfter(slotName(s, slot), d),
  };
}
