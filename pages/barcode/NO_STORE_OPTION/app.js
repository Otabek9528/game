// app.js — Main application controller
// Glues: Camera, Scanner, UI, AddProduct, I18N
// Handles: Telegram init, event binding, orchestration
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

    const wizard = document.getElementById('addProductWizard');
    if (wizard && wizard.style.display !== 'none') {
      const currentStep = AddProduct.getCurrentStep();
      if (currentStep === '3b') {
        scanAgain();
      } else if (currentStep == 3) {
        return;
      } else if (currentStep == 2) {
        AddProduct.goToStep('1b');
      } else if (currentStep === '1b') {
        AddProduct.retake();
      } else if (currentStep == 1) {
        AddProduct.cancel();
      }
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
      UI.showDiscover(false);

      lookupProduct(code, format);
    });
  }

  async function lookupProduct(code, format) {
    const formatName = Scanner.getFormatName(format);
    UI.updateStatus(t('bc.checking'), 'scanning');

    try {
      const resp = await fetch(`${API_BASE}/api/scanner/product/${encodeURIComponent(code)}`);
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
    UI.showDiscover(true);
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
  // DISCOVER
  // ============================================

  async function loadDiscover() {
    try {
      const resp = await fetch(`${API_BASE}/api/scanner/discover?count=10`);
      const data = await resp.json();

      const tagMap = {
        halol:    { cls: 'joiz',        textKey: 'bc.badgeJoiz' },
        shubhali: { cls: 'shubhali',    textKey: 'bc.badgeShubhali' },
        harom:    { cls: 'taqiqlangan',  textKey: 'bc.badgeTaqiqlangan' }
      };

      ['halol', 'shubhali', 'harom'].forEach(verdict => {
        const container = document.getElementById('discover' + verdict.charAt(0).toUpperCase() + verdict.slice(1));
        const products = data[verdict] || [];
        if (products.length === 0) {
          container.innerHTML = '<p class="discover__loading">—</p>';
          return;
        }
        container.innerHTML = '';
        products.forEach(p => {
          let imgSrc = p.image || '';
          if (imgSrc && imgSrc.startsWith('/api/')) imgSrc = API_BASE + imgSrc;

          const tag = tagMap[verdict];
          const card = document.createElement('div');
          card.className = 'mini-card';
          card.setAttribute('data-product', JSON.stringify(p));
          card.innerHTML = `<img class="mini-card__img" src="${imgSrc}" alt="" loading="lazy"><div class="mini-card__body"><p class="mini-card__name">${_escHtml(p.name)}</p><span class="mini-card__tag mini-card__tag--${tag.cls}">${t(tag.textKey)}</span></div>`;
          card.addEventListener('click', () => UI.showProductModal(p));
          container.appendChild(card);
        });
      });
    } catch (e) {
      console.error('Discover fetch failed:', e);
    }
  }

  function _escHtml(s) {
    const d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
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

  // ============================================
  // i18n — apply translations to static DOM
  // ============================================
  function applyI18n() {
    UI.applyTranslations();
  }

  // ============================================
  // EVENT LISTENERS
  // ============================================

  document.addEventListener('DOMContentLoaded', async () => {
    // Init i18n and apply translations
    if (window.I18N) I18N.init();
    applyI18n();

    await Scanner.init();

    loadDiscover();

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

    // --- Permission & error buttons ---
    document.getElementById('requestPermissionBtn').addEventListener('click', () => openCameraAndScan());
    document.getElementById('retryBtn').addEventListener('click', () => openCameraAndScan());

    // --- Viewfinder controls ---
    document.getElementById('switchCameraBtn').addEventListener('click', () => cycleCamera());
    document.getElementById('restartCameraBtn').addEventListener('click', () => restartCamera());
    document.getElementById('torchBtn').addEventListener('click', () => toggleTorch());
    document.getElementById('cameraContainer').addEventListener('click', () => triggerFocus());

    // --- Scan again buttons ---
    document.getElementById('scanAgainBtn').addEventListener('click', () => scanAgain());
    document.getElementById('scanAgainBtn2').addEventListener('click', () => scanAgain());

    // --- Copy barcode ---
    document.getElementById('copyBtn').addEventListener('click', () => {
      const code = document.getElementById('barcodeNumber').textContent;
      if (code && code !== '—') UI.copyToClipboard(code, tg);
    });

    // --- Ingredients toggle ---
    document.getElementById('showIngredientsBtn').addEventListener('click', () => {
      const panel = document.getElementById('ingredientsPanel');
      panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
    });
    document.getElementById('closeIngredientsBtn').addEventListener('click', () => {
      document.getElementById('ingredientsPanel').style.display = 'none';
    });

    // --- Add product button ---
    document.getElementById('addProductBtn').addEventListener('click', () => {
      const bc = currentBarcode || document.getElementById('notFoundBarcode').textContent;
      if (bc) AddProduct.start(bc);
    });

    // --- Wizard done button ---
    document.getElementById('wizardDoneBtn').addEventListener('click', () => scanAgain());

    // --- Init Add Product wizard ---
    AddProduct.init();

    // --- Modal close ---
    document.getElementById('modalCloseBtn').addEventListener('click', () => UI.hideProductModal());
    document.getElementById('modalBackdrop').addEventListener('click', () => UI.hideProductModal());

    // --- Visibility change ---
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
    
    // --- Fullscreen image viewer ---
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

    // --- Browser / Android hardware back button ---
    _pushState('scanner');
    window.addEventListener('popstate', (e) => {
      _pushState('back');
      _handleBackNavigation();
    });

    // --- Language change listener ---
    window.addEventListener('languageChanged', () => {
      applyI18n();
      loadDiscover(); // Reload with new labels
    });
  });

  function _pushState(label) {
    history.pushState({ page: label }, '', '');
  }

  // Expose scanAgain for other modules
  window.AppActions = { scanAgain, openCameraAndScan, getCurrentBarcode: () => currentBarcode };

})();
