import 'package:flutter/services.dart';

/// One reading of the phone's compass (android/…/qibla/QiblaCompass.kt).
/// Directions are degrees from MAGNETIC north.
class CompassReading {
  const CompassReading({
    required this.top,
    required this.camera,
    required this.cameraUp,
    required this.tilt,
    required this.levelX,
    required this.levelY,
    required this.accuracy,
    required this.status,
    required this.field,
    required this.source,
  });

  /// Where the phone's top edge points (meaningful when it lies flat).
  final double top;

  /// Where the back camera looks (meaningful when the phone stands up).
  final double camera;

  /// How far above the horizon the camera looks.
  final double cameraUp;

  /// 0 lying flat, face up; 90 standing up.
  final double tilt;

  /// "Up" in the phone's own x (right) and y (top) directions, −1…1: what
  /// a spirit level shows.
  final double levelX;
  final double levelY;

  /// Android's estimate of the heading's error in degrees, or −1 when the
  /// phone doesn't give one.
  final double accuracy;

  /// The magnetometer's calibration: 0 unreliable, 1 low, 2 medium, 3 high,
  /// −1 not yet known.
  final int status;

  /// Strength of the magnetic field the phone measures, µT.
  final double field;

  /// "rotation", "geomagnetic" or "accel+magnet".
  final String source;

  factory CompassReading.fromMap(Map<Object?, Object?> m) => CompassReading(
        top: (m['top'] as num).toDouble(),
        camera: (m['camera'] as num).toDouble(),
        cameraUp: (m['cameraUp'] as num).toDouble(),
        tilt: (m['tilt'] as num).toDouble(),
        levelX: (m['levelX'] as num).toDouble(),
        levelY: (m['levelY'] as num).toDouble(),
        accuracy: (m['accuracy'] as num).toDouble(),
        status: (m['status'] as num).toInt(),
        field: (m['field'] as num).toDouble(),
        source: m['source'] as String,
      );
}

/// The back camera's picture as a Flutter texture, and how wide it sees.
class CameraFeed {
  const CameraFeed({
    required this.textureId,
    required this.width,
    required this.height,
    required this.sensorOrientation,
    required this.fovLong,
    required this.fovShort,
    required this.rotateInApp,
  });

  final int textureId;

  /// Buffer size in the sensor's own (landscape) orientation.
  final int width;
  final int height;
  final int sensorOrientation;

  /// Field of view along the sensor's long and short sides, degrees.
  final double fovLong;
  final double fovShort;

  /// True when the texture arrives unrotated and the app must turn it.
  final bool rotateInApp;

  factory CameraFeed.fromMap(Map<Object?, Object?> m) => CameraFeed(
        textureId: (m['textureId'] as num).toInt(),
        width: (m['width'] as num).toInt(),
        height: (m['height'] as num).toInt(),
        sensorOrientation: (m['sensorOrientation'] as num).toInt(),
        fovLong: (m['fovLong'] as num).toDouble(),
        fovShort: (m['fovShort'] as num).toDouble(),
        rotateInApp: m['rotateInApp'] as bool,
      );
}

/// Why the camera view can't show the camera.
enum CameraProblem { permission, noCamera, failed }

class CameraException implements Exception {
  const CameraException(this.problem);

  final CameraProblem problem;
}

/// The phone's compass and camera, as the Qibla page needs them.
abstract interface class QiblaDevice {
  /// About 30 readings a second while listened to; an error when the phone
  /// has no compass.
  Stream<CompassReading> readings();

  Future<bool> hasCompass();

  /// Keeps the screen on while the page is open.
  Future<void> keepScreenOn(bool on);

  /// Throws [CameraException].
  Future<CameraFeed> startCamera();
  Future<void> stopCamera();
}

class AndroidQiblaDevice implements QiblaDevice {
  const AndroidQiblaDevice();

  static const _events = EventChannel('vegukin/compass');
  static const _methods = MethodChannel('vegukin/qibla');

  @override
  Stream<CompassReading> readings() => _events
      .receiveBroadcastStream()
      .map((e) => CompassReading.fromMap(e as Map<Object?, Object?>));

  @override
  Future<bool> hasCompass() async {
    try {
      return await _methods.invokeMethod<bool>('hasCompass') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> keepScreenOn(bool on) async {
    try {
      await _methods.invokeMethod<void>('keepScreenOn', on);
    } on MissingPluginException {
      // Not on Android.
    }
  }

  @override
  Future<CameraFeed> startCamera() async {
    try {
      final map = await _methods.invokeMethod<Map<Object?, Object?>>('startCamera');
      if (map == null) throw const CameraException(CameraProblem.failed);
      return CameraFeed.fromMap(map);
    } on PlatformException catch (e) {
      throw CameraException(switch (e.code) {
        'permission' => CameraProblem.permission,
        'no_camera' => CameraProblem.noCamera,
        _ => CameraProblem.failed,
      });
    } on MissingPluginException {
      throw const CameraException(CameraProblem.noCamera);
    }
  }

  @override
  Future<void> stopCamera() async {
    try {
      await _methods.invokeMethod<void>('stopCamera');
    } on MissingPluginException {
      // Not on Android.
    }
  }
}
