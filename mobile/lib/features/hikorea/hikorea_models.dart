import 'package:flutter/foundation.dart';

/// HiKorea's dates: "20261021".
String ymdOf(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

DateTime? parseYmd(String? ymd) {
  if (ymd == null || !RegExp(r'^\d{8}$').hasMatch(ymd)) return null;
  return DateTime(int.parse(ymd.substring(0, 4)), int.parse(ymd.substring(4, 6)), int.parse(ymd.substring(6, 8)));
}

int _int(Object? v) => v is num ? v.toInt() : 0;

Map<String, String> _texts(Object? json) => json is Map
    ? {for (final e in json.entries) '${e.key}': e.value is String ? e.value as String : ''}
    : const {};

/// A desk's text in [language]; English when that one is empty.
String inLanguage(Map<String, String> texts, String language) {
  final text = texts[language];
  return text == null || text.trim().isEmpty ? texts['en'] ?? '' : text;
}

/// A counter at an immigration office, each with its own appointments.
@immutable
class HkDesk {
  const HkDesk({required this.seq, this.booth = const {}, this.details = const {}});

  final int seq;

  /// Its name, by language (en, uz, ru); dates and "AFTER 09:36" included.
  final Map<String, String> booth;

  /// What it handles and where it is, by language.
  final Map<String, String> details;

  static HkDesk? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['desk_seq'] is! int) return null;
    return HkDesk(seq: json['desk_seq'] as int, booth: _texts(json['booth']), details: _texts(json['details']));
  }
}

@immutable
class HkOffice {
  const HkOffice({required this.id, required this.nameEn, this.nameKo, this.shortCode, this.desks = const []});

  final String id;
  final String nameEn;
  final String? nameKo;
  final String? shortCode;
  final List<HkDesk> desks;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || '$nameEn ${nameKo ?? ''} ${shortCode ?? ''}'.toLowerCase().contains(q);
  }

  HkDesk? desk(int seq) => desks.where((d) => d.seq == seq).firstOrNull;

  static HkOffice? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final name = json['name_en'];
    if (name is! String) return null;
    final desks = [for (final d in (json['desks'] as List?) ?? const []) ?HkDesk.fromJson(d)];
    if (desks.isEmpty) return null;
    return HkOffice(
      id: json['office_id'] as String? ?? name,
      nameEn: name,
      nameKo: json['name_ko'] as String?,
      shortCode: json['short_code'] as String?,
      desks: desks,
    );
  }
}

/// An office found for a home address.
@immutable
class HkMatch {
  const HkMatch({required this.officeId, required this.nameEn, this.nameKo, this.district = ''});

  final String officeId;
  final String nameEn;
  final String? nameKo;

  /// The district in the address that decided it.
  final String district;

  static HkMatch? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['name_en'] is! String) return null;
    return HkMatch(
      officeId: json['office_id'] as String? ?? json['name_en'] as String,
      nameEn: json['name_en'] as String,
      nameKo: json['name_ko'] as String?,
      district: json['matched_district'] as String? ?? '',
    );
  }
}

/// How booked a day is: [open] (half or more free), [some] (filling up),
/// [full], [closed] (no appointments that day), [later] (past the booking
/// window: not taken yet).
enum HkTier { open, some, full, closed, later }

/// Which days a counter takes appointments on.
@immutable
class HkSchedule {
  const HkSchedule({required this.first, required this.last, this.holidays = const {}, this.weekdays = const {}});

  final String first;
  final String last;
  final Set<String> holidays;

  /// Monday 0 … Sunday 6.
  final Set<int> weekdays;

  static HkSchedule? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final first = json['bookable_min_ymd'], last = json['bookable_max_ymd'];
    if (first is! String || last is! String) return null;
    return HkSchedule(
      first: first,
      last: last,
      holidays: {for (final h in (json['holidays_ymd'] as List?) ?? const []) if (h is String) h},
      weekdays: {for (final d in (json['active_weekdays'] as List?) ?? const []) if (d is int) d},
    );
  }
}

/// A counter's next months, as the server last saw them on HiKorea.
@immutable
class HkCalendar {
  HkCalendar({
    required this.deskSeq,
    this.listed = const {},
    this.schedule,
    this.capacity = const {},
    this.checkedAt,
    this.status = 'unknown',
  }) : days = _days(listed, schedule);

  final int deskSeq;

  /// Days HiKorea lists, with how many are booked.
  final Map<String, int> listed;
  final HkSchedule? schedule;

  /// Days whose timetable the server has read: how many appointments each takes.
  final Map<String, int> capacity;

  /// When the server last read this counter.
  final DateTime? checkedAt;

  /// 'ok', 'failing' or 'unknown'.
  final String status;

  /// Every day one can book: those listed, and the working days between the
  /// first and the last that aren't (no bookings yet), as the web page has it.
  final Map<String, int> days;

  static Map<String, int> _days(Map<String, int> listed, HkSchedule? schedule) {
    final days = {...listed};
    final first = parseYmd(schedule?.first), last = parseYmd(schedule?.last);
    if (schedule != null && first != null && last != null) {
      for (var d = first; !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1)) {
        final ymd = ymdOf(d);
        if (days.containsKey(ymd) || schedule.holidays.contains(ymd)) continue;
        if (schedule.weekdays.isNotEmpty && !schedule.weekdays.contains(d.weekday - 1)) continue;
        days[ymd] = 0;
      }
    }
    return days;
  }

  /// The last day one can book now; null when nothing is known.
  late final DateTime? windowEnd = () {
    final ends = [?schedule?.last, ...days.keys]..sort();
    return ends.isEmpty ? null : parseYmd(ends.last);
  }();

  /// The most booked day of each weekday: as near as the list gets to a day's
  /// capacity, for days whose timetable hasn't been read.
  late final Map<int, int> _busiest = () {
    final most = <int, int>{};
    for (final MapEntry(:key, :value) in days.entries) {
      final weekday = parseYmd(key)!.weekday;
      if (value > (most[weekday] ?? 0)) most[weekday] = value;
    }
    return most;
  }();

  /// How booked [day] is, and how full (0–1) for the bar under it.
  (HkTier, double) tierOf(String day) {
    final taken = days[day];
    if (taken == null) {
      final end = windowEnd;
      return (end != null && parseYmd(day)!.isAfter(end) ? HkTier.later : HkTier.closed, 0);
    }
    if (capacity[day] case final cap? when cap > 0) {
      final ratio = (taken / cap).clamp(0.0, 1.0);
      if (taken >= cap) return (HkTier.full, 1);
      return (ratio < 0.5 ? HkTier.open : HkTier.some, ratio);
    }
    if (taken == 0) return (HkTier.open, 0);
    final most = _busiest[parseYmd(day)!.weekday] ?? taken;
    final ratio = (taken / most).clamp(0.0, 1.0);
    return (ratio >= 1 ? HkTier.full : HkTier.some, ratio);
  }

  /// Days from [today] on that aren't fully booked, in order.
  List<DateTime> openDays(DateTime today, {DateTime? until}) {
    final from = ymdOf(today), to = until == null ? null : ymdOf(until);
    final open = [
      for (final d in days.keys)
        if (d.compareTo(from) >= 0 && (to == null || d.compareTo(to) <= 0) && tierOf(d).$1 != HkTier.full) d,
    ]..sort();
    return [for (final d in open) parseYmd(d)!];
  }

  /// The first day from [today] on that isn't fully booked.
  DateTime? earliestOpen(DateTime today) => openDays(today).firstOrNull;

  static HkCalendar fromJson(Map<String, dynamic> json) {
    final checked = json['desk_checked_at'] ?? json['last_polled_at'];
    final dates = [for (final d in (json['dates'] as List?) ?? const []) if (d is Map<String, dynamic> && d['visi_ymd'] is String) d];
    final capacity = json['day_capacity'];
    return HkCalendar(
      deskSeq: _int(json['desk_seq']),
      listed: {for (final d in dates) d['visi_ymd'] as String: _int(d['taken'])},
      schedule: HkSchedule.fromJson(json['schedule']),
      capacity: {
        if (capacity is Map)
          for (final MapEntry(:key, :value) in capacity.entries)
            if (key is String && value is num && value > 0) key: value.toInt(),
        for (final d in dates)
          if (d['capacity'] case final num cap when cap > 0) d['visi_ymd'] as String: cap.toInt(),
      },
      checkedAt: checked is String ? DateTime.tryParse(checked)?.toLocal() : null,
      status: json['desk_status'] as String? ?? 'unknown',
    );
  }
}

/// One appointment time on a day: how many it takes, how many are left.
@immutable
class HkTimeSlot {
  const HkTimeSlot({required this.time, required this.capacity, required this.available});

  /// "09:00".
  final String time;
  final int capacity;
  final int available;

  bool get morning => (int.tryParse(time.split(':').first) ?? 0) < 12;
}

/// A day at a counter, checked on HiKorea just now.
@immutable
class HkDay {
  const HkDay({required this.slots, required this.capacity, required this.taken, required this.available});

  final List<HkTimeSlot> slots;
  final int capacity;
  final int taken;
  final int available;

  static HkDay fromJson(Map<String, dynamic> json) => HkDay(
        slots: [
          for (final s in (json['time_slots'] as List?) ?? const [])
            if (s is Map<String, dynamic> && s['time'] is String && _int(s['capacity']) > 0)
              HkTimeSlot(time: s['time'] as String, capacity: _int(s['capacity']), available: _int(s['available'])),
        ],
        capacity: _int(json['total_capacity']),
        taken: _int(json['total_taken']),
        available: _int(json['total_available']),
      );
}

/// Days at a counter the server keeps checking for this person.
@immutable
class HkWatch {
  const HkWatch({
    required this.id,
    required this.officeId,
    required this.officeNameEn,
    required this.deskSeq,
    this.booth = const {},
    required this.start,
    required this.end,
    required this.status,
  });

  final int id;
  final String officeId;
  final String officeNameEn;
  final int deskSeq;
  final Map<String, String> booth;
  final DateTime start;
  final DateTime end;

  /// 'active', 'expired', 'cancelled' or 'undeliverable'.
  final String status;

  bool get active => status == 'active';

  static HkWatch? fromJson(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! int) return null;
    final start = parseYmd(json['start_ymd'] as String?), end = parseYmd(json['end_ymd'] as String?);
    if (start == null || end == null) return null;
    return HkWatch(
      id: json['id'] as int,
      officeId: json['office_id'] as String? ?? '',
      officeNameEn: json['office_name_en'] as String? ?? '',
      deskSeq: _int(json['desk_seq']),
      booth: _texts(json['booth']),
      start: start,
      end: end,
      status: json['status'] as String? ?? 'active',
    );
  }
}
