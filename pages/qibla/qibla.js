// qibla.js - HIGHLY ACCURATE VERSION WITH MANDATORY CALIBRATION + I18N
// ============================================
// CONSTANTS
// ============================================

const MAKKAH_LAT = 21.4225;  // Kaaba latitude (precise)
const MAKKAH_LON = 39.8262;  // Kaaba longitude (precise)

const ALIGNMENT_THRESHOLD_PERFECT = 5;   // Perfect alignment (green)
const ALIGNMENT_THRESHOLD_CLOSE = 15;    // Close alignment (yellow)
const ALIGNMENT_THRESHOLD_MODERATE = 30; // Getting there

// Smoothing parameters - balanced for accuracy vs responsiveness
const SMOOTHING_FACTOR = 0.25;  // Higher = more responsive, lower = smoother
const HISTORY_SIZE = 7;         // Median filter window
const UPDATE_INTERVAL = 50;     // ms between UI updates

// Calibration settings
const CALIBRATION_DURATION = 5000;  // 5 seconds minimum calibration
const CALIBRATION_MOVEMENTS_REQUIRED = 8; // Number of significant movements needed

// ============================================
// I18N HELPER
// ============================================

function t(key, fallback) {
  if (window.I18N) {
    const trans = I18N.t(key);
    return trans !== key ? trans : fallback;
  }
  return fallback;
}

// ============================================
// STATE
// ============================================

let userLat = null;
let userLon = null;
let qiblaAngle = null;        // True bearing to Qibla from user location
let currentHeading = 0;        // Current device heading (true north)
let smoothedHeading = 0;
let isCompassAvailable = false;
let orientationPermissionGranted = false;
let lastUpdateTime = 0;
let headingHistory = [];
let magneticDeclination = 0;   // Will be calculated based on location
let isUsingTrueNorth = false;  // Track if we have true north or magnetic

// Calibration state
let isCalibrating = false;
let calibrationStartTime = 0;
let calibrationMovements = 0;
let lastCalibrationHeading = 0;
let calibrationComplete = false;

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
const calibrationState = document.getElementById('calibrationState');
const compassDisplay = document.getElementById('compassDisplay');

const requestPermissionBtn = document.getElementById('requestPermissionBtn');
const retryBtn = document.getElementById('retryBtn');
const recalibrateBtn = document.getElementById('recalibrateBtn');

const compassRose = document.getElementById('compassRose');
const qiblaPointer = document.getElementById('qiblaPointer');
const qiblaAngleElem = document.getElementById('qiblaAngleValue');
const headingAngleElem = document.getElementById('headingAngleValue');
const headingAngleTopElem = document.getElementById('headingAngleValueTop');
const distanceValue = document.getElementById('distanceValue');
const locationValue = document.getElementById('locationValue');
const compassQuality = document.getElementById('compassQuality');
const qualityText = document.getElementById('qualityText');
const alignmentStatus = document.getElementById('alignmentStatus');
const statusMessage = document.getElementById('statusMessage');
const statusEmoji = document.querySelector('.status-emoji');
const errorMessage = document.getElementById('errorMessage');
const differenceAngle = document.getElementById('differenceAngle');
const turnDirection = document.getElementById('turnDirection');

// Calibration elements
const progressFill = document.getElementById('progressFill');
const progressText = document.getElementById('progressText');

// ============================================
// MATHEMATICAL FUNCTIONS
// ============================================

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

function toDegrees(radians) {
  return radians * (180 / Math.PI);
}

function normalizeAngle(angle) {
  angle = angle % 360;
  if (angle < 0) angle += 360;
  return angle;
}

function signedAngleDifference(from, to) {
  let diff = to - from;
  while (diff > 180) diff -= 360;
  while (diff < -180) diff += 360;
  return diff;
}

function absoluteAngleDifference(angle1, angle2) {
  return Math.abs(signedAngleDifference(angle1, angle2));
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function calculateQiblaDirection(userLat, userLon) {
  const φ1 = toRadians(userLat);
  const φ2 = toRadians(MAKKAH_LAT);
  const Δλ = toRadians(MAKKAH_LON - userLon);
  
  const y = Math.sin(Δλ) * Math.cos(φ2);
  const x = Math.cos(φ1) * Math.sin(φ2) -
            Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);
  
  let bearing = toDegrees(Math.atan2(y, x));
  return normalizeAngle(bearing);
}

function estimateMagneticDeclination(lat, lon) {
  let declination = 0;
  
  if (lon > 100 && lon < 150 && lat > 30 && lat < 45) {
    declination = -8.5;
  } else if (lon > -10 && lon < 60 && lat > 20 && lat < 50) {
    declination = 3;
  } else if (lon > 60 && lon < 100 && lat > 20 && lat < 45) {
    declination = 0;
  }
  
  console.log(`📍 Estimated magnetic declination: ${declination}°`);
  return declination;
}

// ============================================
// SMOOTHING AND FILTERING
// ============================================

function getFilteredHeading(newHeading) {
  headingHistory.push(newHeading);
  if (headingHistory.length > HISTORY_SIZE) {
    headingHistory.shift();
  }
  
  if (headingHistory.length < 3) {
    return newHeading;
  }
  
  let sumSin = 0;
  let sumCos = 0;
  
  for (const h of headingHistory) {
    sumSin += Math.sin(toRadians(h));
    sumCos += Math.cos(toRadians(h));
  }
  
  return normalizeAngle(toDegrees(Math.atan2(sumSin, sumCos)));
}

function smoothAngle(newAngle, oldAngle, factor) {
  const diff = signedAngleDifference(oldAngle, newAngle);
  return normalizeAngle(oldAngle + diff * factor);
}

// ============================================
// UI STATE MANAGEMENT
// ============================================

function showState(state) {
  loadingState.style.display = 'none';
  permissionState.style.display = 'none';
  errorState.style.display = 'none';
  calibrationState.style.display = 'none';
  compassDisplay.style.display = 'none';
  
  switch(state) {
    case 'loading':
      loadingState.style.display = 'flex';
      break;
    case 'permission':
      permissionState.style.display = 'flex';
      break;
    case 'error':
      errorState.style.display = 'flex';
      break;
    case 'calibration':
      calibrationState.style.display = 'flex';
      startCalibration();
      break;
    case 'compass':
      compassDisplay.style.display = 'block';
      break;
  }
}

function showError(message) {
  errorMessage.textContent = message;
  showState('error');
}

// ============================================
// CALIBRATION FUNCTIONS (with I18N)
// ============================================

function startCalibration() {
  console.log('🔄 Starting calibration...');
  isCalibrating = true;
  calibrationStartTime = Date.now();
  calibrationMovements = 0;
  lastCalibrationHeading = 0;
  calibrationComplete = false;
  
  // Reset smoothing
  headingHistory = [];
  smoothedHeading = 0;
  
  // Update UI
  updateCalibrationProgress();
}

function updateCalibrationProgress() {
  if (!isCalibrating) return;
  
  const elapsed = Date.now() - calibrationStartTime;
  const timeProgress = Math.min(elapsed / CALIBRATION_DURATION, 1);
  const movementProgress = Math.min(calibrationMovements / CALIBRATION_MOVEMENTS_REQUIRED, 1);
  
  // Combined progress (both time and movements matter)
  const totalProgress = Math.min((timeProgress * 0.4 + movementProgress * 0.6), 1);
  
  if (progressFill) {
    progressFill.style.width = `${totalProgress * 100}%`;
  }
  
  if (progressText) {
    if (totalProgress < 0.3) {
      progressText.textContent = t('qibla.calibrateMove', 'Telefonni ∞ shaklida harakatlantiring...');
    } else if (totalProgress < 0.6) {
      progressText.textContent = t('qibla.calibrateGood', 'Yaxshi! Davom eting...');
    } else if (totalProgress < 1) {
      progressText.textContent = t('qibla.calibrateAlmost', 'Deyarli tayyor...');
    } else {
      progressText.textContent = t('qibla.calibrateDone', '✓ Kalibratsiya tayyor!');
      calibrationComplete = true;
      
      // AUTO-NAVIGATE: Automatically proceed to compass after short delay
      setTimeout(() => {
        if (calibrationComplete && isCalibrating) {
          finishCalibration();
        }
      }, 500);
    }
  }
  
}

function trackCalibrationMovement(heading) {
  if (!isCalibrating) return;
  
  const diff = absoluteAngleDifference(heading, lastCalibrationHeading);
  
  // Count significant movements (more than 30 degrees change)
  if (diff > 30) {
    calibrationMovements++;
    lastCalibrationHeading = heading;
    console.log(`📐 Calibration movement ${calibrationMovements}/${CALIBRATION_MOVEMENTS_REQUIRED}`);
  }
  
  updateCalibrationProgress();
}

function finishCalibration() {
  console.log('✅ Calibration finished');
  isCalibrating = false;
  calibrationComplete = true;
  
  // Reset smoothing for fresh start
  headingHistory = [];
  
  // Show compass
  showState('compass');
}

// ============================================
// LOCATION HANDLING (with I18N)
// ============================================

async function initializeLocation() {
  console.log('🌍 Initializing location...');
  
  const location = LocationManager.getCurrentLocation();
  
  if (location && location.lat && location.lon) {
    console.log('✅ Location found:', location);
    userLat = location.lat;
    userLon = location.lon;
    
    qiblaAngle = calculateQiblaDirection(userLat, userLon);
    const distance = calculateDistance(userLat, userLon, MAKKAH_LAT, MAKKAH_LON);
    magneticDeclination = estimateMagneticDeclination(userLat, userLon);
    
    if (distanceValue) {
      distanceValue.textContent = `${Math.round(distance).toLocaleString()} km`;
    }
    if (locationValue) {
      locationValue.textContent = location.city || t('qibla.unknown', 'Noma\'lum');
    }
    if (qiblaAngleElem) {
      qiblaAngleElem.textContent = `${Math.round(qiblaAngle)}°`;
    }
    
    console.log(`🕋 Qibla bearing: ${qiblaAngle.toFixed(1)}°`);
    console.log(`📏 Distance to Makkah: ${Math.round(distance)} km`);
    
    return true;
  } else {
    console.error('❌ Location not available');
    showError(t('qibla.locationError', 'Joylashuvni aniqlab bo\'lmadi. Iltimos, brauzerda joylashuvni yoqing va sahifani yangilang.'));
    return false;
  }
}

// ============================================
// COMPASS HANDLING (with I18N)
// ============================================

function checkOrientationSupport() {
  return 'DeviceOrientationEvent' in window;
}

async function requestOrientationPermission() {
  console.log('🔐 Requesting orientation permission...');
  
  if (typeof DeviceOrientationEvent !== 'undefined' && 
      typeof DeviceOrientationEvent.requestPermission === 'function') {
    try {
      const permission = await DeviceOrientationEvent.requestPermission();
      if (permission === 'granted') {
        console.log('✅ Orientation permission granted');
        orientationPermissionGranted = true;
        return true;
      } else {
        console.log('❌ Orientation permission denied');
        showError(t('qibla.permissionDenied', 'Kompas ruxsati berilmadi. Iltimos, Safari sozlamalaridan ruxsat bering.'));
        return false;
      }
    } catch (error) {
      console.error('❌ Error requesting permission:', error);
      showError(t('qibla.permissionError', 'Kompas ruxsatini so\'rashda xatolik yuz berdi.'));
      return false;
    }
  } else {
    console.log('✅ Orientation permission not required (Android/Desktop)');
    orientationPermissionGranted = true;
    return true;
  }
}

function initializeCompass() {
  console.log('🧭 Initializing compass...');
  
  if (!checkOrientationSupport()) {
    console.error('❌ DeviceOrientation API not supported');
    showError(t('qibla.noCompass', 'Bu qurilmada kompas mavjud emas.'));
    return false;
  }
  
  if ('ondeviceorientationabsolute' in window) {
    window.addEventListener('deviceorientationabsolute', handleOrientation, true);
    isUsingTrueNorth = true;
    console.log('✅ Using deviceorientationabsolute (true north)');
  } else {
    window.addEventListener('deviceorientation', handleOrientation, true);
    isUsingTrueNorth = false;
    console.log('✅ Using deviceorientation (may be magnetic north)');
  }
  
  isCompassAvailable = true;
  return true;
}

function handleOrientation(event) {
  let heading = null;
  
  if (event.webkitCompassHeading !== undefined && event.webkitCompassHeading !== null) {
    heading = event.webkitCompassHeading;
    isUsingTrueNorth = true;
  }
  else if (event.alpha !== null && event.alpha !== undefined) {
    if (event.absolute === true) {
      heading = normalizeAngle(360 - event.alpha);
      isUsingTrueNorth = true;
    } else {
      heading = normalizeAngle(360 - event.alpha);
      isUsingTrueNorth = false;
    }
  }
  
  if (heading === null) {
    return;
  }
  
  // Apply magnetic declination correction if needed
  if (!isUsingTrueNorth && magneticDeclination !== 0) {
    heading = normalizeAngle(heading + magneticDeclination);
  }
  
  // Track calibration movements
  if (isCalibrating) {
    trackCalibrationMovement(heading);
  }
  
  // Apply filtering
  const filteredHeading = getFilteredHeading(heading);
  
  // Apply smoothing
  smoothedHeading = smoothAngle(filteredHeading, smoothedHeading, SMOOTHING_FACTOR);
  currentHeading = smoothedHeading;
  
  // Throttle UI updates
  const now = Date.now();
  if (now - lastUpdateTime < UPDATE_INTERVAL) {
    return;
  }
  lastUpdateTime = now;
  
  // Update compass display (only if not calibrating)
  if (!isCalibrating && calibrationComplete) {
    updateCompassDisplay(currentHeading);
  }
  
  // Update quality indicator
  updateCompassQuality(event);
}

function updateCompassQuality(event) {
  const accuracy = event.webkitCompassAccuracy;
  const dots = compassQuality ? compassQuality.querySelectorAll('.dot') : [];
  
  let activeDots = 3;
  let qualityLevel = t('qibla.qualityGood', 'Yaxshi');
  
  if (accuracy !== undefined && accuracy !== null) {
    if (accuracy < 10) {
      activeDots = 4;
      qualityLevel = t('qibla.qualityExcellent', 'A\'lo');
    } else if (accuracy < 20) {
      activeDots = 3;
      qualityLevel = t('qibla.qualityGood', 'Yaxshi');
    } else if (accuracy < 35) {
      activeDots = 2;
      qualityLevel = t('qibla.qualityMedium', 'O\'rtacha');
    } else {
      activeDots = 1;
      qualityLevel = t('qibla.qualityPoor', 'Yomon');
    }
  }
  
  dots.forEach((dot, index) => {
    dot.classList.toggle('active', index < activeDots);
  });
  
  if (qualityText) {
    qualityText.textContent = qualityLevel;
  }
}

function updateCompassDisplay(heading) {
  if (qiblaAngle === null) return;
  
  const diff = signedAngleDifference(heading, qiblaAngle);
  const absDiff = Math.abs(diff);
  
  // Rotate the compass rose
  if (compassRose) {
    compassRose.style.transform = `rotate(${-heading}deg)`;
  }
  
  // Rotate Qibla pointer
  if (qiblaPointer) {
    qiblaPointer.style.transform = `rotate(${diff}deg)`;
  }
  
  // Update heading display (CENTER OF COMPASS)
  if (headingAngleElem) {
    headingAngleElem.textContent = `${Math.round(heading)}°`;
  }
  
  // Update heading in top card too
  if (headingAngleTopElem) {
    headingAngleTopElem.textContent = `${Math.round(heading)}°`;
  }
  
  // Update difference display
  if (differenceAngle) {
    differenceAngle.textContent = `${Math.round(absDiff)}`;
  }
  
  // Update turn direction indicator
  if (turnDirection) {
    if (absDiff <= ALIGNMENT_THRESHOLD_PERFECT) {
      turnDirection.textContent = '✓';
      turnDirection.className = 'turn-indicator aligned';
    } else if (diff > 0) {
      turnDirection.textContent = '➡️';
      turnDirection.className = 'turn-indicator turn-right';
    } else {
      turnDirection.textContent = '⬅️';
      turnDirection.className = 'turn-indicator turn-left';
    }
  }
  
  // Update alignment status
  updateAlignmentStatus(absDiff, diff);
}

function updateAlignmentStatus(absDiff, signedDiff) {
  const statusIndicator = document.getElementById('statusIndicator');
  const turnInstructionTop = document.querySelector('.turn-instruction-top');
  
  if (absDiff <= ALIGNMENT_THRESHOLD_PERFECT) {
    if (statusMessage) {
      statusMessage.textContent = t('qibla.aligned', 'Qiblaga to\'g\'ri yuzlangansiz!');
      statusMessage.className = 'status-message aligned';
    }
    if (statusEmoji) statusEmoji.textContent = '✅';
    if (statusIndicator) statusIndicator.className = 'status-indicator aligned';
    if (turnInstructionTop) turnInstructionTop.classList.add('aligned');
    
    if (navigator.vibrate && !window.hasVibrated) {
      navigator.vibrate(100);
      window.hasVibrated = true;
    }
  } else if (absDiff <= ALIGNMENT_THRESHOLD_CLOSE) {
    const direction = signedDiff > 0 ? t('qibla.right', 'o\'ngga') : t('qibla.left', 'chapga');
    if (statusMessage) {
      statusMessage.textContent = `${t('qibla.turnSlightly', 'Biroz')} ${direction} ${t('qibla.turn', 'buriling')}`;
      statusMessage.className = 'status-message close';
    }
    if (statusEmoji) statusEmoji.textContent = '🎯';
    if (statusIndicator) statusIndicator.className = 'status-indicator close';
    if (turnInstructionTop) turnInstructionTop.classList.remove('aligned');
    window.hasVibrated = false;
  } else if (absDiff <= ALIGNMENT_THRESHOLD_MODERATE) {
    const direction = signedDiff > 0 ? t('qibla.rightCap', 'O\'ngga') : t('qibla.leftCap', 'Chapga');
    if (statusMessage) {
      statusMessage.textContent = `${direction} ${t('qibla.turn', 'buriling')}`;
      statusMessage.className = 'status-message moderate';
    }
    if (statusEmoji) statusEmoji.textContent = '↻';
    if (statusIndicator) statusIndicator.className = 'status-indicator moderate';
    if (turnInstructionTop) turnInstructionTop.classList.remove('aligned');
    window.hasVibrated = false;
  } else {
    const direction = signedDiff > 0 ? t('qibla.right', 'o\'ngga') : t('qibla.left', 'chapga');
    if (statusMessage) {
      statusMessage.textContent = `${Math.round(absDiff)}° ${direction} ${t('qibla.turn', 'buriling')}`;
      statusMessage.className = 'status-message';
    }
    if (statusEmoji) statusEmoji.textContent = '🧭';
    if (statusIndicator) statusIndicator.className = 'status-indicator';
    if (turnInstructionTop) turnInstructionTop.classList.remove('aligned');
    window.hasVibrated = false;
  }
}

// ============================================
// EVENT LISTENERS
// ============================================

if (requestPermissionBtn) {
  requestPermissionBtn.addEventListener('click', async () => {
    console.log('🖱️ Permission button clicked');
    const granted = await requestOrientationPermission();
    
    if (granted) {
      const compassInit = initializeCompass();
      if (compassInit) {
        // Go to calibration state (MANDATORY)
        showState('calibration');
      }
    }
  });
}

if (retryBtn) {
  retryBtn.addEventListener('click', () => {
    console.log('🔄 Retry button clicked');
    headingHistory = [];
    smoothedHeading = 0;
    calibrationComplete = false;
    initializeApp();
  });
}

if (recalibrateBtn) {
  recalibrateBtn.addEventListener('click', () => {
    console.log('🔄 Recalibrate button clicked');
    calibrationComplete = false;
    headingHistory = [];
    smoothedHeading = 0;
    showState('calibration');
  });
}

// ============================================
// I18N UI UPDATE
// ============================================

function updateUITranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (window.I18N) {
      const trans = I18N.t(key);
      if (trans !== key) {
        // Use innerHTML for content with HTML tags, textContent otherwise
        if (trans.includes('<') && trans.includes('>')) {
          el.innerHTML = trans;
        } else {
          el.textContent = trans;
        }
      }
    }
  });
}

// Listen for language changes
window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

// ============================================
// INITIALIZATION
// ============================================

async function initializeApp() {
  console.log('🚀 Initializing Qibla Finder (with Mandatory Calibration)...');
  
  showState('loading');
  
  // Update UI translations
  updateUITranslations();
  
  // Reset state
  smoothedHeading = 0;
  headingHistory = [];
  window.hasVibrated = false;
  calibrationComplete = false;
  isCalibrating = false;
  
  // Initialize location first
  const locationOk = await initializeLocation();
  if (!locationOk) {
    return;
  }
  
  // Check compass support
  if (!checkOrientationSupport()) {
    showError(t('qibla.noCompassSensor', 'Bu qurilmada kompas sensori mavjud emas.'));
    return;
  }
  
  // Check if permission is needed (iOS)
  if (typeof DeviceOrientationEvent !== 'undefined' && 
      typeof DeviceOrientationEvent.requestPermission === 'function') {
    console.log('📱 iOS detected - permission required');
    showState('permission');
  } else {
    console.log('🤖 Android/Desktop detected - no permission needed');
    const compassInit = initializeCompass();
    
    if (compassInit) {
      // Go to calibration (MANDATORY)
      showState('calibration');
    }
  }
}

// Start when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  console.log('📄 DOM loaded');
  initializeApp();
});

// Listen for location updates
window.addEventListener('locationUpdated', (event) => {
  console.log('🌍 Location updated:', event.detail);
  userLat = event.detail.lat;
  userLon = event.detail.lon;
  
  qiblaAngle = calculateQiblaDirection(userLat, userLon);
  magneticDeclination = estimateMagneticDeclination(userLat, userLon);
  
  const distance = calculateDistance(userLat, userLon, MAKKAH_LAT, MAKKAH_LON);
  
  if (distanceValue) {
    distanceValue.textContent = `${Math.round(distance).toLocaleString()} km`;
  }
  if (locationValue) {
    locationValue.textContent = event.detail.city || t('qibla.unknown', 'Noma\'lum');
  }
  if (qiblaAngleElem) {
    qiblaAngleElem.textContent = `${Math.round(qiblaAngle)}°`;
  }
});

// Handle page visibility
document.addEventListener('visibilitychange', () => {
  if (!document.hidden) {
    console.log('▶️ Page visible - resetting smoothing');
    headingHistory = [];
  }
});

console.log('📜 Qibla.js loaded - WITH MANDATORY CALIBRATION + I18N');