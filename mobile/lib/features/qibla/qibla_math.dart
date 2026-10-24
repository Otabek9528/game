import 'dart:math' as math;

import 'wmm2025.g.dart';

/// The Kaaba, as on the web page (pages/qibla/qibla.js).
const kaabaLat = 21.4225;
const kaabaLon = 39.8262;

const _rad = math.pi / 180;
const _deg = 180 / math.pi;

double normalizeDegrees(double a) {
  final x = a % 360;
  return x < 0 ? x + 360 : x;
}

/// From [from] to [to] the short way round: −180…180, positive clockwise.
double signedDifference(double from, double to) {
  var d = (to - from) % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}

/// Mean direction of [angles] and their spread (circular standard
/// deviation), both in degrees.
({double mean, double std}) circularStats(Iterable<double> angles) {
  var s = 0.0, c = 0.0, n = 0;
  for (final a in angles) {
    s += math.sin(a * _rad);
    c += math.cos(a * _rad);
    n++;
  }
  if (n == 0) return (mean: 0, std: double.infinity);
  final r = math.sqrt(s * s + c * c) / n;
  final std = r >= 1 ? 0.0 : math.sqrt(-2 * math.log(math.max(r, 1e-12))) * _deg;
  return (mean: normalizeDegrees(math.atan2(s, c) * _deg), std: std);
}

// ------------------------------------------------------------------ bearing

/// The way to the Kaaba from a place: the direction to face (degrees from
/// true north) and how far it is.
class QiblaBearing {
  const QiblaBearing({required this.bearing, required this.distanceKm});

  final double bearing;
  final double distanceKm;
}

/// On the WGS84 ellipsoid (Vincenty), a few tenths of a degree closer than a
/// sphere at long range; the sphere answers where Vincenty doesn't converge
/// (only near the antipode, which is in the Pacific).
QiblaBearing qiblaFrom(double lat, double lon) =>
    _vincenty(lat, lon, kaabaLat, kaabaLon) ?? _sphere(lat, lon, kaabaLat, kaabaLon);

QiblaBearing? _vincenty(double lat1, double lon1, double lat2, double lon2) {
  const a = 6378137.0;
  const f = 1 / 298.257223563;
  const b = a * (1 - f);
  final l = (lon2 - lon1) * _rad;
  final u1 = math.atan((1 - f) * math.tan(lat1 * _rad));
  final u2 = math.atan((1 - f) * math.tan(lat2 * _rad));
  final sinU1 = math.sin(u1), cosU1 = math.cos(u1);
  final sinU2 = math.sin(u2), cosU2 = math.cos(u2);

  var lambda = l;
  double sinLambda, cosLambda, sinSigma, cosSigma, sigma, cosSqAlpha, cos2SigmaM;
  for (var i = 0; i < 200; i++) {
    sinLambda = math.sin(lambda);
    cosLambda = math.cos(lambda);
    final t1 = cosU2 * sinLambda;
    final t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
    sinSigma = math.sqrt(t1 * t1 + t2 * t2);
    if (sinSigma == 0) return const QiblaBearing(bearing: 0, distanceKm: 0);
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    sigma = math.atan2(sinSigma, cosSigma);
    final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    cosSqAlpha = 1 - sinAlpha * sinAlpha;
    cos2SigmaM = cosSqAlpha == 0 ? 0 : cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
    final c = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
    final previous = lambda;
    lambda = l +
        (1 - c) *
            f *
            sinAlpha *
            (sigma + c * sinSigma * (cos2SigmaM + c * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    if ((lambda - previous).abs() < 1e-12) {
      final uSq = cosSqAlpha * (a * a - b * b) / (b * b);
      final aa = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
      final bb = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
      final deltaSigma = bb *
          sinSigma *
          (cos2SigmaM +
              bb /
                  4 *
                  (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                      bb / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
      final metres = b * aa * (sigma - deltaSigma);
      final bearing = math.atan2(cosU2 * math.sin(lambda), cosU1 * sinU2 - sinU1 * cosU2 * math.cos(lambda));
      return QiblaBearing(bearing: normalizeDegrees(bearing * _deg), distanceKm: metres / 1000);
    }
  }
  return null;
}

QiblaBearing _sphere(double lat1, double lon1, double lat2, double lon2) {
  final p1 = lat1 * _rad, p2 = lat2 * _rad, dl = (lon2 - lon1) * _rad;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
  final dp = p2 - p1;
  final h = math.pow(math.sin(dp / 2), 2) + math.cos(p1) * math.cos(p2) * math.pow(math.sin(dl / 2), 2);
  return QiblaBearing(
    bearing: normalizeDegrees(math.atan2(y, x) * _deg),
    distanceKm: 2 * 6371 * math.asin(math.sqrt(h)),
  );
}

// ------------------------------------------------------------------ magnetism

/// Earth's magnetic field at a place and time.
class MagneticField {
  const MagneticField({required this.declination, required this.inclination, required this.intensity});

  /// Degrees east of true north that a compass needle points: true =
  /// magnetic + declination.
  final double declination;
  final double inclination;

  /// Total strength, in microtesla (the unit Android's sensor reports).
  final double intensity;
}

/// NOAA's World Magnetic Model 2025, the model the web page uses
/// (wmm.bundle.js): within half a degree almost everywhere until 2030.
MagneticField magneticField(double lat, double lon, DateTime when, {double altitudeKm = 0}) {
  const n = Wmm2025.maxDegree;
  final year = when.year + (when.difference(DateTime.utc(when.year)).inSeconds / 31557600);
  final dt = year - Wmm2025.epoch;

  // Geodetic (WGS84) to geocentric spherical coordinates.
  const a = 6378.137;
  const f = 1 / 298.257223563;
  const e2 = f * (2 - f);
  final phi = lat * _rad;
  final sinPhi = math.sin(phi);
  final rc = a / math.sqrt(1 - e2 * sinPhi * sinPhi);
  final p = (rc + altitudeKm) * math.cos(phi);
  final z = (rc * (1 - e2) + altitudeKm) * sinPhi;
  final r = math.sqrt(p * p + z * z);
  final phig = math.asin(z / r);

  // Schmidt semi-normalised associated Legendre functions of sin(phig).
  final count = (n + 1) * (n + 2) ~/ 2;
  final pcup = List<double>.filled(count, 0);
  final dpcup = List<double>.filled(count, 0);
  final x = math.sin(phig);
  final c = math.sqrt((1 - x) * (1 + x));
  pcup[0] = 1;
  for (var i = 1; i <= n; i++) {
    for (var m = 0; m <= i; m++) {
      final k = i * (i + 1) ~/ 2 + m;
      if (i == m) {
        final k1 = (i - 1) * i ~/ 2 + m - 1;
        pcup[k] = c * pcup[k1];
        dpcup[k] = c * dpcup[k1] + x * pcup[k1];
      } else if (i == 1 && m == 0) {
        pcup[k] = x * pcup[0];
        dpcup[k] = x * dpcup[0] - c * pcup[0];
      } else {
        final k1 = (i - 2) * (i - 1) ~/ 2 + m;
        final k2 = (i - 1) * i ~/ 2 + m;
        if (m > i - 2) {
          pcup[k] = x * pcup[k2];
          dpcup[k] = x * dpcup[k2] - c * pcup[k2];
        } else {
          final q = ((i - 1) * (i - 1) - m * m) / ((2 * i - 1) * (2 * i - 3));
          pcup[k] = x * pcup[k2] - q * pcup[k1];
          dpcup[k] = x * dpcup[k2] - c * pcup[k2] - q * dpcup[k1];
        }
      }
    }
  }
  final schmidt = List<double>.filled(count, 0);
  schmidt[0] = 1;
  for (var i = 1; i <= n; i++) {
    final k = i * (i + 1) ~/ 2;
    schmidt[k] = schmidt[(i - 1) * i ~/ 2] * (2 * i - 1) / i;
    for (var m = 1; m <= i; m++) {
      schmidt[k + m] = schmidt[k + m - 1] * math.sqrt((i - m + 1) * (m == 1 ? 2 : 1) / (i + m));
    }
  }
  for (var k = 0; k < count; k++) {
    pcup[k] *= schmidt[k];
    dpcup[k] = -dpcup[k] * schmidt[k];
  }

  // The field in spherical coordinates.
  const ref = 6371.2;
  final lambda = lon * _rad;
  var bx = 0.0, by = 0.0, bz = 0.0;
  for (var i = 1; i <= n; i++) {
    final power = math.pow(ref / r, i + 2).toDouble();
    for (var m = 0; m <= i; m++) {
      final k = i * (i + 1) ~/ 2 + m;
      final g = Wmm2025.g[k] + dt * Wmm2025.gDot[k];
      final h = Wmm2025.h[k] + dt * Wmm2025.hDot[k];
      final cosM = math.cos(m * lambda), sinM = math.sin(m * lambda);
      bz -= power * (g * cosM + h * sinM) * (i + 1) * pcup[k];
      by += power * (g * sinM - h * cosM) * m * pcup[k];
      bx -= power * (g * cosM + h * sinM) * dpcup[k];
    }
  }
  final cosPhig = math.cos(phig);
  if (cosPhig.abs() > 1e-10) by /= cosPhig;

  // Back to geodetic north/east/down.
  final psi = phig - phi;
  final north = bx * math.cos(psi) - bz * math.sin(psi);
  final down = bx * math.sin(psi) + bz * math.cos(psi);
  final horizontal = math.sqrt(north * north + by * by);
  return MagneticField(
    declination: math.atan2(by, north) * _deg,
    inclination: math.atan2(down, horizontal) * _deg,
    intensity: math.sqrt(horizontal * horizontal + down * down) / 1000,
  );
}

// ------------------------------------------------------------------ sun

/// Where the sun is in the sky: degrees from true north, and above the
/// horizon. A check on the compass that no magnet can disturb.
class SunPosition {
  const SunPosition({required this.azimuth, required this.elevation});

  final double azimuth;
  final double elevation;

  bool get up => elevation > -0.83;
}

/// NOAA's solar position algorithm; good to about a hundredth of a degree.
SunPosition sunPosition(double lat, double lon, DateTime when) {
  final utc = when.toUtc();
  final jd = utc.millisecondsSinceEpoch / 86400000 + 2440587.5;
  final t = (jd - 2451545) / 36525;

  final l0 = normalizeDegrees(280.46646 + t * (36000.76983 + t * 0.0003032));
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final mr = m * _rad;
  final center = math.sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * mr) * (0.019993 - 0.000101 * t) +
      math.sin(3 * mr) * 0.000289;
  final trueLong = l0 + center;
  final omega = 125.04 - 1934.136 * t;
  final lambda = trueLong - 0.00569 - 0.00478 * math.sin(omega * _rad);
  final eps0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  final eps = eps0 + 0.00256 * math.cos(omega * _rad);
  final decl = math.asin(math.sin(eps * _rad) * math.sin(lambda * _rad));

  final y = math.pow(math.tan(eps * _rad / 2), 2).toDouble();
  final l0r = l0 * _rad;
  final eqTime = 4 *
      _deg *
      (y * math.sin(2 * l0r) -
          2 * e * math.sin(mr) +
          4 * e * y * math.sin(mr) * math.cos(2 * l0r) -
          0.5 * y * y * math.sin(4 * l0r) -
          1.25 * e * e * math.sin(2 * mr));

  final minutes = utc.hour * 60 + utc.minute + utc.second / 60 + utc.millisecond / 60000;
  final trueSolar = (minutes + eqTime + 4 * lon) % 1440;
  final hourAngle = (trueSolar / 4 < 0 ? trueSolar / 4 + 180 : trueSolar / 4 - 180) * _rad;

  final phi = lat * _rad;
  final cosZenith = (math.sin(phi) * math.sin(decl) + math.cos(phi) * math.cos(decl) * math.cos(hourAngle))
      .clamp(-1.0, 1.0);
  final zenith = math.acos(cosZenith);
  final azimuth = math.atan2(
    math.sin(hourAngle),
    math.cos(hourAngle) * math.sin(phi) - math.tan(decl) * math.cos(phi),
  );
  return SunPosition(azimuth: normalizeDegrees(azimuth * _deg + 180), elevation: 90 - zenith * _deg);
}

/// Twice a year the sun stands right over the Kaaba (about 27–28 May at
/// 09:18 UTC and 15–16 July at 09:27 UTC): wherever it is daytime, a
/// shadow then points straight away from the Qibla.
DateTime nextSunOverKaaba(DateTime now) {
  final utc = now.toUtc();
  for (final year in [utc.year, utc.year + 1]) {
    for (final moment in [
      DateTime.utc(year, 5, 27, 9, 18),
      DateTime.utc(year, 5, 28, 9, 18),
      DateTime.utc(year, 7, 15, 9, 27),
      DateTime.utc(year, 7, 16, 9, 27),
    ]) {
      if (moment.isAfter(utc)) return moment;
    }
  }
  return DateTime.utc(utc.year + 1, 5, 27, 9, 18);
}
