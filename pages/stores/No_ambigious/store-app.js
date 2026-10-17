// ============================================
// store-app.js — Main application controller
// Glues: Camera, Scanner, StoreUI, StoreForm, StoreSubmissions
// Handles: Telegram init, API base, state orchestration, back nav
// ============================================

(function () {

  // ============================================
  // TELEGRAM WEBAPP
  // ============================================
  const tg = window.Telegram && window.Telegram.WebApp;
  let tgUserId = '';
  if (tg) {
    try { tg.ready(); } catch (e) {}
    try { tg.expand(); } catch (e) {}
    try { tg.disableVerticalSwipes && tg.disableVerticalSwipes(); } catch (e) {}
    try {
      const u = tg.initDataUnsafe && tg.initDataUnsafe.user;
      if (u && u.id) tgUserId = String(u.id);
    } catch (e) {}
    try {
      if (tg.BackButton) {
        tg.BackButton.show();
        tg.BackButton.onClick(() => _handleBack());
      }
    } catch (e) {}
  }

  // ============================================
  // API BASE
  // ============================================
  const API_BASE = (window.location.hostname === 'localhost' ||
                    window.location.hostname === '127.0.0.1')
    ? 'http://localhost:5001'
    : 'https://vegukin-api.duckdns.org';
  window._SC_API_BASE = API_BASE;

  // ============================================
  // APP STATE
  // ============================================
  let selectedStore = null;
  let lastBarcode = null;
  let lastScannedAt = 0;

  // ============================================
  // CONNECTION WATCHER
  // ============================================
  function _applyConnectionState(online) {
    const banner = document.getElementById('offlineBanner');
    if (banner) banner.style.display = online ? 'none' : 'flex';

    // Disable form/edit submits while offline
    const submit = document.getElementById('formSubmitBtn');
    const save   = document.getElementById('editSaveBtn');
    if (submit) submit.dataset.offline = online ? '' : '1';
    if (save)   save.dataset.offline   = online ? '' : '1';
    // Re-evaluate submit gate if possible
    if (!online) {
      if (submit) submit.disabled = true;
      if (save)   save.disabled   = true;
    }
  }

  if (window.StoreUtils) {
    StoreUtils.onConnectionChange(_applyConnectionState);
  }

  // ============================================
  // FLOW
  // ============================================
  function goStorePicker() {
    _stopScanner();
    _stopCamera();
    selectedStore = null;
    StoreUI.setSelectedStoreCard(null);
    StoreUI.showState('stateStorePicker');
  }

  function goPermission() {
    _stopScanner();
    StoreUI.setSelectedStoreLabels(selectedStore);
    StoreUI.showState('statePermission');
  }

  async function startScanning() {
    StoreUI.setSelectedStoreLabels(selectedStore);
    StoreUI.showState('stateScanner');
    StoreUI.updateStatus("Kamera ochilmoqda…", 'scanning');
    StoreUI.showScanBeam(true);

    try {
      const videoEl = StoreUI.els().videoElement;
      const info = await Camera.open(videoEl);
      StoreUI.showTorch(info.hasTorch);
      StoreUI.showSwitchCam(info.hasMultipleCameras);

      // Init detector if not ready yet
      if (Scanner.init) { try { await Scanner.init(); } catch (e) {} }
      StoreUI.updateStatus("Shtrix-kod qidirilmoqda…", 'scanning');

      Scanner.start(videoEl, _onBarcodeFound);
    } catch (e) {
      console.error('Camera.open failed:', e);
      StoreUI.showError(
        "Kameraga kirish rad etildi",
        "Sozlamalardan kameraga ruxsat berib, qaytadan urinib ko'ring."
      );
    }
  }

  function _onBarcodeFound(code) {
    // Debounce: avoid rescanning same code within 3s
    const now = Date.now();
    if (code === lastBarcode && (now - lastScannedAt) < 3000) return;
    lastBarcode = code;
    lastScannedAt = now;

    if (navigator.vibrate) { try { navigator.vibrate([80, 40, 80]); } catch (e) {} }
    StoreUI.updateStatus("Topildi! Tekshirilmoqda…", 'found');
    StoreUI.showScanBeam(false);

    _checkBarcode(code);
  }

  async function _checkBarcode(barcode) {
    if (window.StoreUtils && !StoreUtils.isOnline()) {
      StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
      return;
    }
    try {
      const url = `${API_BASE}/api/store/check/${encodeURIComponent(selectedStore)}/${encodeURIComponent(barcode)}`;
      const { ok, data, error } = window.StoreUtils
        ? await StoreUtils.fetchJson(url, { timeoutMs: 15000 })
        : await _rawFetchJson(url);

      if (!ok || !data) {
        if (error === 'timeout') {
          StoreUI.showError("Server javob bermadi", "Server band bo'lishi mumkin. Qaytadan urinib ko'ring.");
        } else if (error === 'offline') {
          StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
        } else {
          StoreUI.showError("Ulanish xatoligi", "Serverga ulanib bo'lmadi. Qaytadan urinib ko'ring.");
        }
        return;
      }

      // 1) Exact match at this store → already added
      if (data.exact_match) {
        _stopScanner();
        StoreUI.renderAlreadyAdded(data.exact_match);
        StoreUI.showState('stateAlreadyAdded');
        return;
      }

      // 2) Barcode exists at other stores → cross-store prompt
      if (data.other_stores && data.other_stores.length > 0) {
        _stopScanner();
        _crossStoreContext = {
          barcode: barcode,
          others: data.other_stores,
          activeIndex: 0,
        };
        _renderCrossStoreNow();
        StoreUI.showState('stateCrossStore');
        return;
      }

      // 3) Nothing found → open blank form
      _stopScanner();
      StoreForm.openBlank(barcode, selectedStore);

    } catch (e) {
      console.error('check failed:', e);
      StoreUI.showError("Ulanish xatoligi", "Serverga ulanib bo'lmadi. Qaytadan urinib ko'ring.");
    }
  }

  // Fallback if store-utils.js didn't load for some reason
  async function _rawFetchJson(url, opts) {
    try {
      const resp = await fetch(url, opts);
      const data = await resp.json().catch(() => null);
      return { ok: resp.ok, status: resp.status, data, error: null };
    } catch (e) {
      return { ok: false, status: 0, data: null, error: 'network' };
    }
  }

  let _crossStoreContext = null;

  function _renderCrossStoreNow() {
    if (!_crossStoreContext) return;
    StoreUI.renderCrossStore(
      selectedStore,
      _crossStoreContext.others,
      _crossStoreContext.activeIndex,
      _pickCrossStoreSource
    );
  }

  function _pickCrossStoreSource(index) {
    if (!_crossStoreContext) return;
    if (index < 0 || index >= _crossStoreContext.others.length) return;
    _crossStoreContext.activeIndex = index;
    _renderCrossStoreNow();
  }

  function _acceptCrossStore() {
    if (!_crossStoreContext) return;
    const source = _crossStoreContext.others[_crossStoreContext.activeIndex];
    if (!source) return;
    StoreForm.openPrefilled(
      _crossStoreContext.barcode,
      selectedStore,
      source
    );
  }

  function _rejectCrossStore() {
    _crossStoreContext = null;
    _scanAgain();
  }

  async function _submitProduct(payload) {
    if (window.StoreUtils && !StoreUtils.isOnline()) {
      StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
      return;
    }

    StoreUI.showState('stateSubmitting');
    payload.userId = tgUserId;

    try {
      const { ok, status, data, error } = window.StoreUtils
        ? await StoreUtils.fetchJson(`${API_BASE}/api/store/product/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
            timeoutMs: 30000,
          })
        : await _rawFetchJson(`${API_BASE}/api/store/product/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          });

      if (error === 'timeout') {
        StoreUI.showError("Server javob bermadi", "Yuborish juda uzoq davom etdi. Qaytadan urinib ko'ring.");
        return;
      }
      if (error === 'offline') {
        StoreUI.showError("Internet yo'q", "Aloqani tiklab qayta urinib ko'ring.");
        return;
      }
      if (!data) {
        StoreUI.showError("Ulanish xatoligi", "Serverga ulanib bo'lmadi. Qaytadan urinib ko'ring.");
        return;
      }

      if (ok && data.success) {
        StoreUI.setSelectedStoreLabels(selectedStore);
        StoreUI.renderSuccess(data.product);
        StoreUI.showState('stateSuccess');
        _crossStoreContext = null;
        lastBarcode = null;
        // Update Mine cache + badge so the tab is fresh without a refetch
        try {
          if (window.StoreSubmissions && StoreSubmissions.addLocal) {
            StoreSubmissions.addLocal(data.product);
          }
        } catch (e) {}
        return;
      }

      // Error branch — interpret API codes.
      // Special case: DUPLICATE means another row at (barcode, store) was
      // created between the /check/ call and /add/. Instead of a dead-end
      // error, refetch and route to the "already added" state so the user
      // sees the winning entry and can move on.
      if (data && data.code === 'DUPLICATE') {
        try {
          const refetch = await fetch(
            `${API_BASE}/api/store/check/${encodeURIComponent(payload.store)}/${encodeURIComponent(payload.barcode)}`
          );
          if (refetch.ok) {
            const check = await refetch.json();
            if (check.exact_match) {
              StoreUI.renderAlreadyAdded(check.exact_match);
              StoreUI.showState('stateAlreadyAdded');
              StoreUI.toast("Bu mahsulot allaqachon qo'shilgan ekan", 'info');
              _crossStoreContext = null;
              lastBarcode = null;
              return;
            }
          }
        } catch (e) { /* fall through to error card */ }
      }

      let title = "Yuborib bo'lmadi";
      let msg = (data && data.error) || "Qaytadan urinib ko'ring.";
      if (data && data.code === 'DUPLICATE') {
        title = "Bu do'konda allaqachon qo'shilgan";
        msg = "Ushbu shtrix-kod allaqachon tanlangan do'kon uchun ro'yxatdan o'tgan.";
      } else if (data && data.code === 'NO_FLAG') {
        title = "Belgilar tanlanmagan";
        msg = "Kamida bitta belgini tanlang.";
      } else if (data && data.code === 'BAD_PHOTO_PATH') {
        title = "Rasm topilmadi";
        msg = "Qayta urinib ko'ring yoki yangi rasm oling.";
      }
      StoreUI.showError(title, msg);

    } catch (e) {
      console.error('submit failed:', e);
      StoreUI.showError("Ulanish xatoligi", "Serverga ulanib bo'lmadi. Qaytadan urinib ko'ring.");
    }
  }

  function _scanAgain() {
    _crossStoreContext = null;
    lastBarcode = null;
    StoreForm.reset();
    // Keep selected store; go back to scanner
    startScanning();
  }

  // ============================================
  // STOP HELPERS
  // ============================================
  function _stopScanner() {
    try { Scanner.stop(); } catch (e) {}
    try { Scanner.resetLastScanned && Scanner.resetLastScanned(); } catch (e) {}
  }
  function _stopCamera() {
    try { Camera.detach(StoreUI.els().videoElement); } catch (e) {}
    try { Camera.detach(StoreUI.els().captureVideo); } catch (e) {}
    try { Camera.stop(); } catch (e) {}
  }

  async function _resumeScannerIfNeeded() {
    try {
      const videoEl = StoreUI.els().videoElement;
      if (!videoEl) return;
      // Re-acquire the stream (no-op if still active) and reattach to <video>.
      const info = await Camera.open(videoEl);
      if (info) {
        StoreUI.showTorch(info.hasTorch);
        StoreUI.showSwitchCam(info.hasMultipleCameras);
      }
      StoreUI.updateStatus("Shtrix-kod qidirilmoqda…", 'scanning');
      StoreUI.showScanBeam(true);
      Scanner.start(videoEl, _onBarcodeFound);
    } catch (e) {
      console.error('resume scanner failed:', e);
    }
  }

  // ============================================
  // BACK NAVIGATION
  // ============================================
  let _backInFlight = false;

  function _handleBack() {
    // Debounce: Telegram BackButton + popstate can both fire for one press
    if (_backInFlight) return;
    _backInFlight = true;
    setTimeout(() => { _backInFlight = false; }, 250);

    // Fullscreen viewer first
    const viewer = document.getElementById('fullscreenViewer');
    if (viewer && viewer.style.display !== 'none') {
      if (window.StoreUI && StoreUI.closeFullscreen) StoreUI.closeFullscreen();
      else viewer.style.display = 'none';
      return;
    }

    // Modals take priority — close them next
    const editModal = document.getElementById('editModal');
    if (editModal && editModal.style.display !== 'none') {
      const closeBtn = document.getElementById('editCloseBtn');
      if (closeBtn) closeBtn.click();
      return;
    }
    const deleteModal = document.getElementById('deleteModal');
    if (deleteModal && deleteModal.style.display !== 'none') {
      const cancelBtn = document.getElementById('deleteCancelBtn');
      if (cancelBtn) cancelBtn.click();
      return;
    }

    const currentPane = document.getElementById('paneMine').style.display === 'block' ? 'mine' : 'collect';

    if (currentPane === 'mine') {
      StoreUI.showTab('collect');
      return;
    }

    const s = _currentState();
    switch (s) {
      case 'stateStorePicker':
        _exitPage();
        return;
      case 'statePermission':
        goStorePicker();
        return;
      case 'stateScanner':
        goPermission();
        return;
      case 'stateError':
        // Don't retry — avoids re-prompting a denied camera permission,
        // which would loop between error and permission screens.
        goStorePicker();
        return;
      case 'stateAlreadyAdded':
      case 'stateCrossStore':
        _scanAgain();
        return;
      case 'stateForm':
        // If prefilled from cross-store, go back to prompt; else scanner.
        if (_crossStoreContext) {
          StoreUI.showState('stateCrossStore');
        } else {
          _scanAgain();
        }
        return;
      case 'stateSubmitting':
        // Block back during upload
        return;
      case 'stateSuccess':
        _scanAgain();
        return;
      default:
        _exitPage();
    }
  }

  function _currentState() {
    const ids = [
      'stateStorePicker','statePermission','stateScanner',
      'stateAlreadyAdded','stateCrossStore','stateForm',
      'stateSubmitting','stateSuccess','stateError'
    ];
    for (const id of ids) {
      const el = document.getElementById(id);
      if (el && el.style.display !== 'none') return id;
    }
    return null;
  }

  function _exitPage() {
    _stopScanner();
    _stopCamera();
    try { Camera.destroy && Camera.destroy(); } catch (e) {}
    // Remove our popstate guard first so history.back() navigates out
    try { window.removeEventListener('popstate', _onPopState); } catch (e) {}
    if (window.history.length > 1) {
      window.history.back();
    } else {
      window.location.href = '../../index.html';
    }
  }

  // ============================================
  // BINDINGS
  // ============================================
  function _bind() {
    // Tabs
    document.getElementById('tabCollect').addEventListener('click', () => {
      StoreUI.showTab('collect');
      // If the user was mid-scan when they left, restart the live stream.
      if (_currentState() === 'stateScanner') {
        _resumeScannerIfNeeded();
      }
    });
    document.getElementById('tabMine').addEventListener('click',    () => {
      // Pause the live camera feed when moving to Mine tab
      _stopScanner();
      _stopCamera();
      StoreUI.showTab('mine');
      if (window.StoreSubmissions && StoreSubmissions.refresh) StoreSubmissions.refresh();
    });

    // Store picker
    document.getElementById('storeGrid').addEventListener('click', (ev) => {
      const card = ev.target.closest('.store-card');
      if (!card) return;
      selectedStore = card.getAttribute('data-store');
      StoreUI.setSelectedStoreCard(selectedStore);
      StoreUI.setSelectedStoreLabels(selectedStore);
      // Short delay so the selection animation is visible before transition
      setTimeout(goPermission, 180);
    });

    // Permission screen
    document.getElementById('changeStoreBtnPerm').addEventListener('click', goStorePicker);
    document.getElementById('startScanBtn').addEventListener('click', startScanning);

    // Scanner controls
    document.getElementById('changeStoreBtnScan').addEventListener('click', () => {
      _stopScanner();
      _stopCamera();
      goStorePicker();
    });

    document.getElementById('torchBtn').addEventListener('click', async () => {
      try {
        const on = await Camera.toggleTorch();
        StoreUI.setTorchActive(on);
      } catch (e) {}
    });

    document.getElementById('switchCamBtn').addEventListener('click', async () => {
      try {
        _stopScanner();
        const info = await Camera.cycle(StoreUI.els().videoElement);
        if (info) {
          StoreUI.showTorch(info.hasTorch);
          StoreUI.showSwitchCam(info.hasMultipleCameras);
        }
        Scanner.start(StoreUI.els().videoElement, _onBarcodeFound);
      } catch (e) {}
    });

    // Already-added
    document.getElementById('scanNextBtnAlready').addEventListener('click', _scanAgain);

    // Cross-store
    document.getElementById('crossAcceptBtn').addEventListener('click', _acceptCrossStore);
    document.getElementById('crossRejectBtn').addEventListener('click', _rejectCrossStore);

    // Success
    document.getElementById('successScanNextBtn').addEventListener('click', _scanAgain);
    document.getElementById('successGotoMineBtn').addEventListener('click', () => {
      StoreUI.showTab('mine');
      if (window.StoreSubmissions && StoreSubmissions.refresh) StoreSubmissions.refresh();
    });

    // Error retry
    document.getElementById('errorRetryBtn').addEventListener('click', _scanAgain);

    // Visibility: pause scanner when tab hidden, resume when back
    document.addEventListener('visibilitychange', () => {
      const onScanner = document.getElementById('stateScanner').style.display !== 'none';
      if (document.hidden) {
        _stopScanner();
      } else if (onScanner) {
        _resumeScannerIfNeeded();
      }
    });

    // Unload
    window.addEventListener('beforeunload', () => {
      _stopScanner();
      _stopCamera();
    });

    // Browser back
    history.pushState({ sc: true }, '', '');
    window.addEventListener('popstate', _onPopState);
  }

  function _onPopState() {
    // Re-push a sentinel so the next back press also fires popstate
    // (only if we're still on our page — _handleBack may navigate away).
    history.pushState({ sc: true }, '', '');
    _handleBack();
  }

  // ============================================
  // BOOT
  // ============================================
  document.addEventListener('DOMContentLoaded', () => {
    StoreForm.init({
      onSubmit: _submitProduct,
      onCancel: _scanAgain,
    });
    StoreEdit.init({
      onSaved: (updated) => {
        // StoreSubmissions.updateLocal was already called inside StoreEdit.
        // Nothing else to do here for now.
      },
    });
    StoreSubmissions.init({
      onEditRequest: (product) => StoreEdit.open(product),
    });
    _bind();

    // Apply current connection state at boot
    if (window.StoreUtils) _applyConnectionState(StoreUtils.isOnline());

    // Start at the store picker
    StoreUI.showTab('collect');
    StoreUI.showState('stateStorePicker');
  });

  // Expose for other modules
  window.StoreAppActions = {
    scanAgain: _scanAgain,
    goStorePicker,
    getUserId: () => tgUserId,
    getSelectedStore: () => selectedStore,
  };

})();
