// qibla.js - ACCURACY-CORRECTED VERSION
// Changes vs previous version:
//  1. Magnetic declination is now ALWAYS applied. webkitCompassHeading (iOS) and
//     deviceorientationabsolute (Android) both report MAGNETIC north, not true north
//     (Apple docs: "measured in degrees relative to magnetic north"). The old code
//     skipped correction for both, causing ~9° systematic error in Korea.
//  2. Declination comes from the WMM2025 model (wmm.bundle.js, NOAA coefficients,
//     <0.5° accuracy worldwide) instead of a 3-bucket lookup table. Falls back to a
//     corrected table if the bundle fails to load.
//  3. Negative webkitCompassAccuracy (= sensor invalid/uncalibrated) no longer reads
//     as "Excellent" quality; it now forces poor quality + recalibration hint.
//  4. Calibration completion is gated on measured heading STABILITY (and on iOS,
//     on webkitCompassAccuracy being valid and < 15°), not just elapsed time + waving.
//  5. Tilt detection: beyond ~35° tilt the quality score degrades and the user is
//     told to hold the phone flat. (Note: 360-alpha is already the correct azimuth
//     of the device top edge at any tilt; the problem at high tilt is sensor fusion
//     quality, not the formula.)
//  6. Screen-orientation offset applied (defensive; Telegram webview is portrait).
//  7. Debug/measurement overlay: open with ?debug=1 or 7 taps on the title.
//     Shows raw vs corrected heading, declination, source, accuracy; REC button
//     records 3s of samples and reports mean error vs an entered reference azimuth.
//
// IOS DOUBLE-CORRECTION CHECK (do once per iOS major version):
//  Apple documents webkitCompassHeading as MAGNETIC north, so we apply declination.
//  If a future iOS silently returns true north, we would over-correct by ~9° in Korea.
//  Verify: open ?debug=1, compare "corrected" heading against the native Compass app
//  with Settings > Compass > "Use True North" ON. If corrected differs from native
//  by ≈ declination, set APPLY_DECLINATION_WEBKIT = false below.
const APPLY_DECLINATION_WEBKIT = true;

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
const HISTORY_SIZE = 7;         // Circular-mean filter window
const UPDATE_INTERVAL = 50;     // ms between UI updates

// Calibration settings
const CALIBRATION_DURATION = 5000;        // 5 seconds minimum calibration
const CALIBRATION_MOVEMENTS_REQUIRED = 8; // Number of significant movements needed
const STABILITY_WINDOW_MS = 1200;         // Hold-steady phase duration
const STABILITY_MAX_STD_DEG = 2.5;        // Max circular std-dev to pass stability
const IOS_ACCURACY_GATE = 15;             // webkitCompassAccuracy must be < this (deg)
const ACCURACY_STUCK_REVERT_MS = 2500;    // Stable but accuracy still bad → back to waving

// Conditional calibration: silent quality check on open. Calibration screen only
// shows when the sensor actually needs it (recalibrate button still forces it).
const QUICK_CHECK_TIMEOUT = 2000;         // ms to decide before defaulting to calibration
const QUICK_CHECK_MIN_SAMPLES = 8;        // sliding window size for jitter test

// Tilt handling
const TILT_WARN_DEG = 35;                 // Beyond this, warn + degrade quality

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
let currentHeading = 0;       // Current device heading (after declination = true north)
let smoothedHeading = 0;
let isCompassAvailable = false;
let orientationPermissionGranted = false;
let lastUpdateTime = 0;
let headingHistory = [];
let magneticDeclination = 0;       // degrees, +East. true = magnetic + declination
let declinationSource = 'none';    // 'wmm' | 'fallback' | 'none'
let headingSource = 'none';        // 'webkit' | 'absolute' | 'relative'

// Sensor diagnostics
let lastRawHeading = null;         // heading before declination, after screen offset
let lastWebkitAccuracy = null;     // webkitCompassAccuracy (iOS only), may be < 0
let lastTiltDeg = 0;               // max(|beta|, |gamma|)
let sensorInvalid = false;         // true when iOS reports negative accuracy

// Calibration state
let isCalibrating = false;
let calibrationStartTime = 0;
let calibrationMovements = 0;
let lastCalibrationHeading = 0;
let calibrationComplete = false;
let stabilityBuffer = [];          // {t, h} samples for hold-steady phase
let inStabilityPhase = false;
let holdAccuracyFailSince = 0;     // for reverting to movement phase when iOS accuracy stays bad

// Quick quality check state
let isQuickChecking = false;
let quickCheckSamples = [];
let quickCheckEvaluate = null;     // set while a check is running

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

// Calibration elements (two-phase UI)
const progressText = document.getElementById('progressText');
const calVisualMove = document.getElementById('calVisualMove');
const calVisualHold = document.getElementById('calVisualHold');
const calDescription = document.getElementById('calDescription');
const calPips = document.getElementById('calPips');
const calPipsWrap = document.getElementById('calPipsWrap');
const pipsCount = document.getElementById('pipsCount');
const stabilityRing = document.getElementById('stabilityRing');
const levelBubble = document.getElementById('levelBubble');
const RING_CIRCUMFERENCE = 389.6; // 2π × r62, matches the SVG

// Build the movement pips once
if (calPips) {
  for (let i = 0; i < CALIBRATION_MOVEMENTS_REQUIRED; i++) {
    const pip = document.createElement('span');
    pip.className = 'cal-pip';
    calPips.appendChild(pip);
  }
}

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

// Circular mean and standard deviation (degrees) of a list of headings.
// std is derived from the resultant length R: std = sqrt(-2 ln R).
function circularStats(angles) {
  if (!angles.length) return { mean: 0, std: Infinity };
  let sumSin = 0, sumCos = 0;
  for (const a of angles) {
    sumSin += Math.sin(toRadians(a));
    sumCos += Math.cos(toRadians(a));
  }
  const n = angles.length;
  const R = Math.sqrt(sumSin * sumSin + sumCos * sumCos) / n;
  const mean = normalizeAngle(toDegrees(Math.atan2(sumSin, sumCos)));
  const std = R >= 1 ? 0 : toDegrees(Math.sqrt(-2 * Math.log(Math.max(R, 1e-12))));
  return { mean, std };
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

// ============================================
// MAGNETIC DECLINATION (WMM2025 with fallback)
// ============================================

function getDeclination(lat, lon) {
  // Primary: NOAA World Magnetic Model 2025 (bundled, offline, <0.5° error)
  if (window.geomagnetism) {
    try {
      const model = window.geomagnetism.model(new Date(), { allowOutOfBoundsModel: true });
      const info = model.point([lat, lon]);
      declinationSource = 'wmm';
      console.log(`📍 WMM declination: ${info.decl.toFixed(2)}°`);
      return info.decl;
    } catch (e) {
      console.warn('WMM model failed, using fallback table:', e);
    }
  }

  // Fallback: coarse regional table (only used if wmm.bundle.js failed to load).
  // Values approximate 2026 epoch.
  declinationSource = 'fallback';
  let declination = 0;
  if (lon > 120 && lon < 150 && lat > 30 && lat < 45) {
    declination = -9;      // Korea / Japan
  } else if (lon > 55 && lon < 75 && lat > 35 && lat < 46) {
    declination = 5.7;     // Uzbekistan / Central Asia (was wrongly 0 before)
  } else if (lon > -10 && lon < 55 && lat > 15 && lat < 50) {
    declination = 3;       // Europe / Middle East (very rough)
  }
  console.log(`📍 Fallback declination: ${declination}°`);
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

  return circularStats(headingHistory).mean;
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
// CALIBRATION (movement phase + stability gate)
// ============================================

function startCalibration() {
  console.log('🔄 Starting calibration...');
  isCalibrating = true;
  calibrationStartTime = Date.now();
  calibrationMovements = 0;
  lastCalibrationHeading = 0;
  calibrationComplete = false;
  inStabilityPhase = false;
  stabilityBuffer = [];
  holdAccuracyFailSince = 0;

  // Reset smoothing
  headingHistory = [];
  smoothedHeading = 0;

  setCalibrationPhaseUI('move');
  updatePips();
  updateStabilityRing(0);
  updateCalibrationProgress();
}

function setCalibrationPhaseUI(phase) {
  if (calibrationState) {
    calibrationState.classList.toggle('phase-move', phase === 'move');
    calibrationState.classList.toggle('phase-hold', phase === 'hold');
  }
  if (calVisualMove) calVisualMove.style.display = phase === 'move' ? 'block' : 'none';
  if (calVisualHold) calVisualHold.style.display = phase === 'hold' ? 'block' : 'none';
  if (calPipsWrap) calPipsWrap.style.display = phase === 'move' ? 'flex' : 'none';
  if (calDescription) {
    calDescription.innerHTML = phase === 'move'
      ? t('qibla.calibrateDescMove', 'Telefonni bilakni burab <strong>∞</strong> shaklida aylantiring — faqat surmang.')
      : t('qibla.calibrateDescHold', 'Pufakchani markazda ushlab, qimirlamay turing.');
  }
}

function updatePips() {
  if (!calPips) return;
  const pips = calPips.children;
  for (let i = 0; i < pips.length; i++) {
    pips[i].classList.toggle('filled', i < calibrationMovements);
  }
  if (pipsCount) pipsCount.textContent = Math.min(calibrationMovements, CALIBRATION_MOVEMENTS_REQUIRED);
}

function updateStabilityRing(p) {
  if (!stabilityRing) return;
  stabilityRing.setAttribute('stroke-dashoffset', (RING_CIRCUMFERENCE * (1 - p)).toFixed(1));
}

// Driven by live beta/gamma from handleOrientation during the hold phase.
function updateLevelBubble(beta, gamma) {
  if (!levelBubble) return;
  const clamp = (v, m) => Math.max(-m, Math.min(m, v));
  const x = clamp(gamma, 30) / 30 * 26;
  const y = clamp(beta, 30) / 30 * 26;
  levelBubble.setAttribute('transform', `translate(${x.toFixed(1)},${y.toFixed(1)})`);
  levelBubble.classList.toggle('centered', Math.hypot(x, y) <= 8);
}

function enterStabilityPhase() {
  inStabilityPhase = true;
  stabilityBuffer = [];
  holdAccuracyFailSince = 0;
  setCalibrationPhaseUI('hold');
  if (progressText) {
    progressText.textContent = t('qibla.calibrateHoldStill', 'Endi telefonni tekis ushlab, qimirlatmang...');
  }
  console.log('🧘 Entering stability phase');
}

// iOS edge case: the user held still but the OS still reports bad accuracy —
// holding still won't fix that, more waving might. Send them back to phase 1
// with partial credit instead of letting the ring sit frozen.
function revertToMovementPhase() {
  inStabilityPhase = false;
  stabilityBuffer = [];
  holdAccuracyFailSince = 0;
  calibrationMovements = Math.max(0, CALIBRATION_MOVEMENTS_REQUIRED - 4);
  setCalibrationPhaseUI('move');
  updatePips();
  updateStabilityRing(0);
  if (progressText) {
    progressText.textContent = t('qibla.calibrateMoreMoves', 'Sensor hali tayyor emas — yana ∞ harakat qiling');
  }
  console.log('↩️ Accuracy still poor, back to movement phase');
}

function updateCalibrationProgress() {
  if (!isCalibrating) return;

  if (!inStabilityPhase) {
    const elapsed = Date.now() - calibrationStartTime;
    const timeProgress = Math.min(elapsed / CALIBRATION_DURATION, 1);
    const movementProgress = Math.min(calibrationMovements / CALIBRATION_MOVEMENTS_REQUIRED, 1);
    const movementPhaseProgress = Math.min(timeProgress * 0.4 + movementProgress * 0.6, 1);

    if (movementPhaseProgress >= 1) {
      enterStabilityPhase();
    } else if (progressText) {
      progressText.textContent = movementProgress < 0.5
        ? t('qibla.calibrateMove', 'Telefonni ∞ shaklida harakatlantiring...')
        : t('qibla.calibrateGood', 'Yaxshi! Davom eting...');
    }
    return;
  }

  // Stability phase
  const s = stabilityStatus();
  updateStabilityRing(s.progress);

  if (s.progress >= 1) {
    if (progressText) {
      progressText.textContent = t('qibla.calibrateDone', '✓ Kalibratsiya tayyor!');
    }
    if (!calibrationComplete) {
      calibrationComplete = true;
      setTimeout(() => {
        if (calibrationComplete && isCalibrating) {
          finishCalibration();
        }
      }, 500);
    }
    return;
  }

  // Stuck-accuracy detection (iOS only: stable + flat but OS says uncalibrated)
  if (s.stable && s.tiltOk && !s.accuracyOk) {
    if (!holdAccuracyFailSince) holdAccuracyFailSince = Date.now();
    if (Date.now() - holdAccuracyFailSince > ACCURACY_STUCK_REVERT_MS) {
      revertToMovementPhase();
      return;
    }
  } else {
    holdAccuracyFailSince = 0;
  }

  if (progressText) {
    if (!s.tiltOk) {
      progressText.textContent = t('qibla.holdFlatShort', 'Telefonni tekis ushlang');
    } else if (!s.stable) {
      progressText.textContent = t('qibla.calibrateHoldStill', 'Endi telefonni tekis ushlab, qimirlatmang...');
    } else {
      progressText.textContent = t('qibla.calibrateChecking', 'Barqarorlik tekshirilmoqda...');
    }
  }
}

// Stability gate: heading must be steady (low circular std) for the full window,
// the device roughly flat, and — on iOS — the OS-reported accuracy valid and good.
function stabilityStatus() {
  const now = Date.now();
  stabilityBuffer = stabilityBuffer.filter(s => now - s.t <= STABILITY_WINDOW_MS);

  const accuracyOk =
    lastWebkitAccuracy === null ||
    (lastWebkitAccuracy >= 0 && lastWebkitAccuracy < IOS_ACCURACY_GATE);
  const tiltOk = lastTiltDeg < TILT_WARN_DEG;

  if (stabilityBuffer.length < 5) {
    return { progress: 0, stable: false, accuracyOk, tiltOk };
  }

  const windowSpan = now - stabilityBuffer[0].t;
  const { std } = circularStats(stabilityBuffer.map(s => s.h));
  const stable = std <= STABILITY_MAX_STD_DEG;

  // Headroom (150 ms) because windowSpan is measured between discrete samples
  // and can never quite reach the full window — without it, progress asymptotes
  // at ~98% and completion never fires.
  const effectiveWindow = STABILITY_WINDOW_MS - 150;

  let progress;
  if (!stable || !tiltOk) {
    progress = Math.min(0.4, windowSpan / effectiveWindow * 0.4);
  } else if (!accuracyOk) {
    progress = 0.5;
  } else {
    progress = Math.min(windowSpan / effectiveWindow, 1);
  }

  return { progress, stable, accuracyOk, tiltOk };
}

function trackCalibrationMovement(heading) {
  if (!isCalibrating) return;

  if (inStabilityPhase) {
    stabilityBuffer.push({ t: Date.now(), h: heading });
  } else {
    const diff = absoluteAngleDifference(heading, lastCalibrationHeading);
    if (diff > 30) {
      calibrationMovements++;
      lastCalibrationHeading = heading;
      updatePips();
      console.log(`📐 Calibration movement ${calibrationMovements}/${CALIBRATION_MOVEMENTS_REQUIRED}`);
    }
  }

  updateCalibrationProgress();
}

function finishCalibration() {
  console.log('✅ Calibration finished');
  isCalibrating = false;
  calibrationComplete = true;
  headingHistory = [];
  showState('compass');
}

// ============================================
// QUICK QUALITY CHECK (conditional calibration)
// ============================================
// Runs silently behind the loading state. Passes → straight to compass.
// Fails or times out → calibration screen. The recalibrate button always
// forces the full calibration flow regardless.

function runQuickQualityCheck() {
  return new Promise((resolve) => {
    console.log('⚡ Running quick sensor quality check...');
    isQuickChecking = true;
    quickCheckSamples = [];

    const finish = (ok, reason) => {
      if (!isQuickChecking) return;
      isQuickChecking = false;
      quickCheckEvaluate = null;
      clearTimeout(timer);
      console.log(`⚡ Quick check ${ok ? 'PASS' : 'FAIL'} (${reason})`);
      resolve(ok);
    };

    const timer = setTimeout(() => finish(false, 'timeout'), QUICK_CHECK_TIMEOUT);

    quickCheckEvaluate = (heading) => {
      if (sensorInvalid) {
        return finish(false, 'sensor reports invalid');
      }

      // iOS: the OS accuracy field is authoritative — trust it either way.
      if (lastWebkitAccuracy !== null) {
        if (lastWebkitAccuracy >= 0 && lastWebkitAccuracy < IOS_ACCURACY_GATE) {
          return finish(true, `webkitCompassAccuracy=${lastWebkitAccuracy}`);
        }
        if (quickCheckSamples.length >= QUICK_CHECK_MIN_SAMPLES) {
          return finish(false, `webkitCompassAccuracy=${lastWebkitAccuracy}`);
        }
        quickCheckSamples.push(heading);
        return;
      }

      // Android: no accuracy signal — pass if any sliding window of recent
      // headings is steady (low circular std) while the device is fairly flat.
      quickCheckSamples.push(heading);
      if (quickCheckSamples.length < QUICK_CHECK_MIN_SAMPLES) return;

      const windowSamples = quickCheckSamples.slice(-QUICK_CHECK_MIN_SAMPLES);
      const { std } = circularStats(windowSamples);
      if (std <= STABILITY_MAX_STD_DEG && lastTiltDeg < TILT_WARN_DEG) {
        finish(true, `std=${std.toFixed(2)}°`);
      }
    };
  });
}

// Shared post-init routing for both platforms.
async function routeAfterCompassInit() {
  const ok = await runQuickQualityCheck();
  if (ok) {
    calibrationComplete = true;
    headingHistory = [];
    showState('compass');
  } else {
    showState('calibration');
  }
}

// ============================================
// LOCATION HANDLING
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
    magneticDeclination = getDeclination(userLat, userLon);

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
// COMPASS HANDLING
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
    console.log('✅ Using deviceorientationabsolute (magnetic north; declination will be applied)');
  } else {
    window.addEventListener('deviceorientation', handleOrientation, true);
    console.log('✅ Using deviceorientation');
  }

  isCompassAvailable = true;
  return true;
}

function getScreenAngle() {
  if (screen.orientation && typeof screen.orientation.angle === 'number') {
    return screen.orientation.angle;
  }
  if (typeof window.orientation === 'number') {
    return window.orientation;
  }
  return 0;
}

function handleOrientation(event) {
  let heading = null;
  let applyDeclination = false;

  if (event.webkitCompassHeading !== undefined && event.webkitCompassHeading !== null) {
    // iOS: tilt-compensated heading relative to MAGNETIC north (per Apple docs).
    heading = event.webkitCompassHeading;
    headingSource = 'webkit';
    applyDeclination = APPLY_DECLINATION_WEBKIT;
    lastWebkitAccuracy = (event.webkitCompassAccuracy !== undefined)
      ? event.webkitCompassAccuracy : null;
    sensorInvalid = (lastWebkitAccuracy !== null && lastWebkitAccuracy < 0);
  }
  else if (event.alpha !== null && event.alpha !== undefined) {
    // alpha: rotation about z, 0 = device top facing north (in absolute frame).
    // 360 - alpha is the azimuth of the device top edge at any tilt, given a
    // correctly fused absolute alpha. Reference: MAGNETIC north on Android.
    heading = normalizeAngle(360 - event.alpha);
    if (event.absolute === true || headingSourceIsAbsoluteListener()) {
      headingSource = 'absolute';
      applyDeclination = true;
    } else {
      // Non-absolute alpha is relative to an arbitrary start orientation —
      // it is NOT a compass. Show it (better than nothing) but mark invalid
      // so quality reads poor and the user isn't given false confidence.
      headingSource = 'relative';
      applyDeclination = true; // harmless constant offset on garbage data
      sensorInvalid = true;
    }
  }

  if (heading === null) {
    return;
  }

  // Compensate for screen rotation (portrait-locked webview → normally 0).
  const screenAngle = getScreenAngle();
  if (screenAngle) {
    heading = normalizeAngle(heading + screenAngle);
  }

  lastRawHeading = heading;

  // Magnetic → true north correction. This is the fix for the ~9° Korea error:
  // the old code only applied this when it (wrongly) believed it already had
  // true north, which was every device, so it never ran.
  if (applyDeclination && magneticDeclination !== 0) {
    heading = normalizeAngle(heading + magneticDeclination);
  }

  // Tilt tracking (sensor fusion degrades and 'top edge azimuth' loses meaning
  // as the device approaches vertical).
  if (event.beta !== null && event.gamma !== null &&
      event.beta !== undefined && event.gamma !== undefined) {
    lastTiltDeg = Math.max(Math.abs(event.beta), Math.abs(event.gamma));

    // Live spirit level during the hold-still phase
    if (isCalibrating && inStabilityPhase) {
      updateLevelBubble(event.beta, event.gamma);
    }
  }

  // Feed the silent quality check (conditional calibration)
  if (isQuickChecking && quickCheckEvaluate) {
    quickCheckEvaluate(heading);
  }

  // Track calibration movements
  if (isCalibrating) {
    trackCalibrationMovement(heading);
  }

  // Apply filtering
  const filteredHeading = getFilteredHeading(heading);

  // Apply smoothing (seed EMA from first real sample — starting at 0° creates a
  // transient bias of up to several degrees right when the compass appears)
  if (headingHistory.length === 1) {
    smoothedHeading = filteredHeading;
  }
  smoothedHeading = smoothAngle(filteredHeading, smoothedHeading, SMOOTHING_FACTOR);
  currentHeading = smoothedHeading;

  // Debug overlay gets unthrottled data
  if (window.__qiblaDebug) {
    window.__qiblaDebug.onSample({
      raw: lastRawHeading,
      corrected: heading,
      smoothed: currentHeading,
      source: headingSource,
      decl: magneticDeclination,
      declSource: declinationSource,
      accuracy: lastWebkitAccuracy,
      tilt: lastTiltDeg,
      qibla: qiblaAngle
    });
  }

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
  updateCompassQuality();
}

// ============================================
// QUALITY INDICATOR
// ============================================
// iOS: webkitCompassAccuracy (negative = INVALID, not excellent!).
// Android: no accuracy field exists, so estimate from the circular spread of
// recent headings (jitter proxy). Both are degraded by excessive tilt.

function updateCompassQuality() {
  const dots = compassQuality ? compassQuality.querySelectorAll('.dot') : [];

  let activeDots;
  let qualityLevel;

  if (sensorInvalid) {
    // Negative iOS accuracy or non-absolute alpha: heading can't be trusted.
    activeDots = 1;
    qualityLevel = t('qibla.qualityCalibrate', 'Kalibratsiya kerak');
  } else if (lastWebkitAccuracy !== null) {
    const accuracy = lastWebkitAccuracy;
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
  } else {
    // Android: jitter-based estimate from the filter window.
    const { std } = circularStats(headingHistory);
    if (headingHistory.length < HISTORY_SIZE) {
      activeDots = 2;
      qualityLevel = t('qibla.qualityMedium', 'O\'rtacha');
    } else if (std < 1.5) {
      activeDots = 4;
      qualityLevel = t('qibla.qualityExcellent', 'A\'lo');
    } else if (std < 4) {
      activeDots = 3;
      qualityLevel = t('qibla.qualityGood', 'Yaxshi');
    } else if (std < 10) {
      activeDots = 2;
      qualityLevel = t('qibla.qualityMedium', 'O\'rtacha');
    } else {
      activeDots = 1;
      qualityLevel = t('qibla.qualityPoor', 'Yomon');
    }
  }

  // Excessive tilt caps the score.
  if (lastTiltDeg > TILT_WARN_DEG && activeDots > 2) {
    activeDots = 2;
    qualityLevel = t('qibla.holdFlatShort', 'Telefonni tekis ushlang');
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
// DEBUG / MEASUREMENT OVERLAY
// Open with ?debug=1 or 7 taps on the page title.
// REC: records 3 s of corrected headings, shows mean ± std, and — if you enter
// a reference azimuth (e.g. sun azimuth or landmark bearing) — the mean error.
// ============================================

function initDebugOverlay() {
  const params = new URLSearchParams(window.location.search);
  let tapCount = 0;
  const title = document.querySelector('.qibla-title');
  if (title) {
    title.addEventListener('click', () => {
      tapCount++;
      if (tapCount >= 7) createDebugOverlay();
    });
  }
  if (params.get('debug') === '1') createDebugOverlay();
}

function createDebugOverlay() {
  if (window.__qiblaDebug) return;

  const box = document.createElement('div');
  box.style.cssText = 'position:fixed;bottom:0;left:0;right:0;z-index:9999;' +
    'background:rgba(0,0,0,0.85);color:#0f0;font:11px/1.5 monospace;' +
    'padding:8px;max-height:45vh;overflow:auto;';
  box.innerHTML =
    '<div id="dbgLive"></div>' +
    '<div style="margin-top:6px;">' +
    'ref az: <input id="dbgRef" type="number" step="0.1" style="width:70px;font:11px monospace;"> ' +
    '<button id="dbgRec" style="font:11px monospace;">REC 3s</button> ' +
    '<button id="dbgClose" style="font:11px monospace;">✕</button>' +
    '</div>' +
    '<div id="dbgResult"></div>';
  document.body.appendChild(box);

  const live = box.querySelector('#dbgLive');
  const result = box.querySelector('#dbgResult');
  let recording = false;
  let recSamples = [];

  window.__qiblaDebug = {
    onSample(s) {
      if (recording) recSamples.push(s.corrected);
      live.innerHTML =
        `src: ${s.source} | decl: ${s.decl.toFixed(2)}° (${s.declSource})<br>` +
        `raw(mag): ${s.raw !== null ? s.raw.toFixed(1) : '--'}° → corrected(true): ${s.corrected.toFixed(1)}° → smoothed: ${s.smoothed.toFixed(1)}°<br>` +
        `webkitAccuracy: ${s.accuracy === null ? 'n/a' : s.accuracy} | tilt: ${s.tilt.toFixed(0)}° | qibla: ${s.qibla === null ? '--' : s.qibla.toFixed(2)}°`;
    }
  };

  box.querySelector('#dbgRec').addEventListener('click', () => {
    recSamples = [];
    recording = true;
    result.textContent = 'recording...';
    setTimeout(() => {
      recording = false;
      const { mean, std } = circularStats(recSamples);
      const refVal = parseFloat(box.querySelector('#dbgRef').value);
      let line = `n=${recSamples.length} mean=${mean.toFixed(2)}° std=${std.toFixed(2)}°`;
      if (!isNaN(refVal)) {
        line += ` | error vs ref: ${signedAngleDifference(refVal, mean).toFixed(2)}°`;
      }
      result.textContent = line;
      console.log('🎯 REC result:', line);
    }, 3000);
  });

  box.querySelector('#dbgClose').addEventListener('click', () => {
    box.remove();
    window.__qiblaDebug = null;
  });
}

// ============================================
// EVENT LISTENERS
// ============================================

// Helper: did we attach the absolute listener? (Chrome Android fires
// deviceorientationabsolute with absolute=true, but be defensive.)
let attachedAbsoluteListener = ('ondeviceorientationabsolute' in window);
function headingSourceIsAbsoluteListener() {
  return attachedAbsoluteListener;
}

if (requestPermissionBtn) {
  requestPermissionBtn.addEventListener('click', async () => {
    console.log('🖱️ Permission button clicked');
    const granted = await requestOrientationPermission();

    if (granted) {
      const compassInit = initializeCompass();
      if (compassInit) {
        showState('loading');
        routeAfterCompassInit();
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
        if (trans.includes('<') && trans.includes('>')) {
          el.innerHTML = trans;
        } else {
          el.textContent = trans;
        }
      }
    }
  });
}

window.addEventListener('languageChanged', () => {
  updateUITranslations();
});

// ============================================
// INITIALIZATION
// ============================================

async function initializeApp() {
  console.log('🚀 Initializing Qibla Finder (WMM declination + gated calibration)...');

  showState('loading');
  updateUITranslations();
  initDebugOverlay();

  // Reset state
  smoothedHeading = 0;
  headingHistory = [];
  window.hasVibrated = false;
  calibrationComplete = false;
  isCalibrating = false;
  sensorInvalid = false;

  const locationOk = await initializeLocation();
  if (!locationOk) {
    return;
  }

  if (!checkOrientationSupport()) {
    showError(t('qibla.noCompassSensor', 'Bu qurilmada kompas sensori mavjud emas.'));
    return;
  }

  if (typeof DeviceOrientationEvent !== 'undefined' &&
      typeof DeviceOrientationEvent.requestPermission === 'function') {
    console.log('📱 iOS detected - permission required');
    showState('permission');
  } else {
    console.log('🤖 Android/Desktop detected - no permission needed');
    const compassInit = initializeCompass();

    if (compassInit) {
      // Conditional calibration: only show the calibration screen if the
      // silent quality check fails. Recalibrate button still forces it.
      routeAfterCompassInit();
    }
  }
}

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
  magneticDeclination = getDeclination(userLat, userLon);

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
