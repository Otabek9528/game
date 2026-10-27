import CoreLocation
import CoreMotion
import Flutter

/// The Qibla page's compass ("vegukin/compass"), sent as QiblaCompass.kt
/// sends it on Android (lib/features/qibla/qibla_sensors.dart): where the
/// phone's top edge points when it lies flat and where the back camera looks
/// when it stands up, both from MAGNETIC north (the app adds the
/// declination), with the heading's accuracy, the magnetometer's
/// calibration and the field's strength.
///
/// As Android's getRotationMatrix does it: "up" from Core Motion's gravity
/// (accelerometer and gyroscope fused, so steady) and magnetic north from
/// its calibrated magnetic field, smoothed. No attitude matrix, whose
/// orientation convention would be a guess. Core Location adds its estimate
/// of the heading's error.
final class QiblaCompass: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let motion = CMMotionManager()
  private let location = CLLocationManager()
  private var sink: FlutterEventSink?

  /// Degrees, from Core Location; −1 until it gives one.
  private var headingAccuracy = -1.0
  private var fieldMicroTesla = 0.0
  private var smoothed: (Double, Double, Double)?

  override init() {
    super.init()
    location.delegate = self
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard motion.isDeviceMotionAvailable,
          CMMotionManager.availableAttitudeReferenceFrames().contains(.xMagneticNorthZVertical)
    else {
      return FlutterError(code: "no_compass", message: "No magnetometer", details: nil)
    }
    sink = events
    motion.deviceMotionUpdateInterval = 1.0 / 30
    motion.magnetometerUpdateInterval = 1.0 / 30
    motion.startMagnetometerUpdates()
    motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, _ in
      if let data { self?.send(data) }
    }
    // Only for its accuracy estimate (it needs the location permission,
    // which the app has asked for by now).
    if CLLocationManager.headingAvailable() {
      location.headingFilter = kCLHeadingFilterNone
      location.startUpdatingHeading()
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motion.stopDeviceMotionUpdates()
    motion.stopMagnetometerUpdates()
    location.stopUpdatingHeading()
    sink = nil
    headingAccuracy = -1
    fieldMicroTesla = 0
    smoothed = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    headingAccuracy = newHeading.headingAccuracy
  }

  /// The page guides calibration itself; no system overlay over it.
  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    false
  }

  private func send(_ data: CMDeviceMotion) {
    guard let sink else { return }
    // The calibrated field; until Core Motion has one, the raw magnetometer.
    let measured = data.magneticField.field
    let raw = motion.magnetometerData?.magneticField
    let f = (measured.x != 0 || measured.y != 0 || measured.z != 0)
      ? (measured.x, measured.y, measured.z)
      : (raw?.x ?? 0, raw?.y ?? 0, raw?.z ?? 0)
    smoothed = smoothed.map { ($0.0 * 0.7 + f.0 * 0.3, $0.1 * 0.7 + f.1 * 0.3, $0.2 * 0.7 + f.2 * 0.3) } ?? f
    let b = smoothed ?? f

    // In the phone's own axes (x right, y top, z out of the screen): up,
    // east = field × up, north = up × east. Android's R has them as rows.
    let g = data.gravity
    guard let up = normalized(-g.x, -g.y, -g.z),
          let east = normalized(b.1 * up.2 - b.2 * up.1, b.2 * up.0 - b.0 * up.2, b.0 * up.1 - b.1 * up.0)
    else { return }
    let north = (up.1 * east.2 - up.2 * east.1, up.2 * east.0 - up.0 * east.2, up.0 * east.1 - up.1 * east.0)
    let r = [east.0, east.1, east.2, north.0, north.1, north.2, up.0, up.1, up.2]

    let field = data.magneticField
    let calibrated = field.accuracy != .uncalibrated
    if calibrated {
      let strength = (field.field.x * field.field.x + field.field.y * field.field.y + field.field.z * field.field.z)
        .squareRoot()
      fieldMicroTesla = fieldMicroTesla == 0 ? strength : fieldMicroTesla * 0.8 + strength * 0.2
    }
    // Android's SENSOR_STATUS_*: 0 unreliable … 3 high.
    let status: Int
    switch field.accuracy {
    case .low: status = 1
    case .medium: status = 2
    case .high: status = 3
    default: status = 0
    }

    func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
    func clamp(_ v: Double) -> Double { min(max(v, -1), 1) }
    let reading: [String: Any] = [
      "top": degrees(atan2(r[1], r[4])),
      "camera": degrees(atan2(-r[2], -r[5])),
      "cameraUp": degrees(asin(clamp(-r[8]))),
      "tilt": degrees(acos(clamp(r[8]))),
      "levelX": r[6],
      "levelY": r[7],
      "accuracy": headingAccuracy,
      "status": status,
      "field": calibrated ? fieldMicroTesla : 0,
      "source": "ios-motion",
    ]
    sink(reading)
  }

  private func normalized(_ x: Double, _ y: Double, _ z: Double) -> (Double, Double, Double)? {
    let length = (x * x + y * y + z * z).squareRoot()
    guard length > 1e-6 else { return nil }
    return (x / length, y / length, z / length)
  }
}
