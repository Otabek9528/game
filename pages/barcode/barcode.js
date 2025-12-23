// barcode.js - Barcode Scanner for Telegram WebApp
// VERSION 6: Minimal - No Focus Settings, Let Camera Use Defaults
// ============================================
// CONSTANTS
// ============================================

const SCAN_INTERVAL = 200; // ms between scan attempts
const HISTORY_MAX_ITEMS = 10;
const HISTORY_STORAGE_KEY = 'barcode_scan_history';

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
let currentCamera = 'environment';
let torchEnabled = false;
let lastScannedCode = null;
let barcodeDetector = null;
let scanHistory = [];
let cameraTrack = null;
let imageCapture = null;

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
// CAMERA FUNCTIONS - WebView Optimized
// ============================================

async function checkCameraPermission() {
  try {
    const permission = await navigator.permissions.query({ name: 'camera' });
    return permission.state;
  } catch (e) {
    return 'prompt';
  }
}

// KEY CHANGE: Use lower resolution and specific constraints that work better in WebView
function getWebViewOptimizedConstraints() {
  return {
    video: {
      facingMode: currentCamera
    },
    audio: false
  };
}

// Fallback constraints
function getSimpleConstraints() {
  return {
    video: {
      facingMode: currentCamera
    },
    audio: false
  };
}

async function startCamera() {
  console.log('📷 Starting camera (WebView optimized)...');
  
  try {
    if (videoStream) {
      stopCamera();
    }
    
    videoElement = document.getElementById('videoElement');
    
    // Try optimized constraints first
    let constraints = getWebViewOptimizedConstraints();
    console.log('📷 Trying optimized constraints:', constraints);
    
    try {
      videoStream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      console.log('⚠️ Optimized constraints failed, trying simple...');
      constraints = getSimpleConstraints();
      videoStream = await navigator.mediaDevices.getUserMedia(constraints);
    }
    
    cameraTrack = videoStream.getVideoTracks()[0];
    
    // Log what we got
    const settings = cameraTrack.getSettings();
    console.log('📷 Camera settings:', settings);
    
    // Try to create ImageCapture for focus control
    try {
      if ('ImageCapture' in window) {
        imageCapture = new ImageCapture(cameraTrack);
        console.log('✅ ImageCapture API available');
        
        // Get photo capabilities
        const capabilities = await imageCapture.getPhotoCapabilities();
        console.log('📷 Photo capabilities:', capabilities);
      }
    } catch (e) {
      console.log('⚠️ ImageCapture not available:', e);
      imageCapture = null;
    }
    
    // Attach stream to video
    videoElement.srcObject = videoStream;
    
    // Wait for video to be ready
    await new Promise((resolve, reject) => {
      videoElement.onloadedmetadata = () => {
        videoElement.play()
          .then(resolve)
          .catch(reject);
      };
      videoElement.onerror = reject;
    });
    
    console.log(`✅ Camera started: ${settings.width}x${settings.height}`);
    
    // Check torch
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

function handleCameraError(error) {
  if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
    showState('permission');
  } else if (error.name === 'NotFoundError') {
    showError('Kamera topilmadi.');
  } else if (error.name === 'NotReadableError') {
    showError('Kamera band. Boshqa ilovalarni yoping.');
  } else if (error.name === 'OverconstrainedError') {
    // Try with very simple constraints
    startCameraBasic();
  } else {
    showError(`Kamera xatoligi: ${error.message}`);
  }
}

async function startCameraBasic() {
  console.log('📷 Trying basic camera...');
  try {
    videoStream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: false
    });
    
    cameraTrack = videoStream.getVideoTracks()[0];
    videoElement = document.getElementById('videoElement');
    videoElement.srcObject = videoStream;
    
    await new Promise(resolve => {
      videoElement.onloadedmetadata = () => {
        videoElement.play().then(resolve);
      };
    });
    
    showState('scanner');
    startScanning();
    
  } catch (e) {
    showError('Kameraga ulanib bo\'lmadi.');
  }
}

// Focus settings removed - let camera use defaults

// Use ImageCapture to grab focused frame
async function grabFocusedFrame() {
  if (!imageCapture) return null;
  
  try {
    // grabFrame() or takePhoto() can trigger autofocus on some devices
    const bitmap = await imageCapture.grabFrame();
    console.log('🎯 Grabbed frame via ImageCapture');
    return bitmap;
  } catch (e) {
    console.log('⚠️ grabFrame failed:', e.message);
    return null;
  }
}

// Tap to focus - disabled, let camera handle it
async function triggerFocus() {
  console.log('👆 Focus tap (no action - using camera defaults)');
  
  // Show indicator only
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
}

// Restart camera stream (can help reset focus)
async function restartCameraStream() {
  console.log('🔄 Restarting camera stream...');
  
  const wasScanning = isScanning;
  stopScanning();
  
  if (videoStream) {
    videoStream.getTracks().forEach(t => t.stop());
  }
  
  // Small delay
  await new Promise(r => setTimeout(r, 300));
  
  // Restart
  await startCamera();
  
  if (wasScanning) {
    startScanning();
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

async function switchCamera() {
  console.log('🔄 Switching camera...');
  currentCamera = currentCamera === 'environment' ? 'user' : 'environment';
  stopScanning();
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
    
    // Try scanning from video directly
    if (barcodeDetector) {
      barcodes = await barcodeDetector.detect(videoElement);
    }
    
    // If nothing found and we have ImageCapture, try from grabbed frame
    if (barcodes.length === 0 && imageCapture) {
      try {
        const frame = await imageCapture.grabFrame();
        if (frame && barcodeDetector) {
          barcodes = await barcodeDetector.detect(frame);
          frame.close(); // Clean up
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
  
  // Feedback
  if (navigator.vibrate) {
    navigator.vibrate([100, 50, 100]);
  }
  playSuccessSound();
  
  // Update UI
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
    // Fallback
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

switchCameraBtn.addEventListener('click', () => switchCamera());

// RESTART CAMERA - helps reset focus
restartCameraBtn.addEventListener('click', async () => {
  console.log('🔄 Restart camera button clicked');
  focusIndicator.classList.add('active');
  setTimeout(() => focusIndicator.classList.remove('active'), 600);
  
  stopScanning();
  stopCamera();
  await new Promise(r => setTimeout(r, 500)); // Wait a bit
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
  console.log('🚀 Barcode Scanner v6 - Minimal, No Focus Manipulation');
  
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

console.log('📜 barcode.js v6 loaded');