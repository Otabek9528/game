// app.js — Main application controller (M5)
// Glues: Camera, Scanner, UI, I18N, Stores
// Wizard removed in M5. Store-scoped scanning preserved from M4.
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
  // STORE CONTEXT — read ?store=X from URL
  // ============================================
  const ALLOWED_STORES = ['No Brand', 'Emart24', '7-Eleven', 'GS25', 'CU', 'Daiso'];
  const EMBLEM_FILES = {
    'No Brand': 'nobrand.png', 'Emart24': 'emart24.png', '7-Eleven': '7_11.png',
    'GS25': 'gs25.png', 'CU': 'cu.png', 'Daiso': 'daiso.png'
  };
  let currentStore = null;
  (function _initStoreContext() {
    try {
      const qs = new URLSearchParams(window.location.search);
      const s = qs.get('store');
      if (s && ALLOWED_STORES.includes(s)) currentStore = s;
    } catch (e) {}
  })();

  // ============================================
  // BACK NAVIGATION — layered state machine
  // ============================================
  function _handleBackNavigation() {
    const modal = document.getElementById('productModal');
    if (modal && modal.style.display !== 'none') {
      UI.hideProductModal();
      return;
    }

    const ingredients = document.getElementById('ingredientsPanel');
    if (ingredients && ingredients.style.display === 'block') {
      ingredients.style.display = 'none';
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
    if (currentStore) {
      window.location.href = `store.html?id=${encodeURIComponent(currentStore)}`;
    } else {
      window.location.href = '../../index.html';
    }
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
      _renderScopedBanner();

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
    const formatName = Scanner.getFormatName(format);
    UI.updateStatus(t('bc.checking'), 'scanning');

    try {
      let url = `${API_BASE}/api/v2/product/${encodeURIComponent(code)}`;
      if (currentStore) url += `?store=${encodeURIComponent(currentStore)}`;

      const resp = await fetch(url);
      const data = await resp.json();

      if (data.found) {
        data.format = formatName;
        data._currentStore = currentStore;
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
  // SCOPED BANNER
  // ============================================
  function _renderScopedBanner() {
    const banner = document.getElementById('scopedBanner');
    if (!banner) return;
    if (!currentStore) {
      banner.style.display = 'none';
      return;
    }
    const emblem = document.getElementById('scopedBannerEmblem');
    const file = EMBLEM_FILES[currentStore];
    if (file) {
      emblem.src = `../../assets/stores/${file}`;
      emblem.style.display = '';
      emblem.onerror = () => { emblem.style.display = 'none'; };
    } else {
      emblem.style.display = 'none';
    }
    document.getElementById('scopedBannerStore').textContent = currentStore;
    banner.style.display = 'flex';
  }

  function _exitScopedScan() {
    if (!currentStore) return;
    window.location.href = `store.html?id=${encodeURIComponent(currentStore)}`;
  }

  // ============================================
  // LOGGING
  // ============================================
  function _logInteraction(action, barcode) {
    try {
      const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
      const suffix = currentStore ? `:${currentStore}` : '';
      fetch(`${API_BASE}/api/log-interaction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: tgUser ? String(tgUser.id) : 'unknown',
          username: tgUser?.username || 'unknown',
          action: `${action}:${barcode}${suffix}`
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

    if (currentStore) {
      const storesSection = document.getElementById('storesSection');
      const contribBanner = document.getElementById('contribBanner');
      if (storesSection) storesSection.style.display = 'none';
      if (contribBanner) contribBanner.style.display = 'none';
    }

    let perm = 'prompt';
    try { perm = (await navigator.permissions.query({ name: 'camera' })).state; }
    catch (e) {}

    if (perm === 'denied') {
      UI.showError(t('bc.errPermDenied'));
    } else if (perm === 'granted' || currentStore) {
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

    const scopedExit = document.getElementById('scopedBannerExit');
    if (scopedExit) scopedExit.addEventListener('click', _exitScopedScan);

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

    document.getElementById('fullscreenClose').addEventListener('click', () => UI.closeFullscreenImage());
    document.getElementById('fullscreenViewer').addEventListener('click', (e) => {
      if (e.target === document.getElementById('fullscreenViewer')) UI.closeFullscreenImage();
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
    getCurrentStore:   () => currentStore,
  };

})();