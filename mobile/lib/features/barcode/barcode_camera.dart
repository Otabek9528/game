import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// What the camera is doing.
enum CameraStatus { starting, running, paused, denied, failed }

/// The live camera that reads barcodes. One Dart side for both phones: the
/// mobile_scanner plugin reads with ML Kit on Android and with Apple's
/// Vision on an iPhone.
abstract class ScannerCamera extends ChangeNotifier {
  CameraStatus get status;
  bool get hasTorch;
  bool get torchOn;
  bool get canSwitch;

  /// Each code read and confirmed.
  ValueChanged<String>? onCode;

  /// The preview, reading only codes that cross [window] (in the preview's
  /// own coordinates).
  Widget preview(Rect window);

  /// Starts, or picks up again after [pause] or a refused permission.
  Future<void> start();
  Future<void> pause();
  Future<void> toggleTorch();
  Future<void> switchCamera();
}

typedef ScannerCameraFactory = ScannerCamera Function();

class MobileScannerCamera extends ScannerCamera {
  MobileScannerCamera() {
    _controller.addListener(notifyListeners);
    _codes = _controller.barcodes.listen(_onCapture);
  }

  final _controller = MobileScannerController(
    autoStart: false,
    // Products only: the EAN and UPC families. A QR code on the packet (most
    // Korean packets have one) is never taken for the product.
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    // Bars stay sharp from further away than at Android's default 640×480.
    cameraResolution: const Size(1280, 720),
    detectionTimeoutMs: 150,
  );
  late final StreamSubscription<BarcodeCapture> _codes;

  /// A short code waiting for a second sighting: see [_onCapture].
  String? _pending;
  DateTime _pendingAt = DateTime(0);

  @override
  CameraStatus get status {
    final state = _controller.value;
    final error = state.error;
    if (error != null) {
      return error.errorCode == MobileScannerErrorCode.permissionDenied ? CameraStatus.denied : CameraStatus.failed;
    }
    if (state.isRunning) return CameraStatus.running;
    if (!state.isInitialized || state.isStarting) return CameraStatus.starting;
    return CameraStatus.paused;
  }

  @override
  bool get hasTorch => _controller.value.torchState != TorchState.unavailable;

  @override
  bool get torchOn => _controller.value.torchState == TorchState.on;

  @override
  bool get canSwitch => (_controller.value.availableCameras ?? 0) > 1;

  /// EAN-13 and UPC-A carry a check digit over a long code: one reading is
  /// enough. The 8-digit kinds can be a slice of a longer code read at an
  /// angle, so they must be seen twice within a moment.
  void _onCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || !RegExp(r'^\d{8,14}$').hasMatch(code)) continue;
      final long = barcode.format == BarcodeFormat.ean13 || barcode.format == BarcodeFormat.upcA;
      final now = DateTime.now();
      if (!long && (_pending != code || now.difference(_pendingAt) > const Duration(milliseconds: 1500))) {
        _pending = code;
        _pendingAt = now;
        continue;
      }
      _pending = null;
      onCode?.call(code);
      return;
    }
  }

  @override
  Widget preview(Rect window) => MobileScanner(
        controller: _controller,
        scanWindow: window,
        scanWindowUpdateThreshold: 8,
        tapToFocus: true,
        placeholderBuilder: (_) => const ColoredBox(color: Colors.black),
        // Shown by the screen from [status] instead.
        errorBuilder: (_, _) => const ColoredBox(color: Colors.black),
      );

  @override
  Future<void> start() async {
    try {
      await _controller.start();
    } on MobileScannerException {
      // Reported through [status].
    }
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    try {
      await _controller.pause();
    } on MobileScannerException {
      // Not running: nothing to pause.
    }
  }

  @override
  Future<void> toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } on MobileScannerException {
      // No torch.
    }
  }

  @override
  Future<void> switchCamera() async {
    try {
      await _controller.switchCamera();
    } on MobileScannerException {
      // One camera only.
    }
  }

  @override
  void dispose() {
    _codes.cancel();
    _controller
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
