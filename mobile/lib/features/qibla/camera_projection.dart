import 'dart:math' as math;
import 'dart:ui';

import 'qibla_math.dart';

/// Where directions in the world land on the camera picture, and back: a
/// pinhole camera looking toward [heading] (degrees from true north),
/// [pitch] degrees above the horizon, turned [roll] degrees about its own
/// axis (positive: the phone's right edge raised), seeing [hFov] × [vFov]
/// degrees across a picture of [size].
class CameraPose {
  const CameraPose({
    required this.heading,
    required this.pitch,
    required this.roll,
    required this.hFov,
    required this.vFov,
    required this.size,
  });

  final double heading;
  final double pitch;
  final double roll;
  final double hFov;
  final double vFov;
  final Size size;

  static const _rad = math.pi / 180;

  /// The picture's right, up and ahead, in a frame turned to [heading]:
  /// x along the horizon to the right, y ahead, z up.
  ({List<double> right, List<double> up, List<double> ahead}) get _axes {
    final p = pitch * _rad;
    final r = roll * _rad;
    final ahead = [0.0, math.cos(p), math.sin(p)];
    final up = [0.0, -math.sin(p), math.cos(p)];
    const right = [1.0, 0.0, 0.0];
    return (
      right: [for (var i = 0; i < 3; i++) right[i] * math.cos(r) + up[i] * math.sin(r)],
      up: [for (var i = 0; i < 3; i++) up[i] * math.cos(r) - right[i] * math.sin(r)],
      ahead: ahead,
    );
  }

  static double _dot(List<double> a, List<double> b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  /// The point on the picture where [azimuth] at [elevation] appears, or
  /// null when it is behind the camera.
  Offset? project(double azimuth, double elevation) {
    final a = signedDifference(heading, azimuth) * _rad;
    final e = elevation * _rad;
    final d = [math.cos(e) * math.sin(a), math.cos(e) * math.cos(a), math.sin(e)];
    final axes = _axes;
    final z = _dot(d, axes.ahead);
    if (z <= 0.05) return null;
    return Offset(
      size.width / 2 * (1 + _dot(d, axes.right) / z / math.tan(hFov / 2 * _rad)),
      size.height / 2 * (1 - _dot(d, axes.up) / z / math.tan(vFov / 2 * _rad)),
    );
  }

  /// The direction seen at [point]: azimuth and elevation, degrees.
  (double, double) unproject(Offset point) {
    final x = (point.dx / (size.width / 2) - 1) * math.tan(hFov / 2 * _rad);
    final y = (1 - point.dy / (size.height / 2)) * math.tan(vFov / 2 * _rad);
    final axes = _axes;
    final d = [for (var i = 0; i < 3; i++) axes.ahead[i] + axes.right[i] * x + axes.up[i] * y];
    final length = math.sqrt(_dot(d, d));
    return (
      normalizeDegrees(heading + math.atan2(d[0], d[1]) / _rad),
      math.asin(d[2] / length) / _rad,
    );
  }
}
