// app.js — Main application controller (M7)
// Glues: Camera, Scanner, UI, I18N, Stores
// M7: scoped scanning fully removed. Manual barcode entry added.
// ============================================

(function () {

  const tg = window.Telegram.WebApp;
  tg.ready();
  try { Telegram.WebApp.disableVerticalSwipes(); } catch (e) {}
  try { tg.expand(); } catch (e) {}
  try {
    if (tg.BackButton) {
      tg.BackButton.show();
      tg.BackButton.onClick(() => _handleBackNavigation());
    }
  } catch (e) {}

  // ============================================
  // BACK NAVIGATION — layered state machine
  // ============================================
  function _handleBackNavigation() {
    // Topmost layer first — fullscreen
    const viewer = document.getElementById('fullscreenViewer');
    if (viewer && viewer.classList.contains('active')) {
      UI.closeFullscreenImage();
      return;
    }

    const modal = document.getElementById('productModal');
    if (modal && modal.style.display !== 'none') {
      UI.hideProductModal();
      return;
    }

    const resultVisible = document.getElementById('resultSection').style.display !== 'none';
    const notFoundVisible = document.getElementById('notFoundSection').style.display !== 'none';
    if (resultVisible || notFoundVisible) {
      scanAgain();
      return;
    }

    Scanner.stop();
    Camera.destroy();
    window.location.href = '../../index.html';
  }

  // --- API base URL ---
  const API_BASE = window.location.hostname === 'localhost'
    ? 'http://localhost:5001'
    : 'https://vegukin-api.duckdns.org';

  window._API_BASE = API_BASE;

  // --- Current barcode state ---
  let currentBarcode = null;
  let currentFormat = null;

  // ============================================
  // CORE ACTIONS
  // ============================================

  async function openCameraAndScan() {
    UI.hideAllResults();
    UI.showScanBeam(true);

    try {
      const videoEl = UI.getVideoElement();
      const info = await Camera.open(videoEl);

      UI.updateCameraInfo(info.cameraIndex, info.totalCameras);
      UI.showTorch(info.hasTorch);
      UI.showSwitchBtn(info.hasMultipleCameras);
      UI.showState('scanner');

      startScanning();
    } catch (error) {
      _handleCameraError(error);
    }
  }

  function startScanning() {
    const videoEl = UI.getVideoElement();
    UI.updateStatus(t('bc.searching'), 'scanning');
    UI.showScanBeam(true);

    Scanner.start(videoEl, (code, format) => {
      currentBarcode = code;
      currentFormat = format;

      if (navigator.vibrate) navigator.vibrate([100, 50, 100]);
      UI.playSuccessSound();
      UI.updateStatus(t('bc.found'), 'found');
      UI.showScanBeam(false);

      lookupProduct(code, format);
    });
  }

  // ============================================
  // PRODUCT LOOKUP — unified v2 endpoint
  // ============================================
  async function lookupProduct(code, format) {
    const formatName = (format === 'manual')
      ? 'Manual'
      : Scanner.getFormatName(format);
    UI.updateStatus(t('bc.checking'), 'scanning');

    try {
      const url = `${API_BASE}/api/v2/product/${encodeURIComponent(code)}`;
      const resp = await fetch(url);
      const data = await resp.json();

      if (data.found) {
        data.format = formatName;
        UI.showProductResult(data);
        _logInteraction('scanner_found', code);
      } else {
        UI.showNotFound(code);
        _logInteraction('scanner_not_found', code);
      }
    } catch (err) {
      console.error('API lookup failed:', err);
      UI.showNotFound(code);
      _logInteraction('scanner_not_found', code);
    }
  }

  function scanAgain() {
    Scanner.resetLastScanned();
    UI.hideAllResults();
    UI.showScanBeam(true);
    openCameraAndScan();
  }

  async function cycleCamera() {
    Scanner.stop();
    try {
      const videoEl = UI.getVideoElement();
      const info = await Camera.cycle(videoEl);
      if (!info) return;
      UI.updateCameraInfo(info.cameraIndex, info.totalCameras);
      UI.showTorch(info.hasTorch);
      startScanning();
    } catch (e) {
      UI.showError(t('bc.errCameraSwitch'));
    }
  }

  async function restartCamera() {
    UI.flashFocusIndicator();
    Scanner.stop();
    Camera.destroy();
    await new Promise(r => setTimeout(r, 500));
    await openCameraAndScan();
  }

  async function toggleTorch() {
    const isOn = await Camera.toggleTorch();
    UI.updateTorchIcon(isOn);
  }

  function triggerFocus() {
    UI.flashFocusIndicator();
    Camera.triggerFocus();
  }

  function _handleCameraError(error) {
    if (error.message === 'NO_CAMERA') {
      UI.showError(t('bc.errNoCamera'));
    } else if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
      UI.showState('permission');
    } else if (error.name === 'NotFoundError') {
      UI.showError(t('bc.errNoCamera'));
    } else if (error.name === 'NotReadableError') {
      UI.showError(t('bc.errCameraBusy'));
    } else {
      UI.showError(t('bc.errCamera') + ': ' + error.message);
    }
  }

  // ============================================
  // MANUAL BARCODE ENTRY (M7)
  // ============================================
  // Validation: digits only, length 8–14, optional EAN-13/EAN-8/UPC-A checksum.
  function _validateManualBarcode(raw) {
    const code = (raw || '').trim();
    if (!code) {
      return { ok: false, reason: 'empty' };
    }
    if (!/^\d+$/.test(code)) {
      return { ok: false, reason: 'nondigit' };
    }
    if (code.length < 8 || code.length > 14) {
      return { ok: false, reason: 'length' };
    }
    // Checksum check for standard lengths
    if (code.length === 13 || code.length === 12 || code.length === 8) {
      if (!_isValidEanChecksum(code)) {
        return { ok: false, reason: 'checksum' };
      }
    }
    return { ok: true, code };
  }

  // EAN-13 / EAN-8 / UPC-A use mod-10 checksum on alternating weights.
  function _isValidEanChecksum(code) {
    const digits = code.split('').map(Number);
    const check = digits.pop();
    let sum = 0;
    // EAN-13 / UPC-A weighting: rightmost data digit weight 3, alternating
    for (let i = digits.length - 1, w = 3; i >= 0; i--, w = (w === 3 ? 1 : 3)) {
      sum += digits[i] * w;
    }
    const calc = (10 - (sum % 10)) % 10;
    return calc === check;
  }

  function _bindManualEntry(suffix) {
    const input = document.getElementById('manualBarcodeInput' + suffix);
    const btn   = document.getElementById('manualBarcodeBtn'   + suffix);
    const errEl = document.getElementById('manualBarcodeError' + suffix);
    if (!input || !btn || !errEl) return;

    function clearErr() {
      errEl.textContent = '';
      errEl.style.display = 'none';
      input.classList.remove('manual-entry__input--err');
    }
    function showErr(reason) {
      const map = {
        empty:    'bc.manual.errEmpty',
        nondigit: 'bc.manual.errNonDigit',
        length:   'bc.manual.errLength',
        checksum: 'bc.manual.errChecksum',
      };
      errEl.textContent = t(map[reason] || 'bc.manual.errInvalid');
      errEl.style.display = 'block';
      input.classList.add('manual-entry__input--err');
    }

    // Sanitize live (strip non-digits as user types)
    input.addEventListener('input', () => {
      const cleaned = input.value.replace(/\D+/g, '');
      if (cleaned !== input.value) input.value = cleaned;
      if (errEl.style.display === 'block') clearErr();
    });

    function submit() {
      const v = _validateManualBarcode(input.value);
      if (!v.ok) {
        showErr(v.reason);
        return;
      }
      clearErr();
      input.blur();
      try { Scanner.stop(); } catch (e) {}    // pause camera if it's running
      try { Camera.destroy(); } catch (e) {}  // release camera if held by permission state
      currentBarcode = v.code;
      currentFormat  = 'manual';
      // Reveal scanner display so result/notFound sections become visible
      UI.showState('scanner');
      UI.showScanBeam(false);
      // Hide viewfinder & status bar — no camera is running for manual lookup
      const vf = document.getElementById('viewfinderWrap');
      const sb = document.querySelector('.status-bar');
      if (vf) vf.style.display = 'none';
      if (sb) sb.style.display = 'none';
      lookupProduct(v.code, 'manual');
    }

    btn.addEventListener('click', submit);
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        submit();
      }
    });
  }

  // ============================================
  // LOGGING
  // ============================================
  function _logInteraction(action, barcode) {
    try {
      const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
      fetch(`${API_BASE}/api/log-interaction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: tgUser ? String(tgUser.id) : 'unknown',
          username: tgUser?.username || 'unknown',
          action: `${action}:${barcode}`
        })
      }).catch(() => {});
    } catch (e) {}
  }

  function applyI18n() { UI.applyTranslations(); }

  // ============================================
  // EVENT LISTENERS
  // ============================================
  document.addEventListener('DOMContentLoaded', async () => {
    if (window.I18N) I18N.init();
    applyI18n();

    await Scanner.init();

    if (window.Stores && typeof Stores.load === 'function') {
      try { Stores.load(); } catch (e) { console.error('Stores.load failed:', e); }
    }

    let perm = 'prompt';
    try { perm = (await navigator.permissions.query({ name: 'camera' })).state; }
    catch (e) {}

    if (perm === 'denied') {
      UI.showError(t('bc.errPermDenied'));
    } else if (perm === 'granted') {
      await openCameraAndScan();
    } else {
      UI.showState('permission');
    }

    document.getElementById('requestPermissionBtn').addEventListener('click', () => openCameraAndScan());
    document.getElementById('retryBtn').addEventListener('click', () => openCameraAndScan());

    document.getElementById('switchCameraBtn').addEventListener('click', () => cycleCamera());
    document.getElementById('restartCameraBtn').addEventListener('click', () => restartCamera());
    document.getElementById('torchBtn').addEventListener('click', () => toggleTorch());
    document.getElementById('cameraContainer').addEventListener('click', () => triggerFocus());

    document.getElementById('scanAgainBtn').addEventListener('click', () => scanAgain());
    document.getElementById('scanAgainBtn2').addEventListener('click', () => scanAgain());

    document.getElementById('copyBtn').addEventListener('click', () => {
      const code = document.getElementById('barcodeNumber').textContent;
      if (code && code !== '—') UI.copyToClipboard(code, tg);
    });

    document.getElementById('showIngredientsBtn').addEventListener('click', () => {
      const panel = document.getElementById('ingredientsPanel');
      panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
    });
    document.getElementById('closeIngredientsBtn').addEventListener('click', () => {
      document.getElementById('ingredientsPanel').style.display = 'none';
    });

    document.getElementById('modalCloseBtn').addEventListener('click', () => UI.hideProductModal());
    document.getElementById('modalBackdrop').addEventListener('click', () => UI.hideProductModal());

    // Manual barcode entry — three instances (permission view + scanner view + error view)
    _bindManualEntry('Perm');  // ids: manualBarcodeInputPerm / manualBarcodeBtnPerm / manualBarcodeErrorPerm
    _bindManualEntry('');      // ids: manualBarcodeInput / manualBarcodeBtn / manualBarcodeError
    _bindManualEntry('Err');   // ids: manualBarcodeInputErr / manualBarcodeBtnErr / manualBarcodeErrorErr

    document.addEventListener('visibilitychange', () => {
      const scannerVisible = document.getElementById('scannerDisplay').style.display === 'block';
      const resultVisible = document.getElementById('resultSection').style.display !== 'none';
      const notFoundVisible = document.getElementById('notFoundSection').style.display !== 'none';
      if (document.hidden) {
        Scanner.stop();
      } else if (scannerVisible && !resultVisible && !notFoundVisible) {
        startScanning();
      }
    });

    document.getElementById('productImage').addEventListener('click', () => {
      const src = document.getElementById('productImage').src;
      if (src) UI.openFullscreenImage(src);
    });

    document.getElementById('modalImg').addEventListener('click', () => {
      const src = document.getElementById('modalImg').src;
      if (src) UI.openFullscreenImage(src);
    });

    document.getElementById('fullscreenClose').addEventListener('click', () => {
      try { history.back(); } catch (e) { UI.closeFullscreenImage(); }
    });
    document.getElementById('fullscreenViewer').addEventListener('click', (e) => {
      if (e.target === document.getElementById('fullscreenViewer')) {
        try { history.back(); } catch (err) { UI.closeFullscreenImage(); }
      }
    });

    window.addEventListener('beforeunload', () => {
      Scanner.stop();
      Camera.destroy();
    });

    if (!history.state || history.state.page !== 'scanner') {
      try { history.replaceState({ page: 'scanner' }, ''); } catch (e) {}
    }
    let _handlingBack = false;
    window.addEventListener('popstate', () => {
      if (_handlingBack) return;
      _handlingBack = true;
      try { history.pushState({ page: 'scanner' }, ''); } catch (e) {}
      _handleBackNavigation();
      setTimeout(() => { _handlingBack = false; }, 100);
    });

    window.addEventListener('languageChanged', () => {
      applyI18n();
      if (window.Stores && typeof Stores.load === 'function') Stores.load();
    });
  });

  window.AppActions = {
    scanAgain, openCameraAndScan,
    getCurrentBarcode: () => currentBarcode,
  };

})();