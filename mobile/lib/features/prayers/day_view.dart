import '../prayer/prayer_models.dart';
import '../reminders/reminders.dart';

/// What a row on the prayers page stands for: the end of suhoor, a prayer,
/// or sunrise (where Fajr's time ends; not a prayer of its own).
enum RowKind { suhoor, prayer, boundary }

/// One row of the day's timeline, as pages/prayers.html draws it.
class TimelineRow {
  const TimelineRow({
    required this.slot,
    required this.time,
    this.active = false,
    this.next = false,
    this.past = false,
    this.highlighted = false,
  });

  final ReminderSlot slot;

  /// Null only for suhoor in days saved without it.
  final DateTime? time;

  /// Its window is open now ("hozir").
  final bool active;

  /// The countdown runs to it ("keyingi").
  final bool next;
  final bool past;

  /// Drawn filled: the open window or, between sunrise and Dhuhr when no
  /// window is open, the next prayer, so the list keeps an anchor.
  final bool highlighted;

  RowKind get kind => switch (slot) {
        ReminderSlot.imsak => RowKind.suhoor,
        ReminderSlot.sunrise => RowKind.boundary,
        _ => RowKind.prayer,
      };
}

/// The day's rows; [now] only when the day is today (it marks the current,
/// next and passed rows).
List<TimelineRow> timelineRows(PrayerDay day, {DateTime? now}) {
  final t = day.times;
  final times = <ReminderSlot, DateTime?>{
    ReminderSlot.imsak: day.imsak,
    ReminderSlot.fajr: t[Prayer.fajr],
    ReminderSlot.sunrise: t[Prayer.sunrise],
    ReminderSlot.dhuhr: t[Prayer.dhuhr],
    ReminderSlot.asr: t[Prayer.asr],
    ReminderSlot.maghrib: t[Prayer.maghrib],
    ReminderSlot.isha: t[Prayer.isha],
  };
  if (now == null) {
    return [for (final slot in ReminderSlot.values) TimelineRow(slot: slot, time: times[slot])];
  }

  final active = activeSlot(day, now);
  final next = switch (PrayerMoment.at(day, now).next) {
    Prayer.fajr => ReminderSlot.fajr,
    Prayer.sunrise => ReminderSlot.sunrise,
    Prayer.dhuhr => ReminderSlot.dhuhr,
    Prayer.asr => ReminderSlot.asr,
    Prayer.maghrib => ReminderSlot.maghrib,
    Prayer.isha => ReminderSlot.isha,
  };
  final n = _minutes(now);
  return [
    for (final slot in ReminderSlot.values)
      TimelineRow(
        slot: slot,
        time: times[slot],
        active: slot == active,
        next: slot == next,
        highlighted: slot == active || (active == null && slot == next),
        past: slot != active &&
            slot != next &&
            times[slot] != null &&
            _minutes(times[slot]!) < n,
      ),
  ];
}

/// The prayer whose time it is at [now], or null between sunrise and Dhuhr,
/// when no obligatory prayer's window is open. A prayer lasts until the next
/// one begins; Isha runs past midnight to Fajr.
ReminderSlot? activeSlot(PrayerDay day, DateTime now) {
  final t = day.times;
  final n = _minutes(now);
  const ends = {
    Prayer.fajr: Prayer.sunrise,
    Prayer.dhuhr: Prayer.asr,
    Prayer.asr: Prayer.maghrib,
    Prayer.maghrib: Prayer.isha,
    Prayer.isha: Prayer.fajr,
  };
  for (final entry in ends.entries) {
    final s = _minutes(t[entry.key]!);
    final e = _minutes(t[entry.value]!);
    final inside = e > s ? n >= s && n < e : n >= s || n < e;
    if (inside) {
      return switch (entry.key) {
        Prayer.fajr => ReminderSlot.fajr,
        Prayer.dhuhr => ReminderSlot.dhuhr,
        Prayer.asr => ReminderSlot.asr,
        Prayer.maghrib => ReminderSlot.maghrib,
        _ => ReminderSlot.isha,
      };
    }
  }
  return null;
}

int _minutes(DateTime t) => t.hour * 60 + t.minute;

// ------------------------------------------------------------------ nafl

/// The voluntary prayers the page lists, in its order.
enum Nafl { tahajjud, ishraq, duha }

/// A nafl window in minutes from midnight; it may wrap past midnight.
class NaflWindow {
  const NaflWindow(this.start, this.end);

  final int start;
  final int end;

  String get text => '${_clock(start)} — ${_clock(end)}';

  static String _clock(int minutes) {
    final m = ((minutes % 1440) + 1440) % 1440;
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }
}

enum NaflStatus { active, upcoming, passed }

/// Same offsets as the web page: Ishraq 30 minutes after sunrise for 15
/// minutes; Duha from 20 minutes after sunrise to an hour before Dhuhr;
/// Tahajjud from the night's last third (Aladhan's) to Fajr.
Map<Nafl, NaflWindow?> naflWindows(PrayerDay day) {
  final t = day.times;
  final sunrise = _minutes(t[Prayer.sunrise]!);
  final dhuhr = _minutes(t[Prayer.dhuhr]!);
  final fajr = _minutes(t[Prayer.fajr]!);
  final maghrib = _minutes(t[Prayer.maghrib]!);
  final NaflWindow tahajjud;
  if (day.lastThird != null) {
    tahajjud = NaflWindow(_minutes(day.lastThird!), fajr);
  } else {
    final night = fajr + 1440 - maghrib;
    tahajjud = NaflWindow(((fajr - (night / 3).round()) % 1440 + 1440) % 1440, fajr);
  }
  return {
    Nafl.tahajjud: tahajjud,
    Nafl.ishraq: NaflWindow(sunrise + 30, sunrise + 45),
    Nafl.duha: NaflWindow(sunrise + 20, dhuhr - 60),
  };
}

/// Where [now] is relative to [w], and how far through it when inside.
({NaflStatus status, double progress}) naflStatus(NaflWindow w, DateTime now) {
  final n = _minutes(now);
  final wraps = w.end < w.start;
  final inside = wraps ? n >= w.start || n < w.end : n >= w.start && n < w.end;
  if (inside) {
    final total = wraps ? 1440 - w.start + w.end : w.end - w.start;
    final elapsed = n >= w.start ? n - w.start : 1440 - w.start + n;
    return (status: NaflStatus.active, progress: (elapsed / total).clamp(0.0, 1.0));
  }
  final upcoming = wraps ? n < w.start && n >= w.end : n < w.start;
  return (status: upcoming ? NaflStatus.upcoming : NaflStatus.passed, progress: 0.0);
}
