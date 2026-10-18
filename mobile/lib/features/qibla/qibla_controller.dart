import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../prayer/prayer_controller.dart';
import 'qibla_math.dart';
import 'qibla_sensors.dart';

/// What the Qibla page is showing.
enum QiblaPhase { loading, noLocation, noCompass, calibrating, compass }

/// Calibration, as on the web page: wave the phone in a figure of eight,
/// then hold it flat and still.
enum CalibrationStep { move, hold }

/// How far the phone is from facing the Qibla, in the web page's steps.
enum Facing { far, turn, close, aligned }

/// What weakens the compass right now, if anything.
enum SignalIssue { none, needsCalibration, tilted, interference }

/// The Qibla page's logic, apart from drawing: the place's Qibla and
/// magnetic declination, a smoothed true heading, signal quality,
/// calibration, and how far to turn.
class QiblaController extends ChangeNotifier {
  QiblaController({
    required this._device,
    required this._prayer,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final QiblaDevice _device;
  final PrayerController _prayer;
  final DateTime Function() _clock;

  // Same thresholds as pages/qibla/qibla.js.
  static const alignedWithin = 5.0;
  static const closeWithin = 15.0;
  static const turnWithin = 30.0;
  static const movementsNeeded = 8;
  static const _calibrationMinimum = Duration(seconds: 5);
  static const _stabilityWindow = Duration(milliseconds: 1200);
  static const _stableStd = 2.5;
  static const _tiltWarn = 35.0;
  static const _accuracyGate = 15.0;
  static const _stuckRevert = Duration(milliseconds: 2500);
  static const _quickCheck = Duration(seconds: 2);

  QiblaPhase phase = QiblaPhase.loading;

  /// The camera view: the heading is where the back camera looks.
  bool cameraMode = false;

  String? city;
  QiblaBearing? qibla;
  MagneticField? magnet;

  CompassReading? reading;

  /// Smoothed, from TRUE north.
  double heading = 0;

  /// Before smoothing and declination: the sensor's own number.
  double rawMagnetic = 0;
  int quality = 0;
  SignalIssue issue = SignalIssue.none;

  CalibrationStep step = CalibrationStep.move;
  int movements = 0;

  /// 0–1 while holding still.
  double holdProgress = 0;
  bool calibrationDone = false;

  StreamSubscription<CompassReading>? _sub;
  Timer? _quickTimer;
  bool _quickChecking = false;
  final _quickSamples = <double>[];
  final _history = <double>[];
  bool _seeded = false;
  DateTime _calibrationStart = DateTime(0);
  double _lastMove = 0;
  final _stability = <(DateTime, double)>[];
  DateTime? _stuckSince;
  List<double>? _recording;

  /// −180…180: how far to turn, positive to the right.
  double get difference => qibla == null ? 0 : signedDifference(heading, qibla!.bearing);

  Facing get facing {
    final d = difference.abs();
    if (d <= alignedWithin) return Facing.aligned;
    if (d <= closeWithin) return Facing.close;
    if (d <= turnWithin) return Facing.turn;
    return Facing.far;
  }

  /// The magnetic field's strength here per the model, µT: far from it the
  /// phone is near metal or electronics.
  double? get expectedField => magnet?.intensity;

  SunPosition? get sun {
    final place = _prayer.place;
    return place == null ? null : sunPosition(place.lat, place.lon, _clock());
  }

  DateTime get now => _clock();

  Future<void> start() async {
    final place = _prayer.place;
    if (place == null) {
      _set(QiblaPhase.noLocation);
      return;
    }
    city = place.city;
    qibla = qiblaFrom(place.lat, place.lon);
    magnet = magneticField(place.lat, place.lon, _clock().toUtc());
    if (!await _device.hasCompass()) {
      _set(QiblaPhase.noCompass);
      return;
    }
    unawaited(_device.keepScreenOn(true));
    _listen();
    _startQuickCheck();
  }

  /// Leaving the page or the app.
  void pause() {
    _sub?.cancel();
    _sub = null;
    _quickTimer?.cancel();
    unawaited(_device.keepScreenOn(false));
  }

  /// Back to the page: readings resume, smoothing starts afresh.
  void resume() {
    if (phase == QiblaPhase.noLocation || phase == QiblaPhase.noCompass) return;
    _history.clear();
    _seeded = false;
    unawaited(_device.keepScreenOn(true));
    _listen();
    if (phase == QiblaPhase.loading) _startQuickCheck();
  }

  @override
  void dispose() {
    pause();
    super.dispose();
  }

  /// The "Qayta kalibratsiya" button: the full two steps, whatever the
  /// signal says.
  void recalibrate() {
    _quickTimer?.cancel();
    _quickChecking = false;
    _startCalibration();
  }

  void setCameraMode(bool on) {
    if (cameraMode == on) return;
    cameraMode = on;
    _history.clear();
    _seeded = false;
    notifyListeners();
  }

  /// For the diagnostics panel: three seconds of true headings.
  Future<({double mean, double std, int count})> record() async {
    _recording = [];
    await Future<void>.delayed(const Duration(seconds: 3));
    final samples = _recording ?? [];
    _recording = null;
    final s = circularStats(samples);
    return (mean: s.mean, std: s.std, count: samples.length);
  }

  void _listen() {
    _sub?.cancel();
    _sub = _device.readings().listen(_onReading, onError: (_) => _set(QiblaPhase.noCompass));
  }

  void _set(QiblaPhase value) {
    phase = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------- readings

  void _onReading(CompassReading r) {
    reading = r;
    // Lying flat the top edge shows the way; standing up, the back camera.
    final facingMagnetic = cameraMode || r.tilt >= 45 ? r.camera : r.top;
    rawMagnetic = normalizeDegrees(facingMagnetic);
    final trueHeading = normalizeDegrees(facingMagnetic + (magnet?.declination ?? 0));
    _recording?.add(trueHeading);

    _history.add(trueHeading);
    if (_history.length > 5) _history.removeAt(0);
    final filtered = _history.length < 3 ? trueHeading : circularStats(_history).mean;
    heading = _seeded ? normalizeDegrees(heading + signedDifference(heading, filtered) * 0.35) : filtered;
    _seeded = true;

    _rate(r);
    if (_quickChecking) _quickEvaluate(trueHeading, r);
    if (phase == QiblaPhase.calibrating) _calibrate(trueHeading, r);
    notifyListeners();
  }

  bool _interference(CompassReading r) {
    final expected = expectedField;
    if (expected == null || r.field <= 0) return false;
    return (r.field - expected).abs() / expected > 0.25;
  }

  /// 1–4 dots: Android's own accuracy estimate when it gives one, else the
  /// heading's jitter; capped by the calibration state, tilt and
  /// interference.
  void _rate(CompassReading r) {
    final int fromHeading;
    if (r.accuracy >= 0) {
      fromHeading = r.accuracy < 8 ? 4 : r.accuracy < 15 ? 3 : r.accuracy < 25 ? 2 : 1;
    } else if (_history.length < 5) {
      fromHeading = 2;
    } else {
      final std = circularStats(_history).std;
      fromHeading = std < 1.5 ? 4 : std < 4 ? 3 : std < 10 ? 2 : 1;
    }
    final fromStatus = switch (r.status) { 0 => 1, 1 => 2, 2 => 3, _ => 4 };
    var q = math.min(fromHeading, fromStatus);
    var problem = q <= 1 ? SignalIssue.needsCalibration : SignalIssue.none;
    // Between flat and upright neither the top edge nor the camera points
    // clearly anywhere.
    if (!cameraMode && r.tilt > _tiltWarn && r.tilt < 60 && q > 2) {
      q = 2;
      problem = SignalIssue.tilted;
    }
    if (_interference(r)) {
      q = 1;
      problem = SignalIssue.interference;
    }
    quality = q;
    issue = problem;
  }

  // ---------------------------------------------------------------- quick check

  /// A silent check on opening: a steady, calibrated, undisturbed compass
  /// goes straight to the compass; otherwise, calibration.
  void _startQuickCheck() {
    _quickChecking = true;
    _quickSamples.clear();
    _quickTimer?.cancel();
    _quickTimer = Timer(_quickCheck, () {
      if (_quickChecking) {
        _quickChecking = false;
        _startCalibration();
      }
    });
  }

  void _quickEvaluate(double h, CompassReading r) {
    _quickSamples.add(h);
    if (_quickSamples.length < 8) return;
    final recent = _quickSamples.sublist(_quickSamples.length - 8);
    final steady = circularStats(recent).std <= _stableStd;
    final calibrated = r.status >= 2 && (r.accuracy < 0 || r.accuracy < _accuracyGate);
    if (steady && calibrated && r.tilt < _tiltWarn && !_interference(r)) {
      _quickChecking = false;
      _quickTimer?.cancel();
      calibrationDone = true;
      _set(QiblaPhase.compass);
    }
  }

  // ---------------------------------------------------------------- calibration

  void _startCalibration() {
    step = CalibrationStep.move;
    movements = 0;
    holdProgress = 0;
    calibrationDone = false;
    // From 0°, as the web page counts.
    _lastMove = 0;
    _stability.clear();
    _stuckSince = null;
    _calibrationStart = _clock();
    _set(QiblaPhase.calibrating);
  }

  void _calibrate(double h, CompassReading r) {
    final now = _clock();
    if (step == CalibrationStep.move) {
      if (signedDifference(_lastMove, h).abs() > 30) {
        movements = math.min(movementsNeeded, movements + 1);
        _lastMove = h;
      }
      final time = now.difference(_calibrationStart).inMilliseconds / _calibrationMinimum.inMilliseconds;
      final progress = math.min(1.0, time.clamp(0.0, 1.0) * 0.4 + movements / movementsNeeded * 0.6);
      // A fully calibrated magnetometer needs fewer turns.
      if (progress >= 1 || (r.status == 3 && movements >= movementsNeeded ~/ 2)) {
        step = CalibrationStep.hold;
        _stability.clear();
        _stuckSince = null;
      }
      return;
    }

    _stability.add((now, h));
    _stability.removeWhere((s) => now.difference(s.$1) > _stabilityWindow);
    final tiltOk = r.tilt < _tiltWarn;
    final accuracyOk = r.status != 0 && r.status != 1 && (r.accuracy < 0 || r.accuracy < _accuracyGate);
    if (_stability.length < 5) {
      holdProgress = 0;
      return;
    }
    final span = now.difference(_stability.first.$1).inMilliseconds;
    final stable = circularStats(_stability.map((s) => s.$2)).std <= _stableStd;
    final window = _stabilityWindow.inMilliseconds - 150;
    if (!stable || !tiltOk) {
      holdProgress = math.min(0.4, span / window * 0.4);
    } else if (!accuracyOk) {
      holdProgress = 0.5;
    } else {
      holdProgress = math.min(1.0, span / window);
    }

    // Steady and flat, but the phone still says uncalibrated: holding still
    // won't fix that; more turning might.
    if (stable && tiltOk && !accuracyOk) {
      _stuckSince ??= now;
      if (now.difference(_stuckSince!) > _stuckRevert) {
        step = CalibrationStep.move;
        movements = movementsNeeded - 4;
        holdProgress = 0;
        _stuckSince = null;
      }
    } else {
      _stuckSince = null;
    }

    if (holdProgress >= 1 && !calibrationDone) {
      calibrationDone = true;
      Timer(const Duration(milliseconds: 500), () {
        if (phase == QiblaPhase.calibrating && calibrationDone) {
          _history.clear();
          _seeded = false;
          _set(QiblaPhase.compass);
        }
      });
    }
  }
}
