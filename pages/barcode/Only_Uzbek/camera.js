// camera.js — Camera management module (persistent stream)
// Exposes: window.Camera
// ============================================
// getUserMedia called once if default has torch, twice if not.
// Stream persists across scanner/wizard views.
// Caches torch camera label in sessionStorage so revisits
// probe the correct camera first (minimizes wasted prompts).
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

  // --- SessionStorage helpers ---
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
      await _attachToVideo(videoElement);
      return _getInfo();
    }

    const savedLabel = _getSavedTorchLabel();

    // ── Step 1: Get environment camera (1 permission prompt) ──
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

    // ── Step 2: Check torch on default camera ──
    let caps = {};
    try { caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {}; } catch (e) {}

    if (caps.torch) {
      // Default camera has torch — save label and done
      const devices = await navigator.mediaDevices.enumerateDevices();
      const thisCam = devices.find(d => d.deviceId === currentDeviceId);
      _saveTorchLabel(thisCam ? thisCam.label : '');
      await _finalize(videoElement);
      return _getInfo();
    }

    // ── Step 3: Default lacks torch — find one that has it ──
    const devices = await navigator.mediaDevices.enumerateDevices();
    const videoCams = devices.filter(d => d.kind === 'videoinput');

    const backCams = videoCams.filter(cam => {
      const label = (cam.label || '').toLowerCase();
      return !(label.includes('front') || label.includes('user') ||
               label.includes('selfie') || label.includes('facetime'));
    });

    let candidates = backCams.filter(cam => cam.deviceId !== currentDeviceId);

    // Prioritize cached label (probe correct camera first on revisit)
    if (savedLabel) {
      const cachedIdx = candidates.findIndex(c => c.label === savedLabel);
      if (cachedIdx >= 0) {
        const cached = candidates.splice(cachedIdx, 1)[0];
        candidates.unshift(cached);
      }
    }

    if (candidates.length > 0) {
      // Stop current stream — Android can't run two back cameras simultaneously
      const fallbackDeviceId = currentDeviceId;
      videoStream.getTracks().forEach(t => t.stop());
      videoStream = null;
      cameraTrack = null;

      let found = false;
      for (const cam of candidates) {
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

          if (testCaps.torch) {
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
          continue;
        }
      }

      if (!found) {
        // No torch camera — reopen original
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
  }

  // ============================================
  // ATTACH TO CAPTURE VIDEO
  // ============================================
  async function openForCapture(videoElement) {
    if (isActive()) {
      await _attachToVideo(videoElement);
      return;
    }
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
    canvas.getContext('2d').drawImage(videoElement, 0, 0);
    return new Promise(resolve => canvas.toBlob(blob => resolve(blob), 'image/jpeg', 0.85));
  }

  // ============================================
  // CYCLE
  // ============================================
  async function cycle(videoElement) {
    if (backCameraIds.length <= 1) return null;
    _killStream();

    currentIndexAmongBack = (currentIndexAmongBack + 1) % backCameraIds.length;
    const nextId = backCameraIds[currentIndexAmongBack];

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
    if (videoElement) { videoElement.pause(); videoElement.srcObject = null; }
  }

  async function stop() {
    if (torchEnabled && cameraTrack) {
      try { await cameraTrack.applyConstraints({ advanced: [{ torch: false }] }); } catch (e) {}
    }
    torchEnabled = false;
  }

  function destroy() { _killStream(); _initialized = false; }

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
