// barcode.js - Barcode Scanner for Telegram WebApp
// VERSION 7: Camera Selection - Pick the right back camera with autofocus
// ============================================
// CONSTANTS
// ============================================

const SCAN_INTERVAL = 200; // ms between scan attempts
const HISTORY_MAX_ITEMS = 10;
const HISTORY_STORAGE_KEY = 'barcode_scan_history';
const PREFERRED_CAMERA_KEY = 'barcode_preferred_camera';

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
let allCameras = [];        // All video input devices
let backCameras = [];       // Back-facing cameras only
let frontCameras = [];      // Front-facing cameras only
let currentCameraIndex = 0; // Index within backCameras or frontCameras
let currentFacing = 'back'; // 'back' or 'front'
let currentDeviceId = null; // The actual deviceId being used

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
 * Enumerate all cameras and categorize them as front/back.
 * We need an initial getUserMedia call first to get labels.
 */
async function enumerateCameras() {
  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    allCameras = devices.filter(d => d.kind === 'videoinput');
    
    console.log(`📷 Found ${allCameras.length} camera(s):`);
    allCameras.forEach((cam, i) => {
      console.log(`  [${i}] ${cam.label || 'Camera ' + i} (id: ${cam.deviceId.substring(0, 12)}...)`);
    });
    
    // Categorize by label heuristics
    backCameras = [];
    frontCameras = [];
    
    allCameras.forEach((cam, i) => {
      const label = (cam.label || '').toLowerCase();
      // Common patterns for front cameras
      if (label.includes('front') || label.includes('user') || label.includes('selfie') || label.includes('facetime')) {
        frontCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
      }
      // Common patterns for back cameras
      else if (label.includes('back') || label.includes('rear') || label.includes('environment') || label.includes('main') || label.includes('wide') || label.includes('tele') || label.includes('ultra')) {
        backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
      }
      // No label clue — use facingMode test or index heuristic
      else {
        if (allCameras.length === 1) {
          backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
        } else if (allCameras.length === 2) {
          // Classic 2-camera phone: index 0 = back, index 1 = front (usually)
          if (i === 0) {
            backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
          } else {
            frontCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
          }
        } else {
          // Multi-camera: try to detect facing by opening briefly
          // For now, add to back cameras (most multi-cam are back cameras)
          backCameras.push({ deviceId: cam.deviceId, label: cam.label, originalIndex: i });
        }
      }
    });

    // If labels were available and gave us no back cameras but we have unlabeled ones,
    // try facingMode-based detection
    if (backCameras.length === 0 && allCameras.length > 0) {
      await detectFacingByStream();
    }
    
    console.log(`📷 Back cameras: ${backCameras.length}, Front cameras: ${frontCameras.length}`);
    backCameras.forEach((cam, i) => {
      console.log(`  Back[${i}]: ${cam.label || 'Camera'}`);
    });
    frontCameras.forEach((cam, i) => {
      console.log(`  Front[${i}]: ${cam.label || 'Camera'}`);
    });
    
    return true;
  } catch (e) {
    console.error('❌ Camera enumeration failed:', e);
    return false;
  }
}

/**
 * Detect camera facing by briefly opening each camera and checking settings.facingMode
 */
async function detectFacingByStream() {
  console.log('📷 Detecting facing by opening each camera...');
  
  backCameras = [];
  frontCameras = [];
  
  for (const cam of allCameras) {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: cam.deviceId } },
        audio: false
      });
      const track = stream.getVideoTracks()[0];
      const settings = track.getSettings();
      stream.getTracks().forEach(t => t.stop());
      
      const entry = { deviceId: cam.deviceId, label: cam.label, originalIndex: allCameras.indexOf(cam) };
      
      if (settings.facingMode === 'environment') {
        backCameras.push(entry);
      } else if (settings.facingMode === 'user') {
        frontCameras.push(entry);
      } else {
        // Unknown, assume back
        backCameras.push(entry);
      }
      
      await new Promise(r => setTimeout(r, 100));
    } catch (e) {
      console.log(`  ⚠️ Could not test camera: ${e.message}`);
    }
  }
}

/**
 * Try to find the best back camera - the one with autofocus capability.
 * Tests each back camera and picks the one that supports continuous autofocus.
 */
async function findBestBackCamera() {
  if (backCameras.length <= 1) {
    console.log('📷 Only one back camera, using it');
    return backCameras.length === 1 ? 0 : -1;
  }
  
  // Check if user has a saved preference
  const savedId = localStorage.getItem(PREFERRED_CAMERA_KEY);
  if (savedId) {
    const savedIndex = backCameras.findIndex(c => c.deviceId === savedId);
    if (savedIndex !== -1) {
      console.log(`📷 Using saved preferred camera: index ${savedIndex}`);
      return savedIndex;
    }
  }
  
  console.log(`📷 Testing ${backCameras.length} back cameras to find best autofocus...`);
  
  let bestIndex = 0;
  let bestScore = -1;
  
  for (let i = 0; i < backCameras.length; i++) {
    const cam = backCameras[i];
    console.log(`📷 Testing back camera [${i}]: ${cam.label || 'Unknown'}...`);
    
    try {
      const testStream = await navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: cam.deviceId } },
        audio: false
      });
      
      const track = testStream.getVideoTracks()[0];
      const capabilities = track.getCapabilities ? track.getCapabilities() : {};
      const settings = track.getSettings();
      
      let score = 0;
      
      // Score based on focus capabilities
      if (capabilities.focusMode) {
        const modes = capabilities.focusMode;
        console.log(`  Focus modes: [${modes.join(', ')}]`);
        
        if (modes.includes('continuous')) score += 50;
        if (modes.includes('single-shot')) score += 30;
        if (modes.includes('manual')) score += 10;
      }
      
      // Score based on resolution (higher max = likely main camera, not ultrawide)
      if (capabilities.width && capabilities.width.max) {
        score += Math.min(capabilities.width.max / 100, 50);
        console.log(`  Max width: ${capabilities.width.max}`);
      }
      
      // Zoom support (main camera usually supports zoom)
      if (capabilities.zoom) {
        score += 20;
        console.log(`  Zoom: ${capabilities.zoom.min}-${capabilities.zoom.max}`);
      }
      
      // Torch support is a good sign (usually main camera)
      if (capabilities.torch) {
        score += 15;
        console.log(`  Torch: supported`);
      }
      
      // focusDistance available = autofocus hardware
      if (capabilities.focusDistance) {
        score += 25;
        console.log(`  Focus distance: ${capabilities.focusDistance.min}-${capabilities.focusDistance.max}`);
      }
      
      console.log(`  Total score: ${score}`);
      
      // Stop test stream
      testStream.getTracks().forEach(t => t.stop());
      
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
      
      await new Promise(r => setTimeout(r, 200));
      
    } catch (e) {
      console.log(`  ❌ Failed to test: ${e.message}`);
    }
  }
  
  console.log(`📷 Best back camera: index ${bestIndex} (score: ${bestScore})`);
  
  // Save preference
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

async function startCamera() {
  console.log('📷 Starting camera v7 (with camera selection)...');
  
  try {
    if (videoStream) {
      stopCamera();
    }
    
    videoElement = document.getElementById('videoElement');
    
    // First, get a temporary stream to trigger permission and enable enumeration with labels
    if (allCameras.length === 0) {
      let tempStream = null;
      try {
        tempStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
      } catch (e) {
        handleCameraError(e);
        return false;
      }
      
      // Now enumerate (labels should be available)
      await enumerateCameras();
      
      // Stop temp stream
      if (tempStream) {
        tempStream.getTracks().forEach(t => t.stop());
        await new Promise(r => setTimeout(r, 300));
      }
    }
    
    // Determine which camera list to use
    const cameraList = currentFacing === 'back' ? backCameras : frontCameras;
    
    if (cameraList.length === 0) {
      console.log('📷 No categorized cameras, falling back to facingMode');
      return await startCameraWithFacingMode();
    }
    
    // For back cameras, find the best one on first use
    if (currentFacing === 'back' && !currentDeviceId) {
      const bestIdx = await findBestBackCamera();
      if (bestIdx >= 0) {
        currentCameraIndex = bestIdx;
      }
    }
    
    // Clamp index
    if (currentCameraIndex >= cameraList.length) {
      currentCameraIndex = 0;
    }
    
    const selectedCamera = cameraList[currentCameraIndex];
    currentDeviceId = selectedCamera.deviceId;
    
    console.log(`📷 Opening: ${selectedCamera.label || 'Camera ' + currentCameraIndex} (${currentFacing} [${currentCameraIndex + 1}/${cameraList.length}])`);
    
    // Request with exact deviceId — this is the key fix
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
      console.log('⚠️ With ideal resolution failed, trying bare deviceId...');
      videoStream = await navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: currentDeviceId } },
        audio: false
      });
    }
    
    cameraTrack = videoStream.getVideoTracks()[0];
    const settings = cameraTrack.getSettings();
    const capabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    
    console.log('📷 Active settings:', JSON.stringify(settings));
    console.log('📷 Active capabilities:', JSON.stringify(capabilities));
    
    // Apply continuous autofocus if available
    await applyContinuousAutofocus();
    
    // Try ImageCapture
    try {
      if ('ImageCapture' in window) {
        imageCapture = new ImageCapture(cameraTrack);
        console.log('✅ ImageCapture available');
      }
    } catch (e) {
      imageCapture = null;
    }
    
    // Attach stream to video
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

/**
 * Apply continuous autofocus if the camera supports it.
 */
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
    } else {
      console.log('⚠️ No autofocus modes available on this camera');
    }
  } catch (e) {
    console.log('⚠️ Could not set focus mode:', e.message);
  }
}

/**
 * Fallback: start camera with just facingMode (old behavior)
 */
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

/**
 * Update the camera info badge in the UI
 */
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

// Tap to focus — trigger single-shot autofocus
async function triggerFocus() {
  console.log('👆 Focus tap');
  
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
  
  if (!cameraTrack) return;
  
  try {
    const capabilities = cameraTrack.getCapabilities ? cameraTrack.getCapabilities() : {};
    
    if (capabilities.focusMode && capabilities.focusMode.includes('single-shot')) {
      await cameraTrack.applyConstraints({
        advanced: [{ focusMode: 'single-shot' }]
      });
      console.log('🎯 Single-shot focus triggered');
      
      // Switch back to continuous after a short delay
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
  } catch (e) {
    console.log('⚠️ Focus trigger failed:', e.message);
  }
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

/**
 * Switch between front and back camera groups
 */
async function switchFacing() {
  console.log('🔄 Switching facing...');
  currentFacing = currentFacing === 'back' ? 'front' : 'back';
  currentCameraIndex = 0;
  currentDeviceId = null;
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 300));
  await startCamera();
}

/**
 * Cycle through cameras within the current facing group.
 * This is the KEY feature — lets user try different back cameras to find the one with good autofocus.
 */
async function cycleCamera() {
  const cameraList = currentFacing === 'back' ? backCameras : frontCameras;
  
  if (cameraList.length <= 1) {
    // Only one camera in this group, switch facing instead
    await switchFacing();
    return;
  }
  
  currentCameraIndex = (currentCameraIndex + 1) % cameraList.length;
  currentDeviceId = cameraList[currentCameraIndex].deviceId;
  
  console.log(`📷 Cycling to ${currentFacing} camera [${currentCameraIndex}]: ${cameraList[currentCameraIndex].label || 'Unknown'}`);
  
  // Save user's preference
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
      console.log('✅ Torch supported');
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
    console.log(`🔦 Torch ${torchEnabled ? 'ON' : 'OFF'}`);
    
  } catch (e) {
    console.error('❌ Torch error:', e);
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
  console.log('⏹️ Scanning stopped');
}

async function scanFrame() {
  if (!isScanning || !videoElement || videoElement.readyState !== 4) {
    return;
  }
  
  try {
    let barcodes = [];
    
    if (barcodeDetector) {
      barcodes = await barcodeDetector.detect(videoElement);
    }
    
    // If nothing found and we have ImageCapture, try from grabbed frame
    if (barcodes.length === 0 && imageCapture) {
      try {
        const frame = await imageCapture.grabFrame();
        if (frame && barcodeDetector) {
          barcodes = await barcodeDetector.detect(frame);
          frame.close();
        }
      } catch (e) {
        // Silently fail
      }
    }
    
    if (barcodes.length > 0) {
      handleBarcodeFound(barcodes[0]);
    }
    
  } catch (error) {
    // Silent fail for individual frames
  }
}

function handleBarcodeFound(barcode) {
  const code = barcode.rawValue || barcode.data;
  const format = barcode.format || 'unknown';
  
  if (code === lastScannedCode) return;
  
  lastScannedCode = code;
  console.log(`✅ Found: ${code} (${format})`);
  
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

// 📷 button: short tap = cycle cameras in same group, long press = switch front/back
switchCameraBtn.addEventListener('click', () => cycleCamera());

// RESTART button
restartCameraBtn.addEventListener('click', async () => {
  console.log('🔄 Restart camera button clicked');
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
  
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 500));
  await startCamera();
});

torchBtn.addEventListener('click', () => toggleTorch());

// TAP TO FOCUS
cameraContainer.addEventListener('click', () => triggerFocus());

copyBtn.addEventListener('click', () => {
  const code = barcodeNumber.textContent;
  if (code && code !== '--') copyToClipboard(code);
});

scanAgainBtn.addEventListener('click', () => scanAgain());

clearHistoryBtn.addEventListener('click', () => clearHistory());

// Long press on switch button to flip between front/back
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
  console.log('🚀 Barcode Scanner v7 - Camera Selection & Autofocus');
  
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

console.log('📜 barcode.js v7 loaded');
