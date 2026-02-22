// camera.js — Camera management module (persistent stream)
// getUserMedia is called ONCE. Stream persists across scanner/wizard.
// Exposes: window.Camera
// ============================================
// STRATEGY: Trust the OS's facingMode:'environment' selection (which is
// virtually always the main back camera on Android), verify it has torch,
// and only probe further if it doesn't. This guarantees a single permission
// prompt in Telegram WebView for 95%+ of devices.
// ============================================

window.Camera = (() => {

  let videoStream = null;
  let cameraTrack = null;
  let imageCapture = null;
  let torchEnabled = false;
  let backCameraIds = [];
  let currentDeviceId = null;
  let currentIndexAmongBack = 0;
  let _initialized = false;

  // --- Getters ---
  function getTrack()        { return cameraTrack; }
  function getStream()       { return videoStream; }
  function getImageCapture() { return imageCapture; }
  function isTorchOn()       { return torchEnabled; }
  function isActive()        { return !!videoStream && cameraTrack && cameraTrack.readyState === 'live'; }

  // ============================================
  // OPEN — acquires stream ONCE, reuses after
  // ============================================
  async function open(videoElement) {
    // If we already have a live stream, just reattach
    if (isActive()) {
      await _attachToVideo(videoElement);
      return _getInfo();
    }

    // ── Step 1: Single permission prompt ──────────────────────
    // Request environment camera with high resolution.
    // On Android, this virtually always returns the main back camera.
    console.log('[Camera] Requesting environment camera (single prompt)...');
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      },
      audio: false
    });
    cameraTrack = videoStream.getVideoTracks()[0];
    currentDeviceId = cameraTrack.getSettings().deviceId;

    const settings = cameraTrack.getSettings();
    console.log('[Camera] Got camera:', currentDeviceId,
      'resolution:', settings.width, 'x', settings.height);

    // ── Step 2: Check if this camera has torch ────────────────
    const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};

    if (caps.torch) {
      // ✅ Main camera with torch — done! No probing needed.
      console.log('[Camera] ✅ Default environment camera has torch — using it');
    } else {
      // ── Step 3: Rare fallback — default lacks torch ─────────
      // Use label-based heuristic to find main back camera.
      // This minimizes extra getUserMedia calls.
      console.log('[Camera] ⚠ Default camera lacks torch — trying label-based fallback');

      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoCams = devices.filter(d => d.kind === 'videoinput');

      console.log('[Camera] Available cameras:', videoCams.map(c =>
        `${c.deviceId.substring(0, 8)}… "${c.label}"`));

      // After first getUserMedia, labels are populated.
      // Filter out front/ultrawide/macro/depth — keep only likely main cameras.
      const mainCandidates = videoCams.filter(cam => {
        const label = (cam.label || '').toLowerCase();
        const isFront = label.includes('front') || label.includes('user') ||
                        label.includes('selfie') || label.includes('facetime');
        const isUltrawide = label.includes('ultra') || label.includes('wide');
        const isMacro = label.includes('macro') || label.includes('depth');
        const isTele = label.includes('tele');
        // Exclude current camera (already checked) and non-main types
        return !isFront && !isUltrawide && !isMacro && !isTele &&
               cam.deviceId !== currentDeviceId;
      });

      console.log('[Camera] Fallback candidates:', mainCandidates.length);

      let found = false;
      for (const candidate of mainCandidates) {
        try {
          console.log('[Camera] Probing candidate:', candidate.label || candidate.deviceId);
          const testStream = await navigator.mediaDevices.getUserMedia({
            video: {
              deviceId: { exact: candidate.deviceId },
              width: { ideal: 1920 },
              height: { ideal: 1080 }
            },
            audio: false
          });
          const testTrack = testStream.getVideoTracks()[0];
          const testCaps = testTrack.getCapabilities ? testTrack.getCapabilities() : {};

          if (testCaps.torch) {
            // Found a torch camera — switch to it
            console.log('[Camera] ✅ Found torch camera via fallback:', candidate.label);
            videoStream.getTracks().forEach(t => t.stop());
            videoStream = testStream;
            cameraTrack = testTrack;
            currentDeviceId = testTrack.getSettings().deviceId;
            found = true;
            break;
          } else {
            testStream.getTracks().forEach(t => t.stop());
          }
        } catch (e) {
          console.log('[Camera] Probe failed for', candidate.label, e.message);
          continue;
        }
      }

      if (!found) {
        // No torch camera found — stick with original default.
        // Scanning still works, just no flashlight.
        console.log('[Camera] ℹ No torch camera found — using default without torch');
      }
    }

    // ── Step 4: Setup ─────────────────────────────────────────
    await _applyAutofocus();
    _setupImageCapture();
    await _attachToVideo(videoElement);
    await _enumerateBackCameras();
    _initialized = true;

    console.log('[Camera] Initialized. Device:', currentDeviceId,
      'Torch:', _hasTorch(), 'Back cameras:', backCameraIds.length);

    return _getInfo();
  }

  // ============================================
  // ATTACH TO CAPTURE VIDEO — reuses existing stream
  // ============================================
  async function openForCapture(videoElement) {
    if (isActive()) {
      // Just reattach the same live stream
      await _attachToVideo(videoElement);
      return;
    }
    // Stream died somehow — re-acquire using known deviceId
    console.log('[Camera] Stream lost — re-acquiring for capture...');
    const constraints = {
      video: currentDeviceId
        ? { deviceId: { exact: currentDeviceId }, width: { ideal: 1920 }, height: { ideal: 1080 } }
        : { facingMode: { ideal: 'environment' }, width: { ideal: 1920 }, height: { ideal: 1080 } },
      audio: false
    };
    videoStream = await navigator.mediaDevices.getUserMedia(constraints);
    cameraTrack = videoStream.getVideoTracks()[0];
    await _applyAutofocus();
    _setupImageCapture();
    await _attachToVideo(videoElement);
  }

  // ============================================
  // GRAB PHOTO — capture frame from video
  // ============================================
  async function grabPhoto(videoElement) {
    const canvas = document.createElement('canvas');
    canvas.width = videoElement.videoWidth;
    canvas.height = videoElement.videoHeight;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(videoElement, 0, 0);
    return new Promise(resolve => {
      canvas.toBlob(blob => resolve(blob), 'image/jpeg', 0.85);
    });
  }

  // ============================================
  // CYCLE — switch to next back camera (user-initiated, may prompt)
  // ============================================
  async function cycle(videoElement) {
    if (backCameraIds.length <= 1) return null;

    // Must stop old stream to switch device
    _killStream();

    currentIndexAmongBack = (currentIndexAmongBack + 1) % backCameraIds.length;
    const nextId = backCameraIds[currentIndexAmongBack];

    console.log('[Camera] Cycling to camera index', currentIndexAmongBack);

    videoStream = await navigator.mediaDevices.getUserMedia({
      video: { deviceId: { exact: nextId }, width: { ideal: 1920 }, height: { ideal: 1080 } },
      audio: false
    });
    cameraTrack = videoStream.getVideoTracks()[0];
    currentDeviceId = nextId;

    await _applyAutofocus();
    _setupImageCapture();
    await _attachToVideo(videoElement);

    return _getInfo();
  }

  // ============================================
  // DETACH — removes from video element but keeps stream alive
  // ============================================
  function detach(videoElement) {
    if (videoElement) {
      videoElement.pause();
      videoElement.srcObject = null;
    }
  }

  // ============================================
  // STOP — soft stop: reset torch, stream stays alive
  // ============================================
  async function stop() {
    if (torchEnabled && cameraTrack) {
      try {
        await cameraTrack.applyConstraints({ advanced: [{ torch: false }] });
      } catch (e) {}
    }
    torchEnabled = false;
  }

  // ============================================
  // DESTROY — hard stop: kill stream (page unload only)
  // ============================================
  function destroy() {
    _killStream();
    _initialized = false;
  }

  // ============================================
  // TORCH & FOCUS
  // ============================================
  async function toggleTorch() {
    if (!cameraTrack) return false;
    torchEnabled = !torchEnabled;
    try {
      await cameraTrack.applyConstraints({ advanced: [{ torch: torchEnabled }] });
      return torchEnabled;
    } catch (e) { torchEnabled = false; return false; }
  }

  async function triggerFocus() {
    if (!cameraTrack) return;
    try {
      const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
      if (caps.focusMode && caps.focusMode.includes('single-shot')) {
        await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'single-shot' }] });
        setTimeout(async () => {
          try {
            if (caps.focusMode.includes('continuous'))
              await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
          } catch (e) {}
        }, 1500);
      }
    } catch (e) {}
  }

  // ============================================
  // INTERNAL
  // ============================================
  function _killStream() {
    if (videoStream) {
      videoStream.getTracks().forEach(t => t.stop());
      videoStream = null;
    }
    cameraTrack = null;
    imageCapture = null;
    torchEnabled = false;
  }

  async function _applyAutofocus() {
    if (!cameraTrack) return;
    try {
      const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
      if (caps.focusMode && caps.focusMode.includes('continuous'))
        await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
      else if (caps.focusMode && caps.focusMode.includes('single-shot'))
        await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'single-shot' }] });
    } catch (e) {}
  }

  function _setupImageCapture() {
    try {
      if ('ImageCapture' in window && cameraTrack)
        imageCapture = new ImageCapture(cameraTrack);
    } catch (e) { imageCapture = null; }
  }

  async function _attachToVideo(videoElement) {
    videoElement.srcObject = videoStream;
    await new Promise((resolve, reject) => {
      videoElement.onloadedmetadata = () => videoElement.play().then(resolve).catch(reject);
      videoElement.onerror = reject;
    });
  }

  function _hasTorch() {
    if (!cameraTrack) return false;
    try {
      const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
      return !!caps.torch;
    } catch (e) { return false; }
  }

  function _getInfo() {
    return {
      hasMultipleCameras: backCameraIds.length > 1,
      hasTorch: _hasTorch(),
      cameraIndex: currentIndexAmongBack,
      totalCameras: backCameraIds.length
    };
  }

  async function _enumerateBackCameras() {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoCams = devices.filter(d => d.kind === 'videoinput');
      backCameraIds = [];
      videoCams.forEach(cam => {
        const label = (cam.label || '').toLowerCase();
        const isFront = label.includes('front') || label.includes('user') ||
                        label.includes('selfie') || label.includes('facetime');
        if (!isFront) backCameraIds.push(cam.deviceId);
      });
      currentIndexAmongBack = backCameraIds.indexOf(currentDeviceId);
      if (currentIndexAmongBack < 0) currentIndexAmongBack = 0;
    } catch (e) {}
  }

  // Cleanup on page unload
  if (typeof window !== 'undefined') {
    window.addEventListener('beforeunload', () => destroy());
  }

  return {
    open, openForCapture, grabPhoto, cycle,
    stop, destroy, detach,
    toggleTorch, triggerFocus,
    getTrack, getStream, getImageCapture, isTorchOn, isActive
  };
})();
