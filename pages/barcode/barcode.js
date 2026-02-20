// barcode.js - Barcode Scanner for Telegram WebApp
// VERSION 12: Try cameras from last to first
//
// enumerateDevices() returns deviceIds without permission (no labels though).
// We try cameras starting from the LAST one (main camera on most phones)
// and stop as soon as we find one with torch capability.
//
// Best case: 1 prompt (last camera is the main one)
// Worst case: N prompts until we find torch (but typically 1-2)
// ============================================

const SCAN_INTERVAL = 200;
const STABLE_COUNT_NEEDED = 3;
const STABLE_TIMEOUT = 2000;
const HISTORY_MAX_ITEMS = 10;
const HISTORY_STORAGE_KEY = 'barcode_scan_history';

const FORMAT_NAMES = {
  'ean_13': 'EAN-13', 'ean_8': 'EAN-8', 'upc_a': 'UPC-A', 'upc_e': 'UPC-E',
  'code_128': 'Code 128', 'code_39': 'Code 39', 'code_93': 'Code 93',
  'codabar': 'Codabar', 'itf': 'ITF', 'qr_code': 'QR Code',
  'data_matrix': 'Data Matrix', 'unknown': 'Noma\'lum'
};

// ============================================
// STATE
// ============================================

let videoStream = null;
let videoElement = null;
let isScanning = false;
let scanInterval = null;
let torchEnabled = false;
let lastScannedCode = null;
let barcodeDetector = null;
let scanHistory = [];
let cameraTrack = null;
let imageCapture = null;

let backCameraIds = [];
let currentDeviceId = null;
let currentIndexAmongBack = 0;

let pendingCode = null;
let pendingFormat = null;
let pendingCount = 0;
let pendingLastSeen = 0;

// ============================================
// TELEGRAM
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();
Telegram.WebApp.disableVerticalSwipes();
try { tg.expand(); } catch (e) {}
try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => { stopScanning(); stopCamera(); window.location.href = "../../index.html"; });
  }
} catch (e) {}

// ============================================
// DOM
// ============================================

const loadingState = document.getElementById('loadingState');
const permissionState = document.getElementById('permissionState');
const errorState = document.getElementById('errorState');
const scannerDisplay = document.getElementById('scannerDisplay');
const requestPermissionBtn = document.getElementById('requestPermissionBtn');
const retryBtn = document.getElementById('retryBtn');
const cameraContainer = document.getElementById('cameraContainer');
const restartCameraBtn = document.getElementById('restartCameraBtn');
const switchCameraBtn = document.getElementById('switchCameraBtn');
const torchBtn = document.getElementById('torchBtn');
const torchIcon = document.getElementById('torchIcon');
const focusIndicator = document.getElementById('focusIndicator');
const statusIndicator = document.getElementById('statusIndicator');
const statusText = document.getElementById('statusText');
const resultSection = document.getElementById('resultSection');
const barcodeType = document.getElementById('barcodeType');
const barcodeNumber = document.getElementById('barcodeNumber');
const copyBtn = document.getElementById('copyBtn');
const scanAgainBtn = document.getElementById('scanAgainBtn');
const historySection = document.getElementById('historySection');
const historyList = document.getElementById('historyList');
const clearHistoryBtn = document.getElementById('clearHistoryBtn');
const errorMessage = document.getElementById('errorMessage');

// ============================================
// UI
// ============================================

function showState(state) {
  loadingState.style.display = 'none';
  permissionState.style.display = 'none';
  errorState.style.display = 'none';
  scannerDisplay.style.display = 'none';
  switch (state) {
    case 'loading': loadingState.style.display = 'flex'; break;
    case 'permission': permissionState.style.display = 'flex'; break;
    case 'error': errorState.style.display = 'flex'; break;
    case 'scanner': scannerDisplay.style.display = 'block'; break;
  }
}

function showError(msg) { errorMessage.textContent = msg; showState('error'); }

function updateStatus(text, type = 'scanning') {
  statusText.textContent = text;
  statusIndicator.className = `status-indicator ${type}`;
}

// ============================================
// CAMERA
// ============================================

/**
 * Main entry. Enumerates cameras first (no prompt), then tries from
 * last to first looking for torch. Stops at the first good camera.
 */
async function openCamera() {
  showState('loading');

  try {
    if (videoStream) stopCamera();
    videoElement = document.getElementById('videoElement');

    // Step 1: enumerate deviceIds (no permission prompt, no labels)
    const devices = await navigator.mediaDevices.enumerateDevices();
    const videoCams = devices.filter(d => d.kind === 'videoinput');

    if (videoCams.length === 0) {
      showError('Kamera topilmadi.');
      return false;
    }

    // Step 2: try cameras from LAST to FIRST
    // On most phones: back cameras are listed first, front cameras last.
    // But the MAIN back camera (with torch/autofocus) is often the last
    // among the back cameras, or we try reverse order to find it fast.
    //
    // Since we have no labels yet, we try ALL cameras in reverse.
    // As soon as we find one with torch → stop.

    let foundCamera = false;

    for (let i = videoCams.length - 1; i >= 0; i--) {
      const cam = videoCams[i];

      try {
        videoStream = await navigator.mediaDevices.getUserMedia({
          video: {
            deviceId: { exact: cam.deviceId },
            width: { ideal: 1920 },
            height: { ideal: 1080 }
          },
          audio: false
        });

        cameraTrack = videoStream.getVideoTracks()[0];
        currentDeviceId = cameraTrack.getSettings().deviceId;

        const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};

        if (caps.torch) {
          // Found the main camera with torch — use it!
          foundCamera = true;
          break;
        }

        // No torch — check if it's at least a back camera (environment)
        const settings = cameraTrack.getSettings();
        if (settings.facingMode === 'user') {
          // Front camera — skip
          videoStream.getTracks().forEach(t => t.stop());
          videoStream = null;
          cameraTrack = null;
          continue;
        }

        // Back camera but no torch — remember it as fallback but keep looking
        if (!foundCamera) {
          // Keep this stream as fallback, but try more
          // Actually stop it and continue — we want the torch one
          videoStream.getTracks().forEach(t => t.stop());
          videoStream = null;
          cameraTrack = null;
          continue;
        }

      } catch (e) {
        // Permission denied or camera error — skip this one
        continue;
      }
    }

    // If we didn't find a torch camera, just use facingMode as last resort
    if (!foundCamera || !videoStream) {
      try {
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
      } catch (e) {
        handleCameraError(e);
        return false;
      }
    }

    await finishCameraSetup();
    return true;

  } catch (error) {
    handleCameraError(error);
    return false;
  }
}

async function finishCameraSetup() {
  await applyContinuousAutofocus();

  try {
    if ('ImageCapture' in window && cameraTrack) imageCapture = new ImageCapture(cameraTrack);
  } catch (e) { imageCapture = null; }

  videoElement.srcObject = videoStream;
  await new Promise((resolve, reject) => {
    videoElement.onloadedmetadata = () => videoElement.play().then(resolve).catch(reject);
    videoElement.onerror = reject;
  });

  enumerateBackCamerasQuietly();
  updateCameraInfo();
  checkTorchSupport();
  showState('scanner');
  startScanning();
}

async function enumerateBackCamerasQuietly() {
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
    switchCameraBtn.style.display = backCameraIds.length > 1 ? 'flex' : 'none';
    updateCameraInfo();
  } catch (e) {}
}

async function applyContinuousAutofocus() {
  if (!cameraTrack) return;
  try {
    const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    if (caps.focusMode && caps.focusMode.includes('continuous')) {
      await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
    } else if (caps.focusMode && caps.focusMode.includes('single-shot')) {
      await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'single-shot' }] });
    }
  } catch (e) {}
}

function handleCameraError(error) {
  if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
    showState('permission');
  } else if (error.name === 'NotFoundError') {
    showError('Kamera topilmadi.');
  } else if (error.name === 'NotReadableError') {
    showError('Kamera band. Boshqa ilovalarni yoping.');
  } else {
    showError(`Kamera xatoligi: ${error.message}`);
  }
}

function updateCameraInfo() {
  const infoEl = document.getElementById('cameraInfoBadge');
  if (infoEl && backCameraIds.length > 1) {
    infoEl.textContent = `📷 ${currentIndexAmongBack + 1}/${backCameraIds.length}`;
    infoEl.style.display = 'inline-block';
  } else if (infoEl) {
    infoEl.style.display = 'none';
  }
}

async function triggerFocus() {
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
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

function stopCamera() {
  if (videoStream) { videoStream.getTracks().forEach(t => t.stop()); videoStream = null; }
  if (videoElement) videoElement.srcObject = null;
  cameraTrack = null;
  imageCapture = null;
}

async function cycleCamera() {
  if (backCameraIds.length <= 1) return;
  stopScanning();
  stopCamera();
  currentIndexAmongBack = (currentIndexAmongBack + 1) % backCameraIds.length;
  const nextId = backCameraIds[currentIndexAmongBack];
  showState('loading');
  try {
    videoElement = document.getElementById('videoElement');
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: { deviceId: { exact: nextId }, width: { ideal: 1920 }, height: { ideal: 1080 } },
      audio: false
    });
    cameraTrack = videoStream.getVideoTracks()[0];
    currentDeviceId = nextId;
    await finishCameraSetup();
  } catch (e) {
    showError('Kamerani almashtirib bo\'lmadi.');
  }
}

function checkTorchSupport() {
  if (!cameraTrack) { torchBtn.style.display = 'none'; return; }
  try {
    const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    torchBtn.style.display = caps.torch ? 'flex' : 'none';
  } catch (e) { torchBtn.style.display = 'none'; }
}

async function toggleTorch() {
  if (!cameraTrack) return;
  torchEnabled = !torchEnabled;
  try {
    await cameraTrack.applyConstraints({ advanced: [{ torch: torchEnabled }] });
    torchBtn.classList.toggle('active', torchEnabled);
    torchIcon.textContent = torchEnabled ? '💡' : '🔦';
  } catch (e) { torchEnabled = false; }
}

// ============================================
// BARCODE DETECTION
// ============================================

async function initBarcodeDetector() {
  if ('BarcodeDetector' in window) {
    try {
      const formats = await BarcodeDetector.getSupportedFormats();
      barcodeDetector = new BarcodeDetector({ formats });
      return true;
    } catch (e) {}
  }
  return false;
}

function startScanning() {
  if (isScanning) return;
  isScanning = true;
  resetPending();
  updateStatus('Qidirilmoqda...', 'scanning');
  scanInterval = setInterval(scanFrame, SCAN_INTERVAL);
}

function stopScanning() {
  isScanning = false;
  if (scanInterval) { clearInterval(scanInterval); scanInterval = null; }
  resetPending();
}

function resetPending() {
  pendingCode = null; pendingFormat = null; pendingCount = 0; pendingLastSeen = 0;
}

function processDetection(code, format) {
  const now = Date.now();
  if (code !== pendingCode) {
    pendingCode = code; pendingFormat = format; pendingCount = 1; pendingLastSeen = now;
    return false;
  }
  if (now - pendingLastSeen > STABLE_TIMEOUT) {
    pendingCount = 1; pendingLastSeen = now; return false;
  }
  pendingCount++; pendingLastSeen = now; pendingFormat = format;
  return pendingCount >= STABLE_COUNT_NEEDED;
}

async function scanFrame() {
  if (!isScanning || !videoElement || videoElement.readyState !== 4) return;
  try {
    let barcodes = [];
    if (barcodeDetector) barcodes = await barcodeDetector.detect(videoElement);
    if (barcodes.length === 0 && imageCapture) {
      try {
        const frame = await imageCapture.grabFrame();
        if (frame && barcodeDetector) { barcodes = await barcodeDetector.detect(frame); frame.close(); }
      } catch (e) {}
    }
    if (barcodes.length > 0) {
      const b = barcodes[0];
      const code = b.rawValue || b.data;
      const format = b.format || 'unknown';
      if (code === lastScannedCode) return;
      if (processDetection(code, format)) handleBarcodeConfirmed(code, format);
    }
  } catch (e) {}
}

function handleBarcodeConfirmed(code, format) {
  lastScannedCode = code;
  if (navigator.vibrate) navigator.vibrate([100, 50, 100]);
  playSuccessSound();
  displayResult(code, format);
  addToHistory(code, format);
  stopScanning();
  updateStatus('Topildi!', 'found');
}

function displayResult(code, format) {
  barcodeType.textContent = `Turi: ${FORMAT_NAMES[format] || FORMAT_NAMES['unknown']}`;
  barcodeNumber.textContent = code;
  resultSection.style.display = 'block';
  resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

function playSuccessSound() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain); gain.connect(ctx.destination);
    osc.frequency.value = 1000; osc.type = 'sine';
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
    osc.start(ctx.currentTime); osc.stop(ctx.currentTime + 0.15);
  } catch (e) {}
}

// ============================================
// HISTORY
// ============================================

function loadHistory() {
  try { const s = localStorage.getItem(HISTORY_STORAGE_KEY); if (s) { scanHistory = JSON.parse(s); renderHistory(); } }
  catch (e) { scanHistory = []; }
}

function saveHistory() {
  try { localStorage.setItem(HISTORY_STORAGE_KEY, JSON.stringify(scanHistory)); } catch (e) {}
}

function addToHistory(code, format) {
  const idx = scanHistory.findIndex(i => i.code === code);
  if (idx !== -1) scanHistory.splice(idx, 1);
  scanHistory.unshift({ code, format, timestamp: Date.now() });
  if (scanHistory.length > HISTORY_MAX_ITEMS) scanHistory = scanHistory.slice(0, HISTORY_MAX_ITEMS);
  saveHistory(); renderHistory();
}

function renderHistory() {
  if (scanHistory.length === 0) { historySection.style.display = 'none'; return; }
  historySection.style.display = 'block';
  historyList.innerHTML = '';
  scanHistory.forEach(item => {
    const el = document.createElement('div');
    el.className = 'history-item';
    el.innerHTML = `
      <div class="history-item-content">
        <span class="history-code">${item.code}</span>
        <span class="history-type">${FORMAT_NAMES[item.format] || FORMAT_NAMES['unknown']}</span>
      </div>
      <span class="history-item-time">${getTimeAgo(item.timestamp)}</span>`;
    el.addEventListener('click', () => copyToClipboard(item.code));
    historyList.appendChild(el);
  });
}

function clearHistory() {
  scanHistory = []; saveHistory(); renderHistory();
  if (tg.showAlert) tg.showAlert('Tarix tozalandi ✅');
}

function getTimeAgo(ts) {
  const sec = Math.floor((Date.now() - ts) / 1000);
  if (sec < 60) return 'Hozirgina';
  if (sec < 3600) return `${Math.floor(sec / 60)} daqiqa oldin`;
  if (sec < 86400) return `${Math.floor(sec / 3600)} soat oldin`;
  return `${Math.floor(sec / 86400)} kun oldin`;
}

// ============================================
// CLIPBOARD
// ============================================

async function copyToClipboard(text) {
  try {
    await navigator.clipboard.writeText(text);
    copyBtn.classList.add('copied'); copyBtn.innerHTML = '<span>✅</span>';
    setTimeout(() => { copyBtn.classList.remove('copied'); copyBtn.innerHTML = '<span>📋</span>'; }, 1500);
    if (tg.showAlert) tg.showAlert('Nusxalandi! ✅');
  } catch (e) {
    const ta = document.createElement('textarea'); ta.value = text;
    document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta);
  }
}

function scanAgain() {
  lastScannedCode = null;
  resultSection.style.display = 'none';
  startScanning();
}

// ============================================
// EVENTS
// ============================================

requestPermissionBtn.addEventListener('click', () => openCamera());
retryBtn.addEventListener('click', () => openCamera());
switchCameraBtn.addEventListener('click', () => cycleCamera());

restartCameraBtn.addEventListener('click', async () => {
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
  stopScanning(); stopCamera();
  await new Promise(r => setTimeout(r, 500));
  await openCamera();
});

torchBtn.addEventListener('click', () => toggleTorch());
cameraContainer.addEventListener('click', () => triggerFocus());
copyBtn.addEventListener('click', () => { const c = barcodeNumber.textContent; if (c && c !== '--') copyToClipboard(c); });
scanAgainBtn.addEventListener('click', () => scanAgain());
clearHistoryBtn.addEventListener('click', () => clearHistory());

document.addEventListener('visibilitychange', () => {
  if (document.hidden) stopScanning();
  else if (scannerDisplay.style.display === 'block' && resultSection.style.display === 'none') startScanning();
});

window.addEventListener('beforeunload', () => { stopScanning(); stopCamera(); });

// ============================================
// INIT
// ============================================

async function initializeApp() {
  showState('loading');
  loadHistory();
  await initBarcodeDetector();

  const perm = await (async () => {
    try { return (await navigator.permissions.query({ name: 'camera' })).state; }
    catch (e) { return 'prompt'; }
  })();

  if (perm === 'denied') {
    showError('Kamera ruxsati berilmagan. Brauzer sozlamalaridan ruxsat bering.');
  } else if (perm === 'granted') {
    await openCamera();
  } else {
    showState('permission');
  }
}

document.addEventListener('DOMContentLoaded', () => initializeApp());
