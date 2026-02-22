// camera.js — Camera management module (persistent stream)
// Exposes: window.Camera
// ============================================
// STRATEGY:
// 1. Check sessionStorage for a previously-found torch camera deviceId
//    → If found, open it directly (0 probing, likely 0 extra prompts)
// 2. Otherwise: get environment camera (1 prompt)
// 3. If it has torch → done, cache deviceId
// 4. If not → stop stream, probe other back cameras
// 5. Cache whichever torch camera we find for next time
// ============================================

window.Camera = (() => {

  const STORAGE_KEY = 'camera_torch_deviceId';

  let videoStream = null;
  let cameraTrack = null;
  let imageCapture = null;
  let torchEnabled = false;
  let backCameraIds = [];
  let currentDeviceId = null;
  let currentIndexAmongBack = 0;
  let _initialized = false;

  // ============================================
  // DEBUG OVERLAY (set false for production)
  // ============================================
  let _debugEl = null;
  let _debugLines = [];
  const DEBUG_ENABLED = true;

  function _dbg(msg) {
    const line = '[Cam] ' + msg;
    console.log(line);
    if (!DEBUG_ENABLED) return;
    _debugLines.push(line);
    if (_debugLines.length > 35) _debugLines.shift();
    if (!_debugEl) {
      _debugEl = document.createElement('div');
      _debugEl.id = 'camera-debug-overlay';
      Object.assign(_debugEl.style, {
        position: 'fixed', bottom: '0', left: '0', right: '0',
        maxHeight: '40vh', overflow: 'auto', zIndex: '99999',
        background: 'rgba(0,0,0,0.85)', color: '#0f0',
        fontSize: '11px', fontFamily: 'monospace',
        padding: '6px', lineHeight: '1.4',
        pointerEvents: 'auto', whiteSpace: 'pre-wrap'
      });
      _debugEl.addEventListener('click', () => {
        _debugEl.style.display = _debugEl.style.display === 'none' ? 'block' : 'none';
      });
      document.body.appendChild(_debugEl);
    }
    _debugEl.textContent = _debugLines.join('\n');
    _debugEl.scrollTop = _debugEl.scrollHeight;
  }

  // --- SessionStorage helpers ---
  function _saveTorchDeviceId(deviceId) {
    try { sessionStorage.setItem(STORAGE_KEY, deviceId); } catch (e) {}
  }
  function _getSavedTorchDeviceId() {
    try { return sessionStorage.getItem(STORAGE_KEY); } catch (e) { return null; }
  }

  // --- Getters ---
  function getTrack()        { return cameraTrack; }
  function getStream()       { return videoStream; }
  function getImageCapture() { return imageCapture; }
  function isTorchOn()       { return torchEnabled; }
  function isActive()        { return !!videoStream && cameraTrack && cameraTrack.readyState === 'live'; }

  // ============================================
  // OPEN — acquires stream, finds main camera
  // ============================================
  async function open(videoElement) {
    if (isActive()) {
      _dbg('Already active — reattaching');
      await _attachToVideo(videoElement);
      return _getInfo();
    }

    // ── Check cache: do we already know the right camera? ──
    const savedId = _getSavedTorchDeviceId();
    if (savedId) {
      _dbg('Cache hit! Trying saved deviceId=' + savedId.substring(0, 8) + '…');
      try {
        videoStream = await navigator.mediaDevices.getUserMedia({
          video: {
            deviceId: { exact: savedId },
            width: { ideal: 1920 },
            height: { ideal: 1080 }
          },
          audio: false
        });
        cameraTrack = videoStream.getVideoTracks()[0];
        currentDeviceId = cameraTrack.getSettings().deviceId;

        // Verify it still has torch (camera config can change on some devices)
        let caps = {};
        try { caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {}; } catch (e) {}

        if (caps.torch) {
          _dbg('✅ Cached camera confirmed — torch=true');
          await _finalize(videoElement);
          return _getInfo();
        } else {
          _dbg('⚠ Cached camera lost torch — falling through to discovery');
          videoStream.getTracks().forEach(t => t.stop());
          videoStream = null;
          cameraTrack = null;
          // Clear stale cache
          try { sessionStorage.removeItem(STORAGE_KEY); } catch (e) {}
        }
      } catch (e) {
        _dbg('⚠ Cached camera failed: ' + e.message + ' — falling through');
        // Clear stale cache
        try { sessionStorage.removeItem(STORAGE_KEY); } catch (e2) {}
      }
    } else {
      _dbg('No cached deviceId');
    }

    // ── Step 1: Get environment camera (1 permission prompt) ──
    _dbg('Step 1: getUserMedia(environment)...');
    try {
      videoStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: { ideal: 'environment' },
          width: { ideal: 1920 },
          height: { ideal: 1080 }
        },
        audio: false
      });
    } catch (e) {
      _dbg('❌ Permission denied: ' + e.message);
      throw e;
    }
    cameraTrack = videoStream.getVideoTracks()[0];
    currentDeviceId = cameraTrack.getSettings().deviceId;

    const settings = cameraTrack.getSettings();
    _dbg('Got: ' + (settings.width || '?') + 'x' + (settings.height || '?') +
         ' id=' + currentDeviceId.substring(0, 8) + '…');

    // ── Step 2: Check capabilities ──
    let caps = {};
    try {
      caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    } catch (e) {
      _dbg('getCapabilities() failed: ' + e.message);
    }

    const hasTorch = !!caps.torch;
    _dbg('Torch: ' + hasTorch + ' | FacingMode: ' + (settings.facingMode || 'unknown'));

    if (hasTorch) {
      _dbg('✅ Default camera has torch — DONE');
      _saveTorchDeviceId(currentDeviceId);
    } else {
      // ── Step 3: Default lacks torch — search others ──
      _dbg('⚠ No torch — enumerating cameras...');

      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoCams = devices.filter(d => d.kind === 'videoinput');

      _dbg('Total video devices: ' + videoCams.length);
      videoCams.forEach((cam, i) => {
        const cur = cam.deviceId === currentDeviceId ? ' ← CURRENT' : '';
        _dbg('  [' + i + '] "' + (cam.label || 'no label') + '"' + cur);
      });

      const backCams = videoCams.filter(cam => {
        const label = (cam.label || '').toLowerCase();
        return !(label.includes('front') || label.includes('user') ||
                 label.includes('selfie') || label.includes('facetime'));
      });

      const candidates = backCams.filter(cam => cam.deviceId !== currentDeviceId);
      _dbg('Back cameras: ' + backCams.length + ', candidates: ' + candidates.length);

      if (candidates.length > 0) {
        // ★ Stop current stream before probing (Android can't run 2 back cameras)
        const fallbackDeviceId = currentDeviceId;
        _dbg('Stopping current stream before probing...');
        videoStream.getTracks().forEach(t => t.stop());
        videoStream = null;
        cameraTrack = null;

        let found = false;
        for (const cam of candidates) {
          _dbg('Probing: "' + (cam.label || cam.deviceId.substring(0, 8)) + '"...');
          try {
            const testStream = await navigator.mediaDevices.getUserMedia({
              video: {
                deviceId: { exact: cam.deviceId },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
              },
              audio: false
            });
            const testTrack = testStream.getVideoTracks()[0];

            let testCaps = {};
            try { testCaps = testTrack.getCapabilities ? testTrack.getCapabilities() : {}; } catch (e) {}

            const testSettings = testTrack.getSettings();
            const testTorch = !!testCaps.torch;
            _dbg('  → ' + (testSettings.width || '?') + 'x' + (testSettings.height || '?') +
                 ' torch=' + testTorch);

            if (testTorch) {
              _dbg('✅ Found torch camera! Using it.');
              videoStream = testStream;
              cameraTrack = testTrack;
              currentDeviceId = testTrack.getSettings().deviceId;
              _saveTorchDeviceId(currentDeviceId);
              found = true;
              break;
            } else {
              _dbg('  ✗ No torch — stopping');
              testStream.getTracks().forEach(t => t.stop());
            }
          } catch (e) {
            _dbg('  ✗ Failed: ' + e.message);
            continue;
          }
        }

        if (!found) {
          _dbg('ℹ No torch camera — reopening original...');
          try {
            videoStream = await navigator.mediaDevices.getUserMedia({
              video: {
                deviceId: { exact: fallbackDeviceId },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
              },
              audio: false
            });
            cameraTrack = videoStream.getVideoTracks()[0];
            currentDeviceId = fallbackDeviceId;
          } catch (e) {
            _dbg('❌ Reopen failed — generic fallback');
            videoStream = await navigator.mediaDevices.getUserMedia({
              video: { facingMode: { ideal: 'environment' }, width: { ideal: 1920 }, height: { ideal: 1080 } },
              audio: false
            });
            cameraTrack = videoStream.getVideoTracks()[0];
            currentDeviceId = cameraTrack.getSettings().deviceId;
          }
        }
      } else {
        _dbg('ℹ No other back cameras to try');
      }
    }

    // ── Finalize ──
    await _finalize(videoElement);
    return _getInfo();
  }

  // ── Shared finalization ──
  async function _finalize(videoElement) {
    await _applyAutofocus();
    _setupImageCapture();
    await _attachToVideo(videoElement);
    await _enumerateBackCameras();
    _initialized = true;

    const info = _getInfo();
    _dbg('READY: torch=' + info.hasTorch +
         ' cams=' + info.totalCameras +
         ' idx=' + info.cameraIndex);
  }

  // ============================================
  // ATTACH TO CAPTURE VIDEO — reuses existing stream
  // ============================================
  async function openForCapture(videoElement) {
    if (isActive()) {
      await _attachToVideo(videoElement);
      return;
    }
    _dbg('Stream lost — re-acquiring...');
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
  // GRAB PHOTO
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
  // CYCLE — switch to next back camera (user-initiated)
  // ============================================
  async function cycle(videoElement) {
    if (backCameraIds.length <= 1) return null;

    _killStream();

    currentIndexAmongBack = (currentIndexAmongBack + 1) % backCameraIds.length;
    const nextId = backCameraIds[currentIndexAmongBack];
    _dbg('Cycling to index ' + currentIndexAmongBack);

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
  // DETACH / STOP / DESTROY
  // ============================================
  function detach(videoElement) {
    if (videoElement) {
      videoElement.pause();
      videoElement.srcObject = null;
    }
  }

  async function stop() {
    if (torchEnabled && cameraTrack) {
      try {
        await cameraTrack.applyConstraints({ advanced: [{ torch: false }] });
      } catch (e) {}
    }
    torchEnabled = false;
  }

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
