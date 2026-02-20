// barcode.js - Barcode Scanner for Telegram WebApp
// VERSION 8: Single permission + Stable detection
// - Only 1 permission prompt (no repeated getUserMedia during camera testing)
// - Barcode must be detected consistently across multiple frames before accepting
// ============================================
// CONSTANTS
// ============================================

const SCAN_INTERVAL = 200;       // ms between scan attempts
const STABLE_COUNT_NEEDED = 3;   // barcode must appear in N consecutive scans to be accepted
const STABLE_TIMEOUT = 2000;     // reset stability counter if no match within this ms
const HISTORY_MAX_ITEMS = 10;
const HISTORY_STORAGE_KEY = 'barcode_scan_history';
const PREFERRED_CAMERA_KEY = 'barcode_preferred_camera_v8';

// Format display names
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

// Camera selection state
let allCameras = [];
let backCameras = [];
let frontCameras = [];
let currentCameraIndex = 0;
let currentFacing = 'back';
let currentDeviceId = null;
let camerasEnumerated = false;

// Barcode stability state
let pendingCode = null;       // The code being confirmed
let pendingFormat = null;
let pendingCount = 0;         // How many consecutive frames it appeared
let pendingLastSeen = 0;      // Timestamp of last detection

// ============================================
// TELEGRAM WEBAPP INITIALIZATION
// ============================================

const tg = window.Telegram.WebApp;
tg.ready();
Telegram.WebApp.disableVerticalSwipes();

try {
  tg.expand();
} catch (e) {
  console.log('Expand not supported');
}

try {
  if (tg.BackButton) {
    tg.BackButton.show();
    tg.BackButton.onClick(() => {
      stopScanning();
      stopCamera();
      window.location.href = "../../index.html";
    });
  }
} catch (e) {
  console.log('BackButton not available');
}

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
// UI STATE MANAGEMENT
// ============================================

function showState(state) {
  loadingState.style.display = 'none';
  permissionState.style.display = 'none';
  errorState.style.display = 'none';
  scannerDisplay.style.display = 'none';
  
  switch (state) {
    case 'loading':
      loadingState.style.display = 'flex';
      break;
    case 'permission':
      permissionState.style.display = 'flex';
      break;
    case 'error':
      errorState.style.display = 'flex';
      break;
    case 'scanner':
      scannerDisplay.style.display = 'block';
      break;
  }
}

function showError(message) {
  errorMessage.textContent = message;
  showState('error');
}

function updateStatus(text, type = 'scanning') {
  statusText.textContent = text;
  statusIndicator.className = `status-indicator ${type}`;
}

// ============================================
// CAMERA ENUMERATION & SELECTION
// ============================================

/**
 * Enumerate all cameras and categorize as front/back using labels.
 * Must be called AFTER a getUserMedia grant so labels are available.
 */
async function enumerateCameras() {
  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    allCameras = devices.filter(d => d.kind === 'videoinput');
    
    console.log(`📷 Found ${allCameras.length} camera(s):`);
    allCameras.forEach((cam, i) => {
      console.log(`  [${i}] ${cam.label || 'Camera ' + i} (id: ${cam.deviceId.substring(0, 12)}...)`);
    });
    
    backCameras = [];
    frontCameras = [];
    
    allCameras.forEach((cam, i) => {
      const label = (cam.label || '').toLowerCase();
      
      if (label.includes('front') || label.includes('user') || label.includes('selfie') || label.includes('facetime')) {
        frontCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
      } else if (label.includes('back') || label.includes('rear') || label.includes('environment') || label.includes('main') || label.includes('wide') || label.includes('tele') || label.includes('ultra') || label.includes('camera2 0') || label.includes('camera2 2') || label.includes('camera2 3')) {
        backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
      } else {
        // No label clue
        if (allCameras.length === 1) {
          backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
        } else if (allCameras.length === 2) {
          if (i === 0) backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
          else frontCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
        } else {
          backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
        }
      }
    });
    
    console.log(`📷 Back cameras: ${backCameras.length}, Front cameras: ${frontCameras.length}`);
    backCameras.forEach((cam, i) => console.log(`  Back[${i}]: ${cam.label || 'Camera'}`));
    frontCameras.forEach((cam, i) => console.log(`  Front[${i}]: ${cam.label || 'Camera'}`));
    
    camerasEnumerated = true;
    return true;
  } catch (e) {
    console.error('❌ Camera enumeration failed:', e);
    return false;
  }
}

/**
 * Find the best back camera WITHOUT opening separate streams.
 * 
 * Strategy: Open each camera one at a time using the SAME permission grant,
 * read capabilities, score, stop, then open the winner for real.
 * Since permission is already granted, no new prompts appear.
 */
async function findBestBackCamera() {
  if (backCameras.length <= 1) {
    console.log('📷 Only one back camera, using it');
    return backCameras.length === 1 ? 0 : -1;
  }
  
  // Check saved preference first (from v8 — not stale)
  const savedId = localStorage.getItem(PREFERRED_CAMERA_KEY);
  if (savedId) {
    const savedIndex = backCameras.findIndex(c => c.deviceId === savedId);
    if (savedIndex !== -1) {
      console.log(`📷 Using saved preferred camera: Back[${savedIndex}]`);
      return savedIndex;
    }
  }
  
  console.log(`📷 Testing ${backCameras.length} back cameras (single permission)...`);
  
  let bestIndex = 0;
  let bestScore = -1;
  const scores = [];
  
  for (let i = 0; i < backCameras.length; i++) {
    const cam = backCameras[i];
    console.log(`📷 Testing Back[${i}]: ${cam.label || 'Unknown'}...`);
    
    try {
      // Open stream — permission already granted, no new prompt
      const testStream = await navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: cam.deviceId } },
        audio: false
      });
      
      const track = testStream.getVideoTracks()[0];
      const capabilities = track.getCapabilities ? track.getCapabilities() : {};
      
      let score = 0;
      
      // FOCUS (most important)
      if (capabilities.focusMode) {
        const modes = capabilities.focusMode;
        console.log(`  Focus modes: [${modes.join(', ')}]`);
        if (modes.includes('continuous')) score += 100;
        if (modes.includes('single-shot')) score += 50;
      }
      
      if (capabilities.focusDistance) {
        score += 60;
        console.log(`  Focus distance: ${capabilities.focusDistance.min}-${capabilities.focusDistance.max}`);
      }
      
      // TORCH (strong main-camera signal)
      if (capabilities.torch) {
        score += 80;
        console.log(`  Torch: supported`);
      }
      
      // ZOOM
      if (capabilities.zoom && capabilities.zoom.max > 1) {
        score += 30;
        console.log(`  Zoom: ${capabilities.zoom.min}-${capabilities.zoom.max}`);
      }
      
      // RESOLUTION
      if (capabilities.width && capabilities.width.max) {
        score += Math.min(Math.floor(capabilities.width.max / 100), 30);
        console.log(`  Max resolution: ${capabilities.width.max}`);
      }
      
      console.log(`  ✅ Score: ${score}`);
      scores.push({ index: i, score, label: cam.label });
      
      // IMPORTANT: stop immediately to release camera for next test
      testStream.getTracks().forEach(t => t.stop());
      
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
      
      // Brief pause between tests
      await new Promise(r => setTimeout(r, 100));
      
    } catch (e) {
      console.log(`  ❌ Failed: ${e.message}`);
      scores.push({ index: i, score: 0, label: cam.label, error: true });
    }
  }
  
  console.log('📷 Camera scores:');
  scores.forEach(s => {
    const marker = s.index === bestIndex ? ' ← BEST' : '';
    console.log(`  Back[${s.index}] ${s.label || 'Camera'}: ${s.score}${marker}`);
  });
  
  // Save winner
  if (backCameras[bestIndex]) {
    localStorage.setItem(PREFERRED_CAMERA_KEY, backCameras[bestIndex].deviceId);
  }
  
  return bestIndex;
}

// ============================================
// CAMERA FUNCTIONS
// ============================================

async function checkCameraPermission() {
  try {
    const permission = await navigator.permissions.query({ name: 'camera' });
    return permission.state;
  } catch (e) {
    return 'prompt';
  }
}

/**
 * Main camera start function.
 * 
 * Flow for first launch:
 * 1. Single getUserMedia({ video: true }) — triggers ONE permission prompt
 * 2. enumerateDevices() — now has labels
 * 3. Test each back camera's capabilities (no new permission prompts)
 * 4. Open the best camera for actual use
 */
async function startCamera() {
  console.log('📷 Starting camera v8...');
  
  try {
    if (videoStream) {
      stopCamera();
    }
    
    videoElement = document.getElementById('videoElement');
    
    // Step 1: Get initial permission with a single prompt
    if (!camerasEnumerated) {
      let tempStream = null;
      try {
        // This is the ONLY getUserMedia that may trigger a permission prompt
        tempStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
        console.log('✅ Camera permission granted');
      } catch (e) {
        handleCameraError(e);
        return false;
      }
      
      // Step 2: Enumerate with labels
      await enumerateCameras();
      
      // Stop temp stream before testing
      if (tempStream) {
        tempStream.getTracks().forEach(t => t.stop());
        tempStream = null;
        await new Promise(r => setTimeout(r, 200));
      }
      
      // Step 3: Find the best back camera (opens/closes streams but no new prompts)
      if (currentFacing === 'back' && backCameras.length > 1 && !currentDeviceId) {
        const bestIdx = await findBestBackCamera();
        if (bestIdx >= 0) {
          currentCameraIndex = bestIdx;
        }
      }
    }
    
    // Determine which camera list to use
    const cameraList = currentFacing === 'back' ? backCameras : frontCameras;
    
    if (cameraList.length === 0) {
      return await startCameraWithFacingMode();
    }
    
    // Clamp index
    if (currentCameraIndex >= cameraList.length) {
      currentCameraIndex = 0;
    }
    
    const selectedCamera = cameraList[currentCameraIndex];
    currentDeviceId = selectedCamera.deviceId;
    
    console.log(`📷 Opening: ${selectedCamera.label || 'Camera'} (${currentFacing} [${currentCameraIndex + 1}/${cameraList.length}])`);
    
    // Step 4: Open the chosen camera — no permission prompt
    const constraints = {
      video: {
        deviceId: { exact: currentDeviceId },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      },
      audio: false
    };
    
    try {
      videoStream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      console.log('⚠️ Ideal resolution failed, trying bare deviceId...');
      videoStream = await navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: currentDeviceId } },
        audio: false
      });
    }
    
    cameraTrack = videoStream.getVideoTracks()[0];
    const settings = cameraTrack.getSettings();
    
    console.log('📷 Active:', JSON.stringify(settings));
    
    // Apply continuous autofocus
    await applyContinuousAutofocus();
    
    // ImageCapture
    try {
      if ('ImageCapture' in window) {
        imageCapture = new ImageCapture(cameraTrack);
      }
    } catch (e) {
      imageCapture = null;
    }
    
    // Attach to video element
    videoElement.srcObject = videoStream;
    
    await new Promise((resolve, reject) => {
      videoElement.onloadedmetadata = () => {
        videoElement.play().then(resolve).catch(reject);
      };
      videoElement.onerror = reject;
    });
    
    console.log(`✅ Camera started: ${settings.width}x${settings.height}`);
    
    updateCameraInfo();
    checkTorchSupport();
    
    showState('scanner');
    startScanning();
    
    return true;
    
  } catch (error) {
    console.error('❌ Camera error:', error);
    handleCameraError(error);
    return false;
  }
}

async function applyContinuousAutofocus() {
  if (!cameraTrack) return;
  
  try {
    const capabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    
    if (capabilities.focusMode && capabilities.focusMode.includes('continuous')) {
      await cameraTrack.applyConstraints({
        advanced: [{ focusMode: 'continuous' }]
      });
      console.log('✅ Continuous autofocus enabled');
    } else if (capabilities.focusMode && capabilities.focusMode.includes('single-shot')) {
      await cameraTrack.applyConstraints({
        advanced: [{ focusMode: 'single-shot' }]
      });
      console.log('✅ Single-shot autofocus enabled');
    }
  } catch (e) {
    console.log('⚠️ Could not set focus mode:', e.message);
  }
}

async function startCameraWithFacingMode() {
  console.log('📷 Fallback: using facingMode...');
  try {
    const facingMode = currentFacing === 'back' ? 'environment' : 'user';
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode },
      audio: false
    });
    
    cameraTrack = videoStream.getVideoTracks()[0];
    videoElement = document.getElementById('videoElement');
    videoElement.srcObject = videoStream;
    
    await applyContinuousAutofocus();
    
    await new Promise(resolve => {
      videoElement.onloadedmetadata = () => {
        videoElement.play().then(resolve);
      };
    });
    
    checkTorchSupport();
    showState('scanner');
    startScanning();
    return true;
  } catch (e) {
    showError('Kameraga ulanib bo\'lmadi.');
    return false;
  }
}

function handleCameraError(error) {
  if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
    showState('permission');
  } else if (error.name === 'NotFoundError') {
    showError('Kamera topilmadi.');
  } else if (error.name === 'NotReadableError') {
    showError('Kamera band. Boshqa ilovalarni yoping.');
  } else if (error.name === 'OverconstrainedError') {
    startCameraWithFacingMode();
  } else {
    showError(`Kamera xatoligi: ${error.message}`);
  }
}

function updateCameraInfo() {
  const cameraList = currentFacing === 'back' ? backCameras : frontCameras;
  const infoEl = document.getElementById('cameraInfoBadge');
  
  if (infoEl && cameraList.length > 1) {
    infoEl.textContent = `📷 ${currentCameraIndex + 1}/${cameraList.length}`;
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
    const capabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    
    if (capabilities.focusMode && capabilities.focusMode.includes('single-shot')) {
      await cameraTrack.applyConstraints({
        advanced: [{ focusMode: 'single-shot' }]
      });
      
      setTimeout(async () => {
        try {
          if (capabilities.focusMode.includes('continuous')) {
            await cameraTrack.applyConstraints({
              advanced: [{ focusMode: 'continuous' }]
            });
          }
        } catch (e) {}
      }, 1500);
    }
  } catch (e) {}
}

function stopCamera() {
  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop());
    videoStream = null;
  }
  if (videoElement) {
    videoElement.srcObject = null;
  }
  cameraTrack = null;
  imageCapture = null;
}

async function switchFacing() {
  currentFacing = currentFacing === 'back' ? 'front' : 'back';
  currentCameraIndex = 0;
  currentDeviceId = null;
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 300));
  await startCamera();
}

async function cycleCamera() {
  const cameraList = currentFacing === 'back' ? backCameras : frontCameras;
  
  if (cameraList.length <= 1) {
    await switchFacing();
    return;
  }
  
  currentCameraIndex = (currentCameraIndex + 1) % cameraList.length;
  currentDeviceId = cameraList[currentCameraIndex].deviceId;
  
  console.log(`📷 Cycling to ${currentFacing} [${currentCameraIndex}]: ${cameraList[currentCameraIndex].label || 'Unknown'}`);
  
  if (currentFacing === 'back') {
    localStorage.setItem(PREFERRED_CAMERA_KEY, currentDeviceId);
  }
  
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 300));
  await startCamera();
}

function checkTorchSupport() {
  if (!cameraTrack) {
    torchBtn.style.display = 'none';
    return;
  }
  
  try {
    const capabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    if (capabilities.torch) {
      torchBtn.style.display = 'flex';
    } else {
      torchBtn.style.display = 'none';
    }
  } catch (e) {
    torchBtn.style.display = 'none';
  }
}

async function toggleTorch() {
  if (!cameraTrack) return;
  
  torchEnabled = !torchEnabled;
  
  try {
    await cameraTrack.applyConstraints({
      advanced: [{ torch: torchEnabled }]
    });
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
    } catch (e) {
      console.warn('⚠️ BarcodeDetector init failed:', e);
    }
  }
  console.log('⚠️ BarcodeDetector not available');
  return false;
}

function startScanning() {
  if (isScanning) return;
  
  isScanning = true;
  resetPendingBarcode();
  updateStatus('Qidirilmoqda...', 'scanning');
  
  scanInterval = setInterval(scanFrame, SCAN_INTERVAL);
  console.log('▶️ Scanning started');
}

function stopScanning() {
  isScanning = false;
  if (scanInterval) {
    clearInterval(scanInterval);
    scanInterval = null;
  }
  resetPendingBarcode();
}

// ============================================
// BARCODE STABILITY CHECK
// ============================================

function resetPendingBarcode() {
  pendingCode = null;
  pendingFormat = null;
  pendingCount = 0;
  pendingLastSeen = 0;
}

/**
 * Process a detected barcode through the stability filter.
 * The same code must be detected in STABLE_COUNT_NEEDED consecutive scans
 * to be accepted. This prevents accepting partial/misread barcodes
 * when the user is still positioning the product.
 */
function processDetection(code, format) {
  const now = Date.now();
  
  // If this is a different code from what we were tracking, restart
  if (code !== pendingCode) {
    pendingCode = code;
    pendingFormat = format;
    pendingCount = 1;
    pendingLastSeen = now;
    console.log(`🔍 New candidate: ${code} (1/${STABLE_COUNT_NEEDED})`);
    return false;
  }
  
  // Same code — check if it timed out (user moved away and came back)
  if (now - pendingLastSeen > STABLE_TIMEOUT) {
    pendingCount = 1;
    pendingLastSeen = now;
    console.log(`🔍 Candidate reset (timeout): ${code} (1/${STABLE_COUNT_NEEDED})`);
    return false;
  }
  
  // Same code, within timeout — increment
  pendingCount++;
  pendingLastSeen = now;
  pendingFormat = format; // Use latest format detection
  
  console.log(`🔍 Candidate confirmed: ${code} (${pendingCount}/${STABLE_COUNT_NEEDED})`);
  
  if (pendingCount >= STABLE_COUNT_NEEDED) {
    // Stable! Accept it.
    return true;
  }
  
  return false;
}

// ============================================
// SCAN FRAME
// ============================================

async function scanFrame() {
  if (!isScanning || !videoElement || videoElement.readyState !== 4) {
    return;
  }
  
  try {
    let barcodes = [];
    
    if (barcodeDetector) {
      barcodes = await barcodeDetector.detect(videoElement);
    }
    
    // Fallback: try ImageCapture grabbed frame
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
      const barcode = barcodes[0];
      const code = barcode.rawValue || barcode.data;
      const format = barcode.format || 'unknown';
      
      // Skip if this was already accepted
      if (code === lastScannedCode) return;
      
      // Run through stability filter
      const stable = processDetection(code, format);
      
      if (stable) {
        handleBarcodeConfirmed(code, format);
      }
    }
    
  } catch (error) {
    // Silent fail for individual frames
  }
}

function handleBarcodeConfirmed(code, format) {
  lastScannedCode = code;
  console.log(`✅ Confirmed: ${code} (${format})`);
  
  if (navigator.vibrate) {
    navigator.vibrate([100, 50, 100]);
  }
  playSuccessSound();
  
  displayResult(code, format);
  addToHistory(code, format);
  
  stopScanning();
  updateStatus('Topildi!', 'found');
}

function displayResult(code, format) {
  const formatName = FORMAT_NAMES[format] || FORMAT_NAMES['unknown'];
  
  barcodeType.textContent = `Turi: ${formatName}`;
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
    const stored = localStorage.getItem(HISTORY_STORAGE_KEY);
    if (stored) {
      scanHistory = JSON.parse(stored);
      renderHistory();
    }
  } catch (e) {
    scanHistory = [];
  }
}

function saveHistory() {
  try {
    localStorage.setItem(HISTORY_STORAGE_KEY, JSON.stringify(scanHistory));
  } catch (e) {}
}

function addToHistory(code, format) {
  const idx = scanHistory.findIndex(i => i.code === code);
  if (idx !== -1) scanHistory.splice(idx, 1);
  
  scanHistory.unshift({ code, format, timestamp: Date.now() });
  
  if (scanHistory.length > HISTORY_MAX_ITEMS) {
    scanHistory = scanHistory.slice(0, HISTORY_MAX_ITEMS);
  }
  
  saveHistory();
  renderHistory();
}

function renderHistory() {
  if (scanHistory.length === 0) {
    historySection.style.display = 'none';
    return;
  }
  
  historySection.style.display = 'block';
  historyList.innerHTML = '';
  
  scanHistory.forEach(item => {
    const formatName = FORMAT_NAMES[item.format] || FORMAT_NAMES['unknown'];
    const timeAgo = getTimeAgo(item.timestamp);
    
    const el = document.createElement('div');
    el.className = 'history-item';
    el.innerHTML = `
      <div class="history-item-content">
        <span class="history-code">${item.code}</span>
        <span class="history-type">${formatName}</span>
      </div>
      <span class="history-item-time">${timeAgo}</span>
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
    setTimeout(() => {
      copyBtn.classList.remove('copied');
      copyBtn.innerHTML = '<span>📋</span>';
    }, 1500);
    
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
// EVENT LISTENERS
// ============================================

requestPermissionBtn.addEventListener('click', async () => {
  showState('loading');
  await startCamera();
});

retryBtn.addEventListener('click', async () => {
  showState('loading');
  await startCamera();
});

// Short tap = cycle cameras in same facing group
switchCameraBtn.addEventListener('click', () => cycleCamera());

// Restart camera
restartCameraBtn.addEventListener('click', async () => {
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
  
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 500));
  await startCamera();
});

torchBtn.addEventListener('click', () => toggleTorch());

// Tap to focus
cameraContainer.addEventListener('click', () => triggerFocus());

copyBtn.addEventListener('click', () => {
  const code = barcodeNumber.textContent;
  if (code && code !== '--') copyToClipboard(code);
});

scanAgainBtn.addEventListener('click', () => scanAgain());

clearHistoryBtn.addEventListener('click', () => clearHistory());

// Long press switch button = flip front/back
let switchLongPressTimer = null;
switchCameraBtn.addEventListener('touchstart', (e) => {
  switchLongPressTimer = setTimeout(() => {
    e.preventDefault();
    switchFacing();
    switchLongPressTimer = null;
  }, 800);
}, { passive: false });

switchCameraBtn.addEventListener('touchend', () => {
  if (switchLongPressTimer) {
    clearTimeout(switchLongPressTimer);
    switchLongPressTimer = null;
  }
});

// Visibility handling
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    stopScanning();
  } else if (scannerDisplay.style.display === 'block' && resultSection.style.display === 'none') {
    startScanning();
  }
});

window.addEventListener('beforeunload', () => {
  stopScanning();
  stopCamera();
});

// ============================================
// INIT
// ============================================

async function initializeApp() {
  console.log('🚀 Barcode Scanner v8 - Single Permission + Stable Detection');
  
  showState('loading');
  loadHistory();
  await initBarcodeDetector();
  
  const permission = await checkCameraPermission();
  console.log('📷 Permission:', permission);
  
  if (permission === 'granted') {
    await startCamera();
  } else if (permission === 'denied') {
    showError('Kamera ruxsati berilmagan. Brauzer sozlamalaridan ruxsat bering.');
  } else {
    showState('permission');
  }
}

document.addEventListener('DOMContentLoaded', () => {
  console.log('📄 DOM ready');
  initializeApp();
});

console.log('📜 barcode.js v8 loaded');
