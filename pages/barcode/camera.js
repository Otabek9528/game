// camera.js — Camera management module
// Handles: open, torch, focus, cycle, stop
// Exposes: window.Camera
// ============================================

window.Camera = (() => {

  let videoStream = null;
  let cameraTrack = null;
  let imageCapture = null;
  let torchEnabled = false;
  let backCameraIds = [];
  let currentDeviceId = null;
  let currentIndexAmongBack = 0;

  // --- Getters ---
  function getTrack()        { return cameraTrack; }
  function getStream()       { return videoStream; }
  function getImageCapture() { return imageCapture; }
  function isTorchOn()       { return torchEnabled; }

  // --- Open camera (reverse enumeration) ---
  async function open(videoElement) {
    if (videoStream) stop();

    const devices = await navigator.mediaDevices.enumerateDevices();
    const videoCams = devices.filter(d => d.kind === 'videoinput');

    if (videoCams.length === 0) throw new Error('NO_CAMERA');

    let foundCamera = false;

    for (let i = videoCams.length - 1; i >= 0; i--) {
      try {
        videoStream = await navigator.mediaDevices.getUserMedia({
          video: { deviceId: { exact: videoCams[i].deviceId }, width: { ideal: 1920 }, height: { ideal: 1080 } },
          audio: false
        });
        cameraTrack = videoStream.getVideoTracks()[0];
        currentDeviceId = cameraTrack.getSettings().deviceId;

        const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
        if (caps.torch) { foundCamera = true; break; }

        const settings = cameraTrack.getSettings();
        if (settings.facingMode === 'user') {
          videoStream.getTracks().forEach(t => t.stop());
          videoStream = null; cameraTrack = null;
          continue;
        }

        videoStream.getTracks().forEach(t => t.stop());
        videoStream = null; cameraTrack = null;
      } catch (e) { continue; }
    }

    if (!foundCamera || !videoStream) {
      videoStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: 'environment' }, width: { ideal: 1920 }, height: { ideal: 1080 } },
        audio: false
      });
      cameraTrack = videoStream.getVideoTracks()[0];
      currentDeviceId = cameraTrack.getSettings().deviceId;
    }

    await _applyAutofocus();
    _setupImageCapture();
    await _attachToVideo(videoElement);
    await _enumerateBackCameras();

    return {
      hasMultipleCameras: backCameraIds.length > 1,
      hasTorch: _hasTorch(),
      cameraIndex: currentIndexAmongBack,
      totalCameras: backCameraIds.length
    };
  }

  // --- Open camera for capture (reuses known device to avoid re-prompting) ---
  async function openForCapture(videoElement) {
    if (videoStream) stop();

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

  // --- Grab frame as blob (for photo capture) ---
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

  // --- Cycle camera ---
  async function cycle(videoElement) {
    if (backCameraIds.length <= 1) return null;
    stop();

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

    return {
      hasTorch: _hasTorch(),
      cameraIndex: currentIndexAmongBack,
      totalCameras: backCameraIds.length
    };
  }

  // --- Stop ---
  function stop() {
    if (videoStream) {
      videoStream.getTracks().forEach(t => t.stop());
      videoStream = null;
    }
    cameraTrack = null;
    imageCapture = null;
    torchEnabled = false;
  }

  // --- Torch ---
  async function toggleTorch() {
    if (!cameraTrack) return false;
    torchEnabled = !torchEnabled;
    try {
      await cameraTrack.applyConstraints({ advanced: [{ torch: torchEnabled }] });
      return torchEnabled;
    } catch (e) { torchEnabled = false; return false; }
  }

  // --- Focus ---
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

  // --- Internal ---
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

  return {
    open, openForCapture, grabPhoto, cycle, stop,
    toggleTorch, triggerFocus,
    getTrack, getStream, getImageCapture, isTorchOn
  };
})();
