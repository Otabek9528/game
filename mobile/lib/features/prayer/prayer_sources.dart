import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'prayer_models.dart';

/// Fetches one day's prayer times.
abstract interface class PrayerTimesSource {
  Future<PrayerDay> fetchDay(
    DateTime day,
    SavedLocation place,
    PrayerSettings settings,
  );
}

/// Prayer times from Aladhan — the same service and parameters as the web
/// app, so both show the same minutes.
class AladhanSource implements PrayerTimesSource {
  AladhanSource([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<PrayerDay> fetchDay(
    DateTime day,
    SavedLocation place,
    PrayerSettings settings,
  ) async {
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(day.day)}-${two(day.month)}-${day.year}';
    final url = AppConfig.prayerApiBase.resolve('timings/$date').replace(
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
    return PrayerDay.fromAladhan(
      body['data'] as Map<String, dynamic>,
      date: day,
      key: PrayerDay.keyFor(day, settings, place),
    );
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
      final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'json',
        'zoom': '10',
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
