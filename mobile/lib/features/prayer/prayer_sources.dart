import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'prayer_models.dart';

/// Fetches prayer times.
abstract interface class PrayerTimesSource {
  /// [count] consecutive days starting at [from]. A week ahead lets the
  /// home-screen widget roll over to new days without the app being opened.
  Future<List<PrayerDay>> fetchDays(
    DateTime from,
    int count,
    SavedLocation place,
    PrayerSettings settings,
  );
}

/// Prayer times from Aladhan — the same service and parameters as the web
/// app, so both show the same minutes. Uses the month calendar endpoint: one
/// request covers the whole range (two when it crosses into the next month).
class AladhanSource implements PrayerTimesSource {
  AladhanSource([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<PrayerDay>> fetchDays(
    DateTime from,
    int count,
    SavedLocation place,
    PrayerSettings settings,
  ) async {
    final first = DateTime(from.year, from.month, from.day);
    final wanted = [for (var i = 0; i < count; i++) DateTime(first.year, first.month, first.day + i)];
    final months = {for (final d in wanted) (d.year, d.month)};

    final byDate = <String, Map<String, dynamic>>{};
    for (final (year, month) in months) {
      for (final entry in await _month(year, month, place, settings)) {
        final gregorian = (entry['date'] as Map<String, dynamic>)['gregorian'] as Map<String, dynamic>;
        byDate['${gregorian['date']}'] = entry;
      }
    }

    String two(int n) => n.toString().padLeft(2, '0');
    return [
      for (final d in wanted)
        if (byDate['${two(d.day)}-${two(d.month)}-${d.year}'] case final entry?)
          PrayerDay.fromAladhan(entry, date: d, key: PrayerDay.keyFor(d, settings, place)),
    ];
  }

  Future<List<Map<String, dynamic>>> _month(
    int year,
    int month,
    SavedLocation place,
    PrayerSettings settings,
  ) async {
    final url = AppConfig.prayerApiBase.resolve('calendar/$year/$month').replace(
      queryParameters: {
        'latitude': '${place.lat}',
        'longitude': '${place.lon}',
        'method': settings.method,
        'school': settings.madhab,
      },
    );
    final response = await _client.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw http.ClientException('Aladhan ${response.statusCode}', url);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List).cast<Map<String, dynamic>>();
  }
}

/// Whether the app may read the phone's position right now.
enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// The phone's position and the name of the city it is in.
abstract interface class LocationSource {
  Future<LocationAccess> check();

  /// Shows the system permission dialog if it still can.
  Future<LocationAccess> request();

  Future<({double lat, double lon})> current();

  /// City name in English, or null when it can't be looked up.
  Future<String?> cityName(double lat, double lon);

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class DeviceLocationSource implements LocationSource {
  DeviceLocationSource([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  LocationAccess _map(LocationPermission permission) => switch (permission) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };

  @override
  Future<LocationAccess> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<({double lat, double lon})> current() async {
    // City-level accuracy is plenty for prayer times, and much quicker.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return (lat: position.latitude, lon: position.longitude);
  }

  @override
  Future<String?> cityName(double lat, double lon) async {
    try {
      // The web app's lookup (js/locationManager.js): street level, so a
      // town is named rather than its district ("Shirin", not "Boyovut").
      final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'json',
        'accept-language': 'en',
      });
      final response = await _client
          .get(url, headers: {'User-Agent': AppConfig.userAgent})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final address = (jsonDecode(response.body) as Map<String, dynamic>)['address']
          as Map<String, dynamic>?;
      final name = address?['city'] ?? address?['town'] ?? address?['village'] ?? address?['county'];
      // Korean cities come back as "Ansan-si"; people say "Ansan".
      return (name as String?)?.replaceFirst(RegExp(r'-si$', caseSensitive: false), '');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
