// camera.js — Camera management module (persistent stream)
// Exposes: window.Camera
// ============================================
// STRATEGY:
// On revisit with cached label:
//   1. Try enumerateDevices() BEFORE getUserMedia — if labels
//      are available (permission persisted), find cached camera
//      and open it directly → 1 prompt only!
//   2. If labels are empty → fall back to normal 2-prompt flow
// On first visit (no cache):
//   1. getUserMedia(environment) → check torch → if yes, done
//   2. If no torch → stop, probe others → cache label
// ============================================

window.Camera = (() => {

  const STORAGE_KEY = 'camera_torch_label';

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

  function _saveTorchLabel(label) {
    try { if (label) sessionStorage.setItem(STORAGE_KEY, label); } catch (e) {}
  }
  function _getSavedTorchLabel() {
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

    const savedLabel = _getSavedTorchLabel();
    _dbg(savedLabel ? 'Cached label: "' + savedLabel + '"' : 'No cached label');

    // ── Fast path: try to use cache with pre-enumeration ──
    if (savedLabel) {
      _dbg('Attempting fast path (enumerate before getUserMedia)...');
      try {
        const preDevices = await navigator.mediaDevices.enumerateDevices();
        const preVideoCams = preDevices.filter(d => d.kind === 'videoinput');
        const labelsAvailable = preVideoCams.some(d => d.label && d.label.length > 0);
        _dbg('Labels available pre-permission: ' + labelsAvailable);

        if (labelsAvailable) {
          // Labels are populated — permission context persists!
          const target = preVideoCams.find(d => d.label === savedLabel);
          if (target) {
            _dbg('Fast path: found "' + savedLabel + '" → opening directly...');
            videoStream = await navigator.mediaDevices.getUserMedia({
              video: {
                deviceId: { exact: target.deviceId },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
              },
              audio: false
            });
            cameraTrack = videoStream.getVideoTracks()[0];
            currentDeviceId = cameraTrack.getSettings().deviceId;

            let caps = {};
            try { caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {}; } catch (e) {}

            if (caps.torch) {
              _dbg('✅ Fast path SUCCESS — 1 prompt only!');
              await _finalize(videoElement);
              return _getInfo();
            } else {
              _dbg('⚠ Fast path camera lost torch — falling through');
              videoStream.getTracks().forEach(t => t.stop());
              videoStream = null;
              cameraTrack = null;
              try { sessionStorage.removeItem(STORAGE_KEY); } catch (e) {}
            }
          } else {
            _dbg('Fast path: cached label not found in device list');
          }
        } else {
          _dbg('No labels pre-permission — fast path unavailable');
        }
      } catch (e) {
        _dbg('Fast path error: ' + e.message);
      }
    }

    // ── Normal path: getUserMedia(environment) first ──
    _dbg('Normal path: getUserMedia(environment)...');
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
    _dbg('Got: ' + (settings.width || '?') + 'x' + (settings.height || '?'));

    // Check torch
    let caps = {};
    try { caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {}; } catch (e) {}
    const hasTorch = !!caps.torch;
    _dbg('Torch: ' + hasTorch);

    if (hasTorch) {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const thisCam = devices.find(d => d.deviceId === currentDeviceId);
      _dbg('✅ Default has torch');
      _saveTorchLabel(thisCam ? thisCam.label : '');
      await _finalize(videoElement);
      return _getInfo();
    }

    // ── Probe other back cameras ──
    _dbg('⚠ No torch — enumerating...');
    const devices = await navigator.mediaDevices.enumerateDevices();
    const videoCams = devices.filter(d => d.kind === 'videoinput');

    videoCams.forEach((cam, i) => {
      const cur = cam.deviceId === currentDeviceId ? ' ← CURRENT' : '';
      _dbg('  [' + i + '] "' + (cam.label || 'no label') + '"' + cur);
    });

    const backCams = videoCams.filter(cam => {
      const label = (cam.label || '').toLowerCase();
      return !(label.includes('front') || label.includes('user') ||
               label.includes('selfie') || label.includes('facetime'));
    });

    let candidates = backCams.filter(cam => cam.deviceId !== currentDeviceId);

    // Prioritize cached label
    if (savedLabel) {
      const cachedIdx = candidates.findIndex(c => c.label === savedLabel);
      if (cachedIdx >= 0) {
        _dbg('Cache match — trying "' + savedLabel + '" first');
        const cached = candidates.splice(cachedIdx, 1)[0];
        candidates.unshift(cached);
      }
    }

    _dbg('Candidates: ' + candidates.length);

    if (candidates.length > 0) {
      const fallbackDeviceId = currentDeviceId;
      _dbg('Stopping current stream...');
      videoStream.getTracks().forEach(t => t.stop());
      videoStream = null;
      cameraTrack = null;

      let found = false;
      for (const cam of candidates) {
        _dbg('Probing: "' + (cam.label || '?') + '"...');
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

          const testTorch = !!testCaps.torch;
          const ts = testTrack.getSettings();
          _dbg('  → ' + (ts.width || '?') + 'x' + (ts.height || '?') + ' torch=' + testTorch);

          if (testTorch) {
            _dbg('✅ Found torch camera!');
            videoStream = testStream;
            cameraTrack = testTrack;
            currentDeviceId = testTrack.getSettings().deviceId;
            _saveTorchLabel(cam.label || '');
            found = true;
            break;
          } else {
            testStream.getTracks().forEach(t => t.stop());
          }
        } catch (e) {
          _dbg('  ✗ Failed: ' + e.message);
          continue;
        }
      }

      if (!found) {
        _dbg('ℹ Reopening original...');
        try {
          videoStream = await navigator.mediaDevices.getUserMedia({
            video: { deviceId: { exact: fallbackDeviceId }, width: { ideal: 1920 }, height: { ideal: 1080 } },
            audio: false
          });
        } catch (e) {
          videoStream = await navigator.mediaDevices.getUserMedia({
            video: { facingMode: { ideal: 'environment' }, width: { ideal: 1920 }, height: { ideal: 1080 } },
            audio: false
          });
        }
        cameraTrack = videoStream.getVideoTracks()[0];
        currentDeviceId = cameraTrack.getSettings().deviceId;
      }
    }

    await _finalize(videoElement);
    return _getInfo();
  }

  async function _finalize(videoElement) {
    await _applyAutofocus();
    _setupImageCapture();
    await _attachToVideo(videoElement);
    await _enumerateBackCameras();
    _initialized = true;
    const info = _getInfo();
    _dbg('READY: torch=' + info.hasTorch + ' cams=' + info.totalCameras + ' idx=' + info.cameraIndex);
  }

  // ============================================
  // REST OF MODULE (unchanged)
  // ============================================
  async function openForCapture(videoElement) {
    if (isActive()) { await _attachToVideo(videoElement); return; }
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

  async function grabPhoto(videoElement) {
    const canvas = document.createElement('canvas');
    canvas.width = videoElement.videoWidth;
    canvas.height = videoElement.videoHeight;
    canvas.getContext('2d').drawImage(videoElement, 0, 0);
    return new Promise(resolve => canvas.toBlob(blob => resolve(blob), 'image/jpeg', 0.85));
  }

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

  function detach(videoElement) {
    if (videoElement) { videoElement.pause(); videoElement.srcObject = null; }
  }

  async function stop() {
    if (torchEnabled && cameraTrack) {
      try { await cameraTrack.applyConstraints({ advanced: [{ torch: false }] }); } catch (e) {}
    }
    torchEnabled = false;
  }

  function destroy() { _killStream(); _initialized = false; }

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

  function _killStream() {
    if (videoStream) { videoStream.getTracks().forEach(t => t.stop()); videoStream = null; }
    cameraTrack = null; imageCapture = null; torchEnabled = false;
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
      if ('ImageCapture' in window && cameraTrack) imageCapture = new ImageCapture(cameraTrack);
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
    try { return !!(cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {}).torch; }
    catch (e) { return false; }
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
