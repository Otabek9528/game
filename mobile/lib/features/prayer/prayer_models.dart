import 'dart:math' as math;

/// The day's six times, in order. Sunrise is not a prayer: it is where Fajr's
/// time ends, so the countdown runs to it between Fajr and sunrise.
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Calculation method and Asr school, same codes as the web app and Aladhan.
class PrayerSettings {
  const PrayerSettings({this.method = '3', this.madhab = '1'});

  /// Aladhan method: 3 Muslim World League (default), 1 Karachi, 4 Makkah,
  /// 5 Egypt, 2 ISNA.
  final String method;

  /// Asr school: 1 Hanafi (default), 0 Shafi'i / Maliki / Hanbali.
  final String madhab;

  static const _methods = {'1', '2', '3', '4', '5'};

  /// Reads the web app's `prayerSettings` value; anything unknown falls back
  /// to the defaults, like the web app does.
  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    final method = '${json['method']}';
    final madhab = '${json['madhab']}';
    return PrayerSettings(
      method: _methods.contains(method) ? method : '3',
      madhab: madhab == '0' || madhab == '1' ? madhab : '1',
    );
  }

  Map<String, dynamic> toJson() => {'method': method, 'madhab': madhab};

  @override
  bool operator ==(Object other) =>
      other is PrayerSettings && other.method == method && other.madhab == madhab;

  @override
  int get hashCode => Object.hash(method, madhab);
}

/// Where the user is, as last measured.
class SavedLocation {
  const SavedLocation({
    required this.lat,
    required this.lon,
    required this.city,
    required this.timestamp,
  });

  final double lat;
  final double lon;

  /// Null when the city lookup failed.
  final String? city;
  final DateTime timestamp;

  /// Same shape the web app keeps under `userLocation`, so the two can share.
  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        city: json['city'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['timestamp'] as num?)?.toInt() ?? 0,
        ),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'city': city,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  SavedLocation copyWith({DateTime? timestamp}) => SavedLocation(
        lat: lat,
        lon: lon,
        city: city,
        timestamp: timestamp ?? this.timestamp,
      );

  /// Great-circle distance in km.
  double distanceTo(double lat2, double lon2) {
    const rad = math.pi / 180;
    final dLat = (lat2 - lat) * rad;
    final dLon = (lon2 - lon) * rad;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat * rad) * math.cos(lat2 * rad) * math.pow(math.sin(dLon / 2), 2);
    return 2 * 6371 * math.asin(math.sqrt(h));
  }
}

/// One day's prayer times, in the phone's local time.
class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.times,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.key,
  });

  /// Midnight of the day these times are for.
  final DateTime date;
  final Map<Prayer, DateTime> times;
  final int hijriDay;

  /// 1 = Muharram … 12 = Dhu al-Hijjah.
  final int hijriMonth;
  final int hijriYear;

  /// Day + settings + place these times were computed for; a different key
  /// means they must be fetched again.
  final String key;

  static const _apiNames = {
    Prayer.fajr: 'Fajr',
    Prayer.sunrise: 'Sunrise',
    Prayer.dhuhr: 'Dhuhr',
    Prayer.asr: 'Asr',
    Prayer.maghrib: 'Maghrib',
    Prayer.isha: 'Isha',
  };

  /// Builds a day from Aladhan's `data` object. Times may read "05:12" or
  /// "05:12 (KST)".
  factory PrayerDay.fromAladhan(
    Map<String, dynamic> data, {
    required DateTime date,
    required String key,
  }) {
    final timings = data['timings'] as Map<String, dynamic>;
    final hijri = (data['date'] as Map<String, dynamic>)['hijri'] as Map<String, dynamic>;
    final day = DateTime(date.year, date.month, date.day);
    return PrayerDay(
      date: day,
      times: {
        for (final entry in _apiNames.entries)
          entry.key: _atTime(day, timings[entry.value] as String),
      },
      hijriDay: int.parse('${hijri['day']}'),
      hijriMonth: int.parse('${(hijri['month'] as Map<String, dynamic>)['number']}'),
      hijriYear: int.parse('${hijri['year']}'),
      key: key,
    );
  }

  static DateTime _atTime(DateTime day, String value) {
    final parts = value.split(' ').first.split(':');
    return DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  factory PrayerDay.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final times = json['times'] as Map<String, dynamic>;
    return PrayerDay(
      date: date,
      times: {
        for (final prayer in Prayer.values)
          prayer: DateTime.parse(times[prayer.name] as String),
      },
      hijriDay: json['hijriDay'] as int,
      hijriMonth: json['hijriMonth'] as int,
      hijriYear: json['hijriYear'] as int,
      key: json['key'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'times': {for (final e in times.entries) e.key.name: e.value.toIso8601String()},
        'hijriDay': hijriDay,
        'hijriMonth': hijriMonth,
        'hijriYear': hijriYear,
        'key': key,
      };

  /// The key for [day]'s times with [settings] at [place]. Coordinates are
  /// rounded to ~100 m, which never changes a prayer time.
  static String keyFor(DateTime day, PrayerSettings settings, SavedLocation place) =>
      '${day.year}-${day.month}-${day.day}|${settings.method}|${settings.madhab}'
      '|${place.lat.toStringAsFixed(3)}|${place.lon.toStringAsFixed(3)}';
}

/// Where [now] falls in the day.
class PrayerMoment {
  const PrayerMoment({
    required this.current,
    required this.next,
    required this.nextAt,
    required this.progress,
  });

  /// The window we are in. Between midnight and Fajr this is still Isha.
  final Prayer current;
  final Prayer next;
  final DateTime nextAt;

  /// 0–1 through the current window.
  final double progress;

  /// 0–1 across the whole day strip: whole windows passed plus the current
  /// one's progress, each window being a sixth.
  double get dayFraction =>
      ((current.index + progress) / Prayer.values.length).clamp(0.0, 1.0);

  Duration remaining(DateTime now) {
    final left = nextAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// Works out the current and next window for [now] from [day]'s times.
  /// Before Fajr, Isha is still current (from last night); after Isha, the
  /// next Fajr is tomorrow's, estimated from today's.
  factory PrayerMoment.at(PrayerDay day, DateTime now) {
    final order = Prayer.values;
    var index = -1;
    for (var i = 0; i < order.length; i++) {
      if (!now.isBefore(day.times[order[i]]!)) index = i;
    }

    final Prayer current;
    final DateTime start;
    final Prayer next;
    final DateTime end;
    if (index == -1) {
      current = Prayer.isha;
      start = day.times[Prayer.isha]!.subtract(const Duration(days: 1));
      next = Prayer.fajr;
      end = day.times[Prayer.fajr]!;
    } else if (index == order.length - 1) {
      current = Prayer.isha;
      start = day.times[Prayer.isha]!;
      next = Prayer.fajr;
      end = day.times[Prayer.fajr]!.add(const Duration(days: 1));
    } else {
      current = order[index];
      start = day.times[current]!;
      next = order[index + 1];
      end = day.times[next]!;
    }

    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return PrayerMoment(
      current: current,
      next: next,
      nextAt: end,
      progress: total <= 0 ? 0 : (elapsed / total).clamp(0.0, 1.0),
    );
  }
}
