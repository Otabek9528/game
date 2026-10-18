import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/qibla/qibla_math.dart';

void main() {
  group('magnetic declination (WMM-2025)', () {
    // Reference values from the web app's own model (pages/qibla/wmm.bundle.js,
    // run under node): the app and the web page must agree.
    final cases = [
      ('Seoul', 37.5665, 126.978, DateTime.utc(2026, 10, 18), -9.0211, 51.4307, 54.6528),
      ('Ansan', 37.3219, 126.8309, DateTime.utc(2026, 10, 18), -8.9365, 51.3358, 54.3882),
      ('Shirin', 40.5, 68.75, DateTime.utc(2026, 10, 18), 5.441, 53.5567, 60.8905),
      ('Tashkent', 41.2995, 69.2401, DateTime.utc(2026, 10, 18), 5.6904, 53.9778, 61.7591),
      ('Makkah', 21.4225, 39.8262, DateTime.utc(2026, 10, 18), 3.5018, 40.9927, 31.5163),
      ('London', 51.5, -0.13, DateTime.utc(2026, 10, 18), 1.2121, 49.1302, 66.5427),
      ('Sydney', -33.9, 151.2, DateTime.utc(2026, 10, 18), 12.8367, 56.9937, -64.4242),
      ('Reykjavik', 64.1, -21.9, DateTime.utc(2026, 10, 18), -11.0086, 52.5767, 75.3926),
      ('Null island', 0.0, 0.0, DateTime.utc(2026, 10, 18), -3.7948, 31.7919, -30.1979),
      ('Seoul', 37.5665, 126.978, DateTime.utc(2028, 1, 1), -9.0683, 51.4665, 54.6894),
      ('Ansan', 37.3219, 126.8309, DateTime.utc(2028, 1, 1), -8.984, 51.3717, 54.4253),
      ('Shirin', 40.5, 68.75, DateTime.utc(2028, 1, 1), 5.4641, 53.6310, 60.9092),
      ('Tashkent', 41.2995, 69.2401, DateTime.utc(2028, 1, 1), 5.7128, 54.0536, 61.7787),
      ('Makkah', 21.4225, 39.8262, DateTime.utc(2028, 1, 1), 3.4918, 41.0275, 31.567),
      ('London', 51.5, -0.13, DateTime.utc(2028, 1, 1), 1.4176, 49.1743, 66.5547),
      ('Sydney', -33.9, 151.2, DateTime.utc(2028, 1, 1), 12.8627, 56.9732, -64.4277),
      ('Reykjavik', 64.1, -21.9, DateTime.utc(2028, 1, 1), -10.6504, 52.5933, 75.3804),
      ('Null island', 0.0, 0.0, DateTime.utc(2028, 1, 1), -3.6456, 31.7599, -30.2037),
    ];
    for (final (name, lat, lon, date, decl, intensity, incl) in cases) {
      test('$name, ${date.year}-${date.month}', () {
        final f = magneticField(lat, lon, date);
        expect(f.declination, closeTo(decl, 0.01));
        expect(f.inclination, closeTo(incl, 0.01));
        expect(f.intensity, closeTo(intensity, 0.05));
      });
    }
  });

  test('the Qibla bearing and distance on the ellipsoid (GeographicLib values)', () {
    for (final (lat, lon, bearing, km) in [
      (37.3219, 126.8309, 285.7542, 8344.92), // Ansan
      (40.5, 68.75, 240.9536, 3452.38), // Shirin
      (51.5, -0.13, 118.859, 4794.49), // London
      (-33.9, 151.2, 277.3062, 13236.54), // Sydney
      (40.7128, -74.006, 58.396, 10323.92), // New York
    ]) {
      final q = qiblaFrom(lat, lon);
      expect(q.bearing, closeTo(bearing, 0.001));
      expect(q.distanceKm, closeTo(km, 0.05));
    }
  });

  test('the sun stands over the Kaaba on its two yearly days', () {
    final noon = sunPosition(kaabaLat, kaabaLon, DateTime.utc(2026, 5, 27, 9, 18));
    expect(noon.elevation, greaterThan(89.4));
    final july = sunPosition(kaabaLat, kaabaLon, DateTime.utc(2026, 7, 15, 9, 27));
    expect(july.elevation, greaterThan(89.4));
    expect(nextSunOverKaaba(DateTime.utc(2026, 10, 18)), DateTime.utc(2027, 5, 27, 9, 18));
    expect(nextSunOverKaaba(DateTime.utc(2026, 5, 27, 10)), DateTime.utc(2026, 5, 28, 9, 18));
  });

  test('the sun rises in the east and sets in the west', () {
    // Ansan, 18 October 2026 (KST = UTC+9): sunrise is about 06:45, so at
    // 07:45 the sun is some 11° up in the east-southeast.
    final morning = sunPosition(37.32, 126.83, DateTime.utc(2026, 10, 17, 22, 45));
    expect(morning.azimuth, inInclusiveRange(100, 120));
    expect(morning.elevation, inInclusiveRange(8, 14));
    final noon = sunPosition(37.32, 126.83, DateTime.utc(2026, 10, 18, 3, 25));
    expect(noon.azimuth, inInclusiveRange(170, 190));
    expect(noon.elevation, inInclusiveRange(40, 46));
  });

  test('angles: the short way round and their spread', () {
    expect(signedDifference(350, 10), 20);
    expect(signedDifference(10, 350), -20);
    expect(normalizeDegrees(-30), 330);
    final s = circularStats([359, 1, 0]);
    expect(signedDifference(s.mean, 0).abs(), lessThan(1e-9));
    expect(s.std, lessThan(1));
  });
}
