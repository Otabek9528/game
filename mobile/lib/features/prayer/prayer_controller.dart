import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/key_value_store.dart';
import 'prayer_models.dart';
import 'prayer_sources.dart';

/// What the prayer card can show.
enum PrayerStatus {
  /// Nothing known yet; the first check is running.
  starting,

  /// Never located; the user has not been asked yet (or said no once).
  needsPermission,

  /// The user blocked location for the app; only system settings can undo it.
  permissionBlocked,

  /// The phone's location (GPS) is switched off.
  locationOff,

  /// Asking for a position failed and there is no saved one.
  locationFailed,

  /// Have a place, waiting for its times.
  loading,

  /// Times are on screen.
  ready,

  /// Have a place, but the times could not be fetched.
  timesFailed,
}

/// Keeps the user's location and today's prayer times, saving both so the
/// card is filled instantly on the next launch.
///
/// Like the web app, a saved location is reused rather than re-measured every
/// time: a new fix is only taken on the first launch, when the saved one is
/// older than [staleAfter], or when the user taps the city.
class PrayerController extends ChangeNotifier {
  PrayerController({
    required this._location,
    required this._times,
    required this._store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocationSource _location;
  final PrayerTimesSource _times;
  final KeyValueStore _store;
  final DateTime Function() _clock;

  static const staleAfter = Duration(hours: 6);

  /// A new fix this close to the saved one keeps the saved coordinates, so
  /// cached times stay valid (prayer times shift ~1 minute per 20 km).
  static const samePlaceKm = 3.0;

  PrayerStatus status = PrayerStatus.starting;
  PrayerSettings settings = const PrayerSettings();
  SavedLocation? place;

  /// Today's times, once known.
  PrayerDay? day;

  /// Today and the week after it, kept for the home-screen widget and so the
  /// card rolls over to a new day without the network.
  List<PrayerDay> days = const [];

  /// A location request is running.
  bool locating = false;

  /// The last location request failed; the saved place is still shown.
  bool lastLocateFailed = false;

  bool _fetching = false;

  DateTime get now => _clock();

  DateTime get _today {
    final n = _clock();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> start() async {
    settings = _readJson('prayer_settings', PrayerSettings.fromJson) ?? settings;
    place = _readJson('location', SavedLocation.fromJson);
    days = _readDays();
    if (place != null) {
      day = _todayFrom(days);
      if (day != null) status = PrayerStatus.ready;
    }
    notifyListeners();

    if (place == null) {
      final access = await _location.check();
      if (access == LocationAccess.granted) {
        await locate();
      } else {
        _setStatus(_statusFor(access));
      }
      return;
    }

    await loadTimes();
    if (_isStale) await locate();
  }

  /// Takes a new location fix and refreshes the times if the place changed.
  /// [userAsked]: the user tapped a button, so the permission dialog may show.
  Future<void> locate({bool userAsked = false}) async {
    if (locating) return;
    var access = await _location.check();
    if (access == LocationAccess.denied && userAsked) {
      access = await _location.request();
    }
    if (access != LocationAccess.granted) {
      if (place == null) {
        _setStatus(_statusFor(access));
      } else {
        lastLocateFailed = userAsked;
        notifyListeners();
      }
      return;
    }

    locating = true;
    lastLocateFailed = false;
    if (place == null) status = PrayerStatus.loading;
    notifyListeners();

    try {
      final fix = await _location.current();
      final previous = place;
      final distance = previous?.distanceTo(fix.lat, fix.lon) ?? double.infinity;
      final SavedLocation updated;
      if (previous != null && distance <= samePlaceKm && previous.city != null) {
        updated = previous.copyWith(timestamp: _clock());
      } else {
        final city = await _location.cityName(fix.lat, fix.lon);
        updated = SavedLocation(
          lat: fix.lat,
          lon: fix.lon,
          // A failed lookup after a short move is still the same city.
          city: city ?? (distance <= 25 ? previous?.city : null),
          timestamp: _clock(),
        );
      }
      place = updated;
      await _store.write('location', jsonEncode(updated.toJson()));
    } catch (_) {
      lastLocateFailed = true;
      if (place == null) status = PrayerStatus.locationFailed;
    } finally {
      locating = false;
      notifyListeners();
    }
    await loadTimes();
  }

  /// Makes sure [day] holds today's times for the current place and settings.
  /// Cheap to call often: it only fetches when something changed.
  Future<void> loadTimes() async {
    if (place == null || _fetching) return;
    // Past midnight, tomorrow's times may already be saved.
    day = _todayFrom(days) ?? (day?.date == _today ? day : null);
    _fetching = true;
    try {
      // Loops because the place, settings or date can change while a request
      // is in flight; it stops once [day] matches all three.
      while (day?.key != _todayKey) {
        if (day == null) _setStatus(PrayerStatus.loading);
        try {
          final fetched = await _times.fetchDays(_today, daysAhead, place!, settings);
          final today = _todayFrom(fetched);
          if (today == null) throw StateError('no times for today');
          days = fetched;
          day = today;
          await _store.write(
            'prayer_days',
            jsonEncode([for (final d in fetched) d.toJson()]),
          );
        } catch (_) {
          // Yesterday's times would be wrong today; only keep [day] if it is
          // still for today (e.g. only the place moved a little).
          if (day == null || day!.date != _today) {
            day = null;
            _setStatus(PrayerStatus.timesFailed);
          } else {
            notifyListeners();
          }
          return;
        }
      }
      _setStatus(PrayerStatus.ready);
    } finally {
      _fetching = false;
    }
  }

  /// The calculation method or Asr school changed (on the web prayers page).
  Future<void> applySettings(PrayerSettings value) async {
    if (value == settings) return;
    settings = value;
    await _store.write('prayer_settings', jsonEncode(value.toJson()));
    await loadTimes();
  }

  /// Pull-to-refresh and coming back to the app.
  Future<void> refresh() async {
    if (place == null) {
      await start();
      return;
    }
    await loadTimes();
    if (_isStale) await locate();
  }

  /// For web pages that ask for the position. Never shows the permission
  /// dialog: the app asks once, at first launch, and only the user's own taps
  /// ask again.
  Future<bool> hasLocationAccess() async =>
      await _location.check() == LocationAccess.granted;

  Future<void> openAppSettings() => _location.openAppSettings();
  Future<void> openLocationSettings() => _location.openLocationSettings();

  bool get _isStale =>
      place == null || _clock().difference(place!.timestamp) > staleAfter;

  String get _todayKey => PrayerDay.keyFor(_today, settings, place!);

  /// How many days [loadTimes] fetches: today plus a week.
  static const daysAhead = 8;

  PrayerDay? _todayFrom(List<PrayerDay> list) {
    if (place == null) return null;
    final key = _todayKey;
    for (final d in list) {
      if (d.key == key) return d;
    }
    return null;
  }

  List<PrayerDay> _readDays() {
    final raw = _store.read('prayer_days');
    if (raw == null) return const [];
    try {
      return [
        for (final d in jsonDecode(raw) as List) PrayerDay.fromJson(d as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  PrayerStatus _statusFor(LocationAccess access) => switch (access) {
        LocationAccess.deniedForever => PrayerStatus.permissionBlocked,
        LocationAccess.serviceOff => PrayerStatus.locationOff,
        _ => PrayerStatus.needsPermission,
      };

  void _setStatus(PrayerStatus value) {
    status = value;
    notifyListeners();
  }

  T? _readJson<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _store.read(key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
