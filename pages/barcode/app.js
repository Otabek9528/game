// app.js — Main application controller
// Glues: Camera, Scanner, UI, AddProduct
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
      tg.BackButton.onClick(() => {
        Scanner.stop();
        Camera.stop();
        window.location.href = '../../index.html';
      });
    }
  } catch (e) {}

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
      // Discover stays visible (it's outside scannerDisplay)

      startScanning();
    } catch (error) {
      _handleCameraError(error);
    }
  }

  function startScanning() {
    const videoEl = UI.getVideoElement();
    UI.updateStatus('Qidirilmoqda...', 'scanning');
    UI.showScanBeam(true);

    Scanner.start(videoEl, (code, format) => {
      currentBarcode = code;
      currentFormat = format;

      if (navigator.vibrate) navigator.vibrate([100, 50, 100]);
      UI.playSuccessSound();
      UI.updateStatus('Topildi!', 'found');
      UI.showScanBeam(false);
      UI.showDiscover(false);

      // For now, show as "not found" — real API lookup comes in Milestone 3
      lookupProduct(code, format);
    });
  }

  async function lookupProduct(code, format) {
    const formatName = Scanner.getFormatName(format);
    UI.updateStatus('Tekshirilmoqda...', 'scanning');

    try {
      const resp = await fetch(`/api/scanner/product/${encodeURIComponent(code)}`);
      const data = await resp.json();

      if (data.found) {
        data.format = formatName;
        UI.showProductResult(data);
      } else {
        UI.showNotFound(code);
      }
    } catch (err) {
      // Network error — show not found with the barcode
      console.error('API lookup failed:', err);
      UI.showNotFound(code);
    }
  }

  function scanAgain() {
    Scanner.resetLastScanned();
    UI.hideAllResults();
    UI.showScanBeam(true);
    UI.showDiscover(true);
    startScanning();
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
      UI.showError("Kamerani almashtirib bo'lmadi.");
    }
  }

  async function restartCamera() {
    UI.flashFocusIndicator();
    Scanner.stop();
    Camera.stop();
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
      UI.showError('Kamera topilmadi.');
    } else if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
      UI.showState('permission');
    } else if (error.name === 'NotFoundError') {
      UI.showError('Kamera topilmadi.');
    } else if (error.name === 'NotReadableError') {
      UI.showError('Kamera band. Boshqa ilovalarni yoping.');
    } else {
      UI.showError('Kamera xatoligi: ' + error.message);
    }
  }

  // ============================================
  // EVENT LISTENERS
  // ============================================

  document.addEventListener('DOMContentLoaded', async () => {
    await Scanner.init();

    // Check permission
    let perm = 'prompt';
    try { perm = (await navigator.permissions.query({ name: 'camera' })).state; }
    catch (e) {}

    if (perm === 'denied') {
      UI.showError('Kamera ruxsati berilmagan. Brauzer sozlamalaridan ruxsat bering.');
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

    // --- Add product button (Milestone 5) ---
    document.getElementById('addProductBtn').addEventListener('click', () => {
      // Will be implemented in Milestone 5
      if (tg.showAlert) tg.showAlert('Bu funksiya tez orada qo\'shiladi!');
    });

    // --- Wizard done button (Milestone 5) ---
    document.getElementById('wizardDoneBtn').addEventListener('click', () => scanAgain());

    // --- Modal close ---
    document.getElementById('modalCloseBtn').addEventListener('click', () => UI.hideProductModal());
    document.getElementById('modalBackdrop').addEventListener('click', () => UI.hideProductModal());

    // --- Mini-card clicks (discover section) ---
    document.querySelectorAll('.mini-card').forEach(card => {
      card.addEventListener('click', () => {
        const data = JSON.parse(card.getAttribute('data-product') || '{}');
        if (data.name) UI.showProductModal(data);
      });
    });

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

    window.addEventListener('beforeunload', () => {
      Scanner.stop();
      Camera.stop();
    });
  });

  // Expose scanAgain for other modules
  window.AppActions = { scanAgain, openCameraAndScan, getCurrentBarcode: () => currentBarcode };

})();
