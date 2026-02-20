// barcode.js - Barcode Scanner for Telegram WebApp
// VERSION 9: Single permission, back camera only, stable detection
// ============================================
// CONSTANTS
// ============================================

const SCAN_INTERVAL = 200;
const STABLE_COUNT_NEEDED = 3;
const STABLE_TIMEOUT = 2000;
const HISTORY_MAX_ITEMS = 10;
const HISTORY_STORAGE_KEY = 'barcode_scan_history';
const PREFERRED_CAMERA_KEY = 'barcode_preferred_cam_v9';

const FORMAT_NAMES = {
  'ean_13': 'EAN-13',
  'ean_8': 'EAN-8',
  'upc_a': 'UPC-A',
  'upc_e': 'UPC-E',
  'code_128': 'Code 128',
  'code_39': 'Code 39',
  'code_93': 'Code 93',
  'codabar': 'Codabar',
  'itf': 'ITF',
  'qr_code': 'QR Code',
  'data_matrix': 'Data Matrix',
  'unknown': 'Noma\'lum'
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

// Camera state
let backCameras = [];
let currentCameraIndex = 0;
let permissionGranted = false;

// Stability state
let pendingCode = null;
let pendingFormat = null;
let pendingCount = 0;
let pendingLastSeen = 0;

// ============================================
// TELEGRAM WEBAPP
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();
Telegram.WebApp.disableVerticalSwipes();

try { tg.expand(); } catch (e) {}

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      stopScanning();
      stopCamera();
      window.location.href = "../../index.html";
    });
  }
} catch (e) {}

// ============================================
// DOM ELEMENTS
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

function showError(msg) {
  errorMessage.textContent = msg;
  showState('error');
}

function updateStatus(text, type = 'scanning') {
  statusText.textContent = text;
  statusIndicator.className = `status-indicator ${type}`;
}

// ============================================
// CAMERA: SINGLE PERMISSION APPROACH
//
// The key insight: Telegram WebView (and many Android browsers)
// prompt permission PER deviceId. So we NEVER call getUserMedia
// with deviceId during camera testing.
//
// Flow:
// 1. getUserMedia({ facingMode: 'environment' }) — ONE prompt
// 2. Keep that stream alive, read its track capabilities
// 3. Enumerate devices to find other back cameras
// 4. Score the initial stream's camera
// 5. To test other cameras: we DON'T open them during selection.
//    Instead, we use label heuristics + the fact that the camera
//    with torch/autofocus is the main one (which we already have).
// 6. If user manually cycles cameras, THEN we open by deviceId
//    (permission already granted for camera, no new prompt).
// ============================================

async function grantPermissionAndEnumerate() {
  console.log('📷 Step 1: Getting camera permission (single prompt)...');
  
  try {
    // ONE getUserMedia call — this is the only permission prompt
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: { ideal: 'environment' },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      },
      audio: false
    });
    
    permissionGranted = true;
    cameraTrack = videoStream.getVideoTracks()[0];
    const initialSettings = cameraTrack.getSettings();
    const initialDeviceId = initialSettings.deviceId;
    
    console.log('✅ Permission granted, got camera:', cameraTrack.label);
    console.log('📷 Initial settings:', JSON.stringify(initialSettings));
    
    // Read capabilities of this camera
    const initialCapabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    const initialScore = scoreCapabilities(initialCapabilities, 'Initial');
    
    // Step 2: Enumerate all devices (labels now available)
    const devices = await navigator.mediaDevices.enumerateDevices();
    const allVideoCameras = devices.filter(d => d.kind === 'videoinput');
    
    console.log(`📷 Found ${allVideoCameras.length} cameras total`);
    
    // Identify back cameras by label
    backCameras = [];
    allVideoCameras.forEach((cam, i) => {
      const label = (cam.label || '').toLowerCase();
      const isFront = label.includes('front') || label.includes('user') || label.includes('selfie') || label.includes('facetime');
      
      if (!isFront) {
        backCameras.push({
          deviceId: cam.deviceId,
          label: cam.label,
          isInitial: cam.deviceId === initialDeviceId,
          score: cam.deviceId === initialDeviceId ? initialScore : null
        });
        console.log(`  Back[${backCameras.length - 1}]: ${cam.label || 'Camera ' + i}${cam.deviceId === initialDeviceId ? ' ← CURRENT' : ''}`);
      } else {
        console.log(`  Front (skipped): ${cam.label || 'Camera ' + i}`);
      }
    });
    
    // If our initial camera isn't in backCameras (shouldn't happen), add it
    if (!backCameras.some(c => c.isInitial)) {
      backCameras.unshift({
        deviceId: initialDeviceId,
        label: cameraTrack.label,
        isInitial: true,
        score: initialScore
      });
    }
    
    // Determine best camera
    const bestIndex = pickBestCamera(initialCapabilities, initialDeviceId);
    
    if (bestIndex >= 0 && !backCameras[bestIndex].isInitial) {
      // A different camera scored better — switch to it
      console.log(`📷 Switching to better camera: Back[${bestIndex}]`);
      
      // Stop current stream
      videoStream.getTracks().forEach(t => t.stop());
      videoStream = null;
      cameraTrack = null;
      
      await new Promise(r => setTimeout(r, 200));
      
      // Open the better camera (no new permission prompt — already granted)
      currentCameraIndex = bestIndex;
      await openCameraByIndex(bestIndex);
    } else {
      // Current camera is the best — just use it
      currentCameraIndex = backCameras.findIndex(c => c.isInitial);
      if (currentCameraIndex < 0) currentCameraIndex = 0;
      
      console.log(`📷 Keeping initial camera: Back[${currentCameraIndex}]`);
      await setupCurrentStream();
    }
    
    return true;
    
  } catch (error) {
    console.error('❌ Camera error:', error);
    handleCameraError(error);
    return false;
  }
}

function scoreCapabilities(capabilities, label) {
  let score = 0;
  
  if (capabilities.focusMode) {
    const modes = capabilities.focusMode;
    if (modes.includes('continuous')) score += 100;
    if (modes.includes('single-shot')) score += 50;
    console.log(`  ${label} focus modes: [${modes.join(', ')}]`);
  }
  
  if (capabilities.focusDistance) {
    score += 60;
    console.log(`  ${label} focusDistance: ${capabilities.focusDistance.min}-${capabilities.focusDistance.max}`);
  }
  
  if (capabilities.torch) {
    score += 80;
    console.log(`  ${label} torch: yes`);
  }
  
  if (capabilities.zoom && capabilities.zoom.max > 1) {
    score += 30;
    console.log(`  ${label} zoom: ${capabilities.zoom.min}-${capabilities.zoom.max}`);
  }
  
  if (capabilities.width && capabilities.width.max) {
    score += Math.min(Math.floor(capabilities.width.max / 100), 30);
  }
  
  console.log(`  ${label} total score: ${score}`);
  return score;
}

/**
 * Pick the best back camera.
 * We already have the score for the initial camera.
 * For other cameras, we use label heuristics since we can't open them without
 * potentially triggering a permission prompt.
 * 
 * BUT — if user has a saved preference, use that directly.
 */
function pickBestCamera(initialCapabilities, initialDeviceId) {
  if (backCameras.length <= 1) return 0;
  
  // Saved preference from previous manual selection
  const savedId = localStorage.getItem(PREFERRED_CAMERA_KEY);
  if (savedId) {
    const savedIdx = backCameras.findIndex(c => c.deviceId === savedId);
    if (savedIdx !== -1) {
      console.log(`📷 Saved preference: Back[${savedIdx}]`);
      return savedIdx;
    }
  }
  
  // If the initial camera (facingMode: environment) already has torch + autofocus,
  // it's almost certainly the main camera — keep it
  const hasGoodFocus = initialCapabilities.focusMode && 
    (initialCapabilities.focusMode.includes('continuous') || initialCapabilities.focusMode.includes('single-shot'));
  const hasTorch = !!initialCapabilities.torch;
  
  if (hasGoodFocus && hasTorch) {
    console.log('📷 Initial camera has autofocus + torch — keeping it');
    return backCameras.findIndex(c => c.isInitial);
  }
  
  // Initial camera lacks good features — the other back camera might be better.
  // Return the first non-initial camera so we can try it.
  // (When opened, if it's also bad, user can cycle back)
  const otherIdx = backCameras.findIndex(c => !c.isInitial);
  if (otherIdx !== -1) {
    console.log(`📷 Initial camera lacks autofocus/torch — trying Back[${otherIdx}]`);
    return otherIdx;
  }
  
  return backCameras.findIndex(c => c.isInitial);
}

/**
 * Open a specific back camera by index. No permission prompt since camera access
 * was already granted via the initial getUserMedia.
 */
async function openCameraByIndex(index) {
  const cam = backCameras[index];
  if (!cam) return false;
  
  console.log(`📷 Opening Back[${index}]: ${cam.label || 'Camera'}`);
  
  try {
    if (videoStream) {
      videoStream.getTracks().forEach(t => t.stop());
      videoStream = null;
      cameraTrack = null;
      await new Promise(r => setTimeout(r, 200));
    }
    
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: {
        deviceId: { exact: cam.deviceId },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      },
      audio: false
    });
    
    cameraTrack = videoStream.getVideoTracks()[0];
    
    // Score this camera if not scored yet
    if (cam.score === null) {
      const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
      cam.score = scoreCapabilities(caps, `Back[${index}]`);
    }
    
    await setupCurrentStream();
    return true;
    
  } catch (e) {
    console.error(`❌ Failed to open Back[${index}]:`, e);
    // If failed, try to go back to initial camera
    const initialIdx = backCameras.findIndex(c => c.isInitial);
    if (initialIdx !== -1 && initialIdx !== index) {
      return await openCameraByIndex(initialIdx);
    }
    showError('Kameraga ulanib bo\'lmadi.');
    return false;
  }
}

/**
 * Setup the current videoStream — apply autofocus, attach to video element, etc.
 */
async function setupCurrentStream() {
  videoElement = document.getElementById('videoElement');
  
  // Apply autofocus
  await applyContinuousAutofocus();
  
  // ImageCapture
  try {
    if ('ImageCapture' in window && cameraTrack) {
      imageCapture = new ImageCapture(cameraTrack);
    }
  } catch (e) {
    imageCapture = null;
  }
  
  // Attach to video
  videoElement.srcObject = videoStream;
  
  await new Promise((resolve, reject) => {
    videoElement.onloadedmetadata = () => {
      videoElement.play().then(resolve).catch(reject);
    };
    videoElement.onerror = reject;
  });
  
  const settings = cameraTrack.getSettings();
  console.log(`✅ Camera active: ${settings.width}x${settings.height}`);
  
  updateCameraInfo();
  checkTorchSupport();
  showState('scanner');
  startScanning();
}

async function applyContinuousAutofocus() {
  if (!cameraTrack) return;
  
  try {
    const capabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    
    if (capabilities.focusMode && capabilities.focusMode.includes('continuous')) {
      await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
      console.log('✅ Continuous autofocus ON');
    } else if (capabilities.focusMode && capabilities.focusMode.includes('single-shot')) {
      await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'single-shot' }] });
      console.log('✅ Single-shot autofocus ON');
    }
  } catch (e) {
    console.log('⚠️ Focus mode failed:', e.message);
  }
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
  if (infoEl && backCameras.length > 1) {
    infoEl.textContent = `📷 ${currentCameraIndex + 1}/${backCameras.length}`;
    infoEl.style.display = 'inline-block';
  } else if (infoEl) {
    infoEl.style.display = 'none';
  }
}

// Tap to focus
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
          if (caps.focusMode.includes('continuous')) {
            await cameraTrack.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
          }
        } catch (e) {}
      }, 1500);
    }
  } catch (e) {}
}

function stopCamera() {
  if (videoStream) {
    videoStream.getTracks().forEach(t => t.stop());
    videoStream = null;
  }
  if (videoElement) {
    videoElement.srcObject = null;
  }
  cameraTrack = null;
  imageCapture = null;
}

/**
 * Cycle to next back camera. Since permission is already granted,
 * opening by deviceId won't prompt again.
 */
async function cycleCamera() {
  if (backCameras.length <= 1) {
    console.log('📷 Only one back camera, nothing to cycle');
    return;
  }
  
  stopScanning();
  
  currentCameraIndex = (currentCameraIndex + 1) % backCameras.length;
  
  console.log(`📷 Cycling to Back[${currentCameraIndex}]: ${backCameras[currentCameraIndex].label || 'Camera'}`);
  
  // Save preference
  localStorage.setItem(PREFERRED_CAMERA_KEY, backCameras[currentCameraIndex].deviceId);
  
  await openCameraByIndex(currentCameraIndex);
}

function checkTorchSupport() {
  if (!cameraTrack) { torchBtn.style.display = 'none'; return; }
  try {
    const caps = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    torchBtn.style.display = caps.torch ? 'flex' : 'none';
  } catch (e) {
    torchBtn.style.display = 'none';
  }
}

async function toggleTorch() {
  if (!cameraTrack) return;
  torchEnabled = !torchEnabled;
  try {
    await cameraTrack.applyConstraints({ advanced: [{ torch: torchEnabled }] });
    torchBtn.classList.toggle('active', torchEnabled);
    torchIcon.textContent = torchEnabled ? '💡' : '🔦';
  } catch (e) {
    torchEnabled = false;
  }
}

// ============================================
// BARCODE DETECTION
// ============================================

async function initBarcodeDetector() {
  if ('BarcodeDetector' in window) {
    try {
      const formats = await BarcodeDetector.getSupportedFormats();
      console.log('✅ BarcodeDetector formats:', formats);
      barcodeDetector = new BarcodeDetector({ formats });
      return true;
    } catch (e) {}
  }
  console.log('⚠️ BarcodeDetector not available');
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

// ============================================
// STABILITY FILTER
// ============================================

function resetPending() {
  pendingCode = null;
  pendingFormat = null;
  pendingCount = 0;
  pendingLastSeen = 0;
}

function processDetection(code, format) {
  const now = Date.now();
  
  if (code !== pendingCode) {
    pendingCode = code;
    pendingFormat = format;
    pendingCount = 1;
    pendingLastSeen = now;
    console.log(`🔍 Candidate: ${code} (1/${STABLE_COUNT_NEEDED})`);
    return false;
  }
  
  if (now - pendingLastSeen > STABLE_TIMEOUT) {
    pendingCount = 1;
    pendingLastSeen = now;
    return false;
  }
  
  pendingCount++;
  pendingLastSeen = now;
  pendingFormat = format;
  
  console.log(`🔍 Confirmed: ${code} (${pendingCount}/${STABLE_COUNT_NEEDED})`);
  return pendingCount >= STABLE_COUNT_NEEDED;
}

// ============================================
// SCAN FRAME
// ============================================

async function scanFrame() {
  if (!isScanning || !videoElement || videoElement.readyState !== 4) return;
  
  try {
    let barcodes = [];
    
    if (barcodeDetector) {
      barcodes = await barcodeDetector.detect(videoElement);
    }
    
    if (barcodes.length === 0 && imageCapture) {
      try {
        const frame = await imageCapture.grabFrame();
        if (frame && barcodeDetector) {
          barcodes = await barcodeDetector.detect(frame);
          frame.close();
        }
      } catch (e) {}
    }
    
    if (barcodes.length > 0) {
      const b = barcodes[0];
      const code = b.rawValue || b.data;
      const format = b.format || 'unknown';
      
      if (code === lastScannedCode) return;
      
      if (processDetection(code, format)) {
        handleBarcodeConfirmed(code, format);
      }
    }
  } catch (e) {}
}

function handleBarcodeConfirmed(code, format) {
  lastScannedCode = code;
  console.log(`✅ Accepted: ${code} (${format})`);
  
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
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = 1000;
    osc.type = 'sine';
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.15);
  } catch (e) {}
}

// ============================================
// HISTORY
// ============================================

function loadHistory() {
  try {
    const s = localStorage.getItem(HISTORY_STORAGE_KEY);
    if (s) { scanHistory = JSON.parse(s); renderHistory(); }
  } catch (e) { scanHistory = []; }
}

function saveHistory() {
  try { localStorage.setItem(HISTORY_STORAGE_KEY, JSON.stringify(scanHistory)); } catch (e) {}
}

function addToHistory(code, format) {
  const idx = scanHistory.findIndex(i => i.code === code);
  if (idx !== -1) scanHistory.splice(idx, 1);
  scanHistory.unshift({ code, format, timestamp: Date.now() });
  if (scanHistory.length > HISTORY_MAX_ITEMS) scanHistory = scanHistory.slice(0, HISTORY_MAX_ITEMS);
  saveHistory();
  renderHistory();
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
      <span class="history-item-time">${getTimeAgo(item.timestamp)}</span>
    `;
    el.addEventListener('click', () => copyToClipboard(item.code));
    historyList.appendChild(el);
  });
}

function clearHistory() {
  scanHistory = [];
  saveHistory();
  renderHistory();
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
    copyBtn.classList.add('copied');
    copyBtn.innerHTML = '<span>✅</span>';
    setTimeout(() => { copyBtn.classList.remove('copied'); copyBtn.innerHTML = '<span>📋</span>'; }, 1500);
    if (tg.showAlert) tg.showAlert('Nusxalandi! ✅');
  } catch (e) {
    const ta = document.createElement('textarea');
    ta.value = text;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  }
}

// ============================================
// SCAN AGAIN
// ============================================

function scanAgain() {
  lastScannedCode = null;
  resultSection.style.display = 'none';
  startScanning();
}

// ============================================
// EVENTS
// ============================================

requestPermissionBtn.addEventListener('click', async () => {
  showState('loading');
  await grantPermissionAndEnumerate();
});

retryBtn.addEventListener('click', async () => {
  showState('loading');
  await grantPermissionAndEnumerate();
});

// Cycle back cameras
switchCameraBtn.addEventListener('click', () => cycleCamera());

// Restart
restartCameraBtn.addEventListener('click', async () => {
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 500));
  await openCameraByIndex(currentCameraIndex);
});

torchBtn.addEventListener('click', () => toggleTorch());
cameraContainer.addEventListener('click', () => triggerFocus());

copyBtn.addEventListener('click', () => {
  const code = barcodeNumber.textContent;
  if (code && code !== '--') copyToClipboard(code);
});

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
  console.log('🚀 Barcode Scanner v9');
  showState('loading');
  loadHistory();
  await initBarcodeDetector();
  
  const permission = await (async () => {
    try { return (await navigator.permissions.query({ name: 'camera' })).state; }
    catch (e) { return 'prompt'; }
  })();
  
  if (permission === 'granted') {
    await grantPermissionAndEnumerate();
  } else if (permission === 'denied') {
    showError('Kamera ruxsati berilmagan. Brauzer sozlamalaridan ruxsat bering.');
  } else {
    showState('permission');
  }
}

document.addEventListener('DOMContentLoaded', () => initializeApp());
console.log('📜 barcode.js v9 loaded');
