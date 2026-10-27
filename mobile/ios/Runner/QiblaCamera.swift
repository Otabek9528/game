import AVFoundation
import Flutter

/// The back camera's picture for the Qibla page's camera view, as a Flutter
/// texture (lib/features/qibla/camera_view.dart), like QiblaCamera.kt. Frames
/// come in the sensor's own landscape orientation and the app turns them
/// (rotateInApp, sensorOrientation 90), the way Android's often do; the
/// field of view lets the app put the Kaaba marker in the right place.
final class QiblaCamera: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
  private let textures: FlutterTextureRegistry
  private let queue = DispatchQueue(label: "qibla-camera")
  private var session: AVCaptureSession?
  private var textureId: Int64?

  /// The newest frame, handed to Flutter on its raster thread.
  private var latest: CVPixelBuffer?
  private let lock = NSLock()

  /// Bumped by [stop]: a camera that opens after it was closed closes at once.
  private var generation = 0

  init(textures: FlutterTextureRegistry) {
    self.textures = textures
  }

  func start(_ result: @escaping FlutterResult) {
    stop()
    generation += 1
    let gen = generation
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      open(result, gen)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          guard gen == self.generation else { return result(FlutterError(code: "stopped", message: nil, details: nil)) }
          if granted {
            self.open(result, gen)
          } else {
            result(FlutterError(code: "permission", message: "Camera permission is off", details: nil))
          }
        }
      }
    default:
      result(FlutterError(code: "permission", message: "Camera permission is off", details: nil))
    }
  }

  private func open(_ result: @escaping FlutterResult, _ gen: Int) {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      return result(FlutterError(code: "no_camera", message: "No back camera", details: nil))
    }
    // 4:3, the whole sensor, so the field of view holds; at most 1920 wide,
    // light enough to hand Flutter 30 times a second.
    func size(_ format: AVCaptureDevice.Format) -> CMVideoDimensions {
      CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    }
    let fourThree = device.formats.filter {
      let d = size($0)
      return abs(Int(d.width) * 3 - Int(d.height) * 4) < 8 && d.width <= 1920
    }
    let format = fourThree.max(by: { Int(size($0).width) < Int(size($1).width) })
    let session = AVCaptureSession()
    session.beginConfiguration()
    session.sessionPreset = format == nil ? .high : .inputPriority
    let output = AVCaptureVideoDataOutput()
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(self, queue: queue)
    do {
      let input = try AVCaptureDeviceInput(device: device)
      guard session.canAddInput(input), session.canAddOutput(output) else {
        session.commitConfiguration()
        return result(FlutterError(code: "camera", message: "Can't use the camera", details: nil))
      }
      session.addInput(input)
      session.addOutput(output)
      // After the input is in: the session keeps a format set this way.
      if let format, (try? device.lockForConfiguration()) != nil {
        device.activeFormat = format
        device.unlockForConfiguration()
      }
      session.commitConfiguration()
    } catch {
      return result(FlutterError(code: "camera", message: error.localizedDescription, details: nil))
    }
    self.session = session
    let id = textures.register(self)
    textureId = id

    let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    let width = Int(max(dimensions.width, dimensions.height))
    let height = Int(min(dimensions.width, dimensions.height))
    // videoFieldOfView is along the long side; the short side's follows.
    let fovLong = Double(device.activeFormat.videoFieldOfView)
    let fovShort = 2 * atan(tan(fovLong * .pi / 360) * Double(height) / Double(width)) * 180 / .pi

    queue.async {
      session.startRunning()
      DispatchQueue.main.async {
        guard gen == self.generation else { return result(FlutterError(code: "stopped", message: nil, details: nil)) }
        let feed: [String: Any] = [
          "textureId": id,
          "width": width,
          "height": height,
          "sensorOrientation": 90,
          "fovLong": fovLong,
          "fovShort": fovShort,
          "rotateInApp": true,
        ]
        result(feed)
      }
    }
  }

  func stop() {
    generation += 1
    if let session {
      queue.async { session.stopRunning() }
    }
    session = nil
    if let id = textureId {
      textures.unregisterTexture(id)
    }
    textureId = nil
    lock.lock()
    latest = nil
    lock.unlock()
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    lock.lock()
    latest = buffer
    lock.unlock()
    DispatchQueue.main.async {
      if let id = self.textureId { self.textures.textureFrameAvailable(id) }
    }
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    lock.lock()
    defer { lock.unlock() }
    guard let latest else { return nil }
    return Unmanaged.passRetained(latest)
  }
}
